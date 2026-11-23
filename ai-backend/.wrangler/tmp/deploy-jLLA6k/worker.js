var __defProp = Object.defineProperty;
var __name = (target, value) => __defProp(target, "name", { value, configurable: true });

// worker.mjs
var maxBodyBytes = 64 * 1024;
var maxPromptLength = 24e3;
var instruction = `B\u1EA1n l\xE0 EduMaster AI Tutor, tr\u1EE3 l\xFD h\u1ECDc t\u1EADp c\u1EE7a EduMaster.
Tr\u1EA3 l\u1EDDi b\u1EB1ng ng\xF4n ng\u1EEF ng\u01B0\u1EDDi h\u1ECDc y\xEAu c\u1EA7u, m\u1EB7c \u0111\u1ECBnh l\xE0 ti\u1EBFng Vi\u1EC7t.
Gi\u1EA3i th\xEDch ch\xEDnh x\xE1c, d\u1EC5 hi\u1EC3u, c\xF3 v\xED d\u1EE5 khi h\u1EEFu \xEDch. Khi thi\u1EBFu th\xF4ng tin, h\xE3y h\u1ECFi l\u1EA1i.`;
function error(message, status) {
  return Response.json({ error: message }, { status });
}
__name(error, "error");
async function readPrompt(request) {
  const reader = request.body?.getReader();
  if (!reader) return null;
  const decoder = new TextDecoder("utf-8", { fatal: true });
  let bytes = 0;
  let body = "";
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
    return typeof prompt === "string" ? prompt.trim() : null;
  } catch {
    return null;
  } finally {
    reader.releaseLock();
  }
}
__name(readPrompt, "readPrompt");
var worker_default = {
  async fetch(request, env) {
    const { pathname } = new URL(request.url);
    if (pathname === "/health" && request.method === "GET") {
      return env.GEMINI_API_KEY && env.GEMINI_MODEL && env.CHAT_RATE_LIMIT ? Response.json({ status: "ok" }) : error("M\xE1y ch\u1EE7 ch\u01B0a \u0111\u01B0\u1EE3c c\u1EA5u h\xECnh.", 503);
    }
    if (pathname !== "/chat") return error("Kh\xF4ng t\xECm th\u1EA5y \u0111\u01B0\u1EDDng d\u1EABn.", 404);
    if (request.method !== "POST") {
      return Response.json({ error: "H\xE3y d\xF9ng POST." }, {
        status: 405,
        headers: { Allow: "POST" }
      });
    }
    if (!env.GEMINI_API_KEY || !env.GEMINI_MODEL || !env.CHAT_RATE_LIMIT) {
      return error("M\xE1y ch\u1EE7 ch\u01B0a \u0111\u01B0\u1EE3c c\u1EA5u h\xECnh.", 503);
    }
    const ip = request.headers.get("CF-Connecting-IP") ?? "local";
    const { success } = await env.CHAT_RATE_LIMIT.limit({ key: ip });
    if (!success) return error("Qu\xE1 nhi\u1EC1u y\xEAu c\u1EA7u. H\xE3y th\u1EED l\u1EA1i sau.", 429);
    const prompt = await readPrompt(request);
    if (!prompt || prompt.length > maxPromptLength) {
      return error("C\xE2u h\u1ECFi tr\u1ED1ng ho\u1EB7c v\u01B0\u1EE3t gi\u1EDBi h\u1EA1n \u0111\u1ED9 d\xE0i.", 400);
    }
    try {
      const model = encodeURIComponent(env.GEMINI_MODEL);
      const upstream = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "x-goog-api-key": env.GEMINI_API_KEY
          },
          signal: AbortSignal.timeout(35e3),
          body: JSON.stringify({
            systemInstruction: { parts: [{ text: instruction }] },
            contents: [{ role: "user", parts: [{ text: prompt }] }],
            generationConfig: { maxOutputTokens: 1536 }
          })
        }
      );
      if (!upstream.ok) {
        console.warn("Gemini HTTP status:", upstream.status);
        return upstream.status === 429 ? error("Gemini \u0111ang qu\xE1 t\u1EA3i ho\u1EB7c \u0111\xE3 h\u1EBFt h\u1EA1n m\u1EE9c.", 429) : error("Kh\xF4ng th\u1EC3 k\u1EBFt n\u1ED1i v\u1EDBi Gemini.", 502);
      }
      const data = await upstream.json();
      const answer = data.candidates?.[0]?.content?.parts?.filter((part) => !part.thought && typeof part.text === "string").map((part) => part.text).join("").trim();
      return answer ? Response.json({ answer }) : error("Gemini kh\xF4ng tr\u1EA3 v\u1EC1 n\u1ED9i dung.", 502);
    } catch (cause) {
      if (cause?.name === "TimeoutError" || cause?.name === "AbortError") {
        return error("Gemini ph\u1EA3n h\u1ED3i qu\xE1 l\xE2u.", 504);
      }
      return error("Kh\xF4ng th\u1EC3 k\u1EBFt n\u1ED1i v\u1EDBi Gemini.", 502);
    }
  }
};
export {
  worker_default as default
};
//# sourceMappingURL=worker.js.map
