const maxBodyBytes = 64 * 1024;
const maxPromptLength = 24000;
const instruction = `Bạn là EduMaster AI Tutor, trợ lý học tập của EduMaster.
Trả lời bằng ngôn ngữ người học yêu cầu, mặc định là tiếng Việt.
Giải thích chính xác, dễ hiểu, có ví dụ khi hữu ích. Khi thiếu thông tin, hãy hỏi lại.`;

function error(message, status) {
  return Response.json({ error: message }, { status });
}

async function readPrompt(request) {
  const reader = request.body?.getReader();
  if (!reader) return null;
  const decoder = new TextDecoder('utf-8', { fatal: true });
  let bytes = 0;
  let body = '';
  try {
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      bytes += value.byteLength;
      if (bytes > maxBodyBytes) {
        await reader.cancel();
        return null;
      }
      body += decoder.decode(value, { stream: true });
    }
    const prompt = JSON.parse(body + decoder.decode())?.prompt;
    return typeof prompt === 'string' ? prompt.trim() : null;
  } catch {
    return null;
  } finally {
    reader.releaseLock();
  }
}

export default {
  async fetch(request, env) {
    const { pathname } = new URL(request.url);
    if (pathname === '/health' && request.method === 'GET') {
      return env.GEMINI_API_KEY && env.GEMINI_MODEL && env.CHAT_RATE_LIMIT
        ? Response.json({ status: 'ok' })
        : error('Máy chủ chưa được cấu hình.', 503);
    }
    if (pathname !== '/chat') return error('Không tìm thấy đường dẫn.', 404);
    if (request.method !== 'POST') {
      return Response.json({ error: 'Hãy dùng POST.' }, {
        status: 405, headers: { Allow: 'POST' },
      });
    }
    if (!env.GEMINI_API_KEY || !env.GEMINI_MODEL || !env.CHAT_RATE_LIMIT) {
      return error('Máy chủ chưa được cấu hình.', 503);
    }

    const ip = request.headers.get('CF-Connecting-IP') ?? 'local';
    const { success } = await env.CHAT_RATE_LIMIT.limit({ key: ip });
    if (!success) return error('Quá nhiều yêu cầu. Hãy thử lại sau.', 429);

    const prompt = await readPrompt(request);
    if (!prompt || prompt.length > maxPromptLength) {
      return error('Câu hỏi trống hoặc vượt giới hạn độ dài.', 400);
    }

    try {
      const model = encodeURIComponent(env.GEMINI_MODEL);
      const upstream = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': env.GEMINI_API_KEY,
          },
          signal: AbortSignal.timeout(35_000),
          body: JSON.stringify({
            systemInstruction: { parts: [{ text: instruction }] },
            contents: [{ role: 'user', parts: [{ text: prompt }] }],
            generationConfig: { maxOutputTokens: 1536 },
          }),
        },
      );
      if (!upstream.ok) {
        console.warn('Gemini HTTP status:', upstream.status);
        return upstream.status === 429
          ? error('Gemini đang quá tải hoặc đã hết hạn mức.', 429)
          : error('Không thể kết nối với Gemini.', 502);
      }
      const data = await upstream.json();
      const answer = data.candidates?.[0]?.content?.parts
        ?.filter((part) => !part.thought && typeof part.text === 'string')
        .map((part) => part.text).join('').trim();
      return answer
        ? Response.json({ answer })
        : error('Gemini không trả về nội dung.', 502);
    } catch (cause) {
      if (cause?.name === 'TimeoutError' || cause?.name === 'AbortError') {
        return error('Gemini phản hồi quá lâu.', 504);
      }
      return error('Không thể kết nối với Gemini.', 502);
    }
  },
};
