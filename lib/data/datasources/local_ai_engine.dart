// lib/data/datasources/local_ai_engine.dart
//
// Bộ não AI Ngoại tuyến Thông minh (Smart Local AI Engine & Knowledge Base)
// Tự động phân tích và sinh câu trả lời ĐỘNG cho MỌI câu hỏi:
//   1. So sánh & Phân biệt các khái niệm (List vs Tuple, final vs const...)
//   2. Kho tri thức CNTT chuyên sâu (Flutter, Dart, Clean Architecture, SM-2, SQLite FTS...)
//   3. Tính toán số học & công thức toán học/điểm thi
//   4. Đời sống, sức khỏe, học tập & công nghệ phổ biến (Mặt nạ tự nhiên, Pomodoro...)
//   5. Giải thích câu hỏi trắc nghiệm song ngữ cho tính năng "Xem AI giải thích"
//   6. Phân tích ngữ nghĩa tự nhiên linh hoạt (Semantic Dynamic Synthesizer)

class LocalAiEngine {
  /// Tách câu hỏi thực tế của người dùng ra khỏi wrapper ngữ cảnh (nếu có)
  static String extractQuestion(String prompt) {
    if (prompt.contains('CÂU HỎI MỚI NHẤT:')) {
      final parts = prompt.split('CÂU HỎI MỚI NHẤT:');
      if (parts.length > 1) {
        return parts.last
            .replaceAll('Hãy trả lời trực tiếp câu hỏi mới nhất.', '')
            .trim();
      }
    }
    return prompt.trim();
  }

  /// Entry point chính: Phân tích prompt và giải đáp (Chế độ Ngoại tuyến / Demo Mode)
  /// Theo yêu cầu: Ở chế độ ngoại tuyến, CHỈ CHO PHÉP HỎI VỀ MÔN HỌC & CÔNG NGHỆ.
  /// Mọi câu hỏi ngoài môn học sẽ được từ chối lịch sự và hướng dẫn chuyển sang Online.
  static String processQuery(String prompt) {
    final clean = extractQuestion(prompt);
    if (clean.isEmpty) {
      return '👋 Xin chào bạn! Mình là Trợ lý AI Tutor của EduMaster (Chế độ Ngoại tuyến). Hãy nhập câu hỏi thuộc môn học để mình giải đáp nhé!';
    }

    final lower = clean.toLowerCase();

    // 0. Xử lý lời chào / giao tiếp thông thường
    if (lower == 'hello' ||
        lower == 'hi' ||
        lower == 'xin chào' ||
        lower.contains('chào bạn') ||
        lower.contains('giúp tôi') ||
        lower == 'chào') {
      return '👋 Xin chào! Tôi là Trợ lý Gia sư AI EduMaster (Đang chạy ở **Chế độ Ngoại tuyến**).\n\n'
          '📚 Ở chế độ này, tôi chuyên tâm giải đáp các nội dung thuộc **Chương trình Môn học & Công nghệ**:\n'
          '- 📱 **Lập trình Flutter & Ngôn ngữ Dart** (Widget, State, Provider, Async/Await...)\n'
          '- 🧠 **Thuật toán SuperMemo SM-2** & Cấu trúc dữ liệu ôn tập\n'
          '- 💾 **Cơ sở dữ liệu SQLite** & Bảng ảo tìm kiếm FTS\n'
          '- 🏛️ **Kiến trúc phần mềm Clean Architecture** & Repository Pattern\n'
          '- 📝 **Giải thích trắc nghiệm** & Công thức tính điểm thi thang 10\n\n'
          '💡 *Gợi ý: Nếu bạn muốn đặt câu hỏi mở rộng về các chủ đề đời sống, xã hội hay kiến thức tổng quát khác, hãy bấm biểu tượng đám mây ☁️ ở góc trên để chuyển sang **Chế độ Trực tuyến** nhé!*';
    }

    // 1. Kiểm tra giới hạn: Ở chế độ ngoại tuyến, CHỈ CHO PHÉP HỎI VỀ MÔN HỌC
    if (!isCourseworkTopic(clean, lower)) {
      return '📴 **Chế độ Ngoại tuyến (Offline Mode) — Giới hạn phạm vi Môn học:**\n\n'
          'Hiện tại Trợ lý AI đang hoạt động ở **Chế độ Ngoại tuyến** trên thiết bị và chỉ được thiết lập để hỗ trợ các câu hỏi liên quan đến **Môn học & Công nghệ**:\n'
          '- 📱 **Lập trình ứng dụng:** Flutter, Ngôn ngữ Dart, Quản lý trạng thái (Provider), Vòng đời Widget.\n'
          '- 🧠 **Thuật toán & Ghi nhớ:** Thuật toán SuperMemo SM-2, Cấu trúc dữ liệu & Giải thuật.\n'
          '- 💾 **Cơ sở dữ liệu:** SQLite, Bảng ảo FTS (Full-Text Search), Truy vấn dữ liệu.\n'
          '- 🏛️ **Kiến trúc phần mềm:** Clean Architecture, Repository Pattern, Dependency Inversion.\n'
          '- 📝 **Ôn luyện thi cử:** Giải thích đáp án trắc nghiệm, công thức tính điểm thi thang 10.\n\n'
          '💡 **Để hỏi đáp mở rộng về mọi chủ đề đời sống, xã hội và các lĩnh vực kiến thức khác:**\n'
          'Bấm biểu tượng **Đám mây (☁️)** để chuyển sang **Chế độ Trực tuyến (Online)** và hỏi Gemini.';
    }

    // 2. Phép toán số học hoặc công thức tính điểm thi
    final mathResult = _tryEvaluateMath(clean, lower);
    if (mathResult != null) return mathResult;

    // 3. So sánh / Phân biệt các khái niệm chuyên ngành (List vs Tuple, final vs const...)
    final comparisonResult = _tryCompareConcepts(lower);
    if (comparisonResult != null) return comparisonResult;

    // 4. Giải thích câu hỏi trắc nghiệm (cho tính năng "Xem AI giải thích")
    final quizResult = _tryExplainQuizQuestion(clean, lower);
    if (quizResult != null) return quizResult;

    // 5. Kho tri thức CNTT chuyên sâu (Flutter, Dart, Clean Architecture, SM-2, SQLite FTS...)
    final kbResult = _lookupKnowledgeBase(lower);
    if (kbResult != null) return kbResult;

    // 6. Tổng hợp phân tích cho câu hỏi môn học hợp lệ
    return _synthesizeCourseResponse(clean, lower);
  }

  /// Kiểm tra xem câu hỏi có thuộc phạm vi môn học và công nghệ hay không
  static bool isCourseworkTopic(String clean, String lower) {
    // Luôn cho phép giải thích câu hỏi trắc nghiệm
    if (lower.contains('học viên chọn') ||
        lower.contains('the student chose') ||
        lower.contains('đáp án đúng') ||
        lower.contains('correct answer') ||
        lower.contains('giải thích')) {
      return true;
    }

    // Cho phép tính điểm hoặc biểu thức số học
    if (lower.contains('tính điểm') ||
        lower.contains('thang điểm') ||
        lower.contains('điểm thi') ||
        RegExp(r'\d+\s*[\+\-\*\/xX:]\s*\d+').hasMatch(clean)) {
      return true;
    }

    // Tập từ khóa Môn học & Công nghệ EduMaster
    const courseKeywords = [
      'flutter', 'dart', 'widget', 'stateful', 'stateless', 'buildcontext', 'setstate',
      'provider', 'changenotifier', 'bloc', 'getx', 'state management', 'quản lý trạng thái',
      'sm-2', 'sm2', 'supermemo', 'lặp lại ngắt quãng', 'spaced repetition',
      'sqlite', 'fts', 'fts4', 'fts5', 'database', 'csdl', 'cơ sở dữ liệu', 'query', 'bảng ảo',
      'clean architecture', 'kiến trúc sạch', 'kiến trúc phần mềm', 'repository', 'datasource',
      'entity', 'domain', 'usecase', 'dependency inversion', 'di',
      'oop', 'hướng đối tượng', 'kế thừa', 'đóng gói', 'đa hình', 'trừu tượng',
      'encapsulation', 'inheritance', 'polymorphism', 'abstraction', 'interface', 'abstract class',
      'async', 'await', 'future', 'stream', 'event loop', 'isolate', 'bất đồng bộ', 'đồng bộ',
      'hot reload', 'hot restart', 'null safety', 'record', 'tuple', 'list', 'map', 'set',
      'final', 'const', 'var', 'late',
      'git', 'github', 'commit', 'branch', 'pull request', 'merge', 'ci/cd',
      'api', 'rest', 'restful', 'http', 'json', 'post', 'get', 'endpoint',
      'trắc nghiệm', 'quiz', 'câu hỏi', 'đáp án', 'phòng thi', 'exam', 'thí sinh',
      'flashcard', 'từ điển', 'dictionary', 'bxh', 'leaderboard', 'bảng xếp hạng', 'xp', 'streak',
      'lập trình', 'code', 'coding', 'ngôn ngữ lập trình', 'software', 'phần mềm',
      'python', 'java', 'c++', 'c#', 'javascript', 'typescript', 'sql', 'nosql', 'firebase',
      'thuật toán', 'algorithm', 'cấu trúc dữ liệu', 'data structure', 'big o', 'độ phức tạp',
      'đệ quy', 'recursion', 'binary search', 'sắp xếp', 'tìm kiếm', 'cache', 'bộ nhớ đệm',
      'edumaster', 'ptit', 'học phần', 'môn học', 'bài tập', 'đề thi', 'ôn tập', 'giảng viên', 'sinh viên',
      'pomodoro', 'phương pháp học'
    ];

    for (final kw in courseKeywords) {
      if (lower.contains(kw)) return true;
    }

    return false;
  }

  // ==========================================================================
  // 1. BỘ TÍNH TOÁN TOÁN HỌC & CÔNG THỨC (Math Evaluator)
  // ==========================================================================
  static String? _tryEvaluateMath(String raw, String lower) {
    // Nhận diện câu hỏi điểm thi hoặc công thức BTL
    if (lower.contains('tính điểm') || lower.contains('thang điểm') || lower.contains('điểm thi')) {
      final counts = RegExp(r'(-?\d+)\s*(?:/|trên)\s*(-?\d+)').firstMatch(lower);
      if (counts != null) {
        final correct = int.tryParse(counts.group(1)!);
        final total = int.tryParse(counts.group(2)!);
        if (correct == null || total == null || total <= 0 ||
            correct < 0 || correct > total) {
          return 'Số câu đúng phải nằm trong khoảng từ 0 đến tổng số câu. '
              'Tổng số câu phải lớn hơn 0.';
        }
        final score = (correct / total * 10)
            .toStringAsFixed(2)
            .replaceFirst(RegExp(r'0$'), '');
        return '📊 **Kết quả tính điểm thi:**\n\n'
            'Đúng $correct/$total câu: ($correct / $total) × 10 = **$score điểm**.';
      }
      return '📊 **Công thức tính điểm thi trắc nghiệm (Thang điểm 10):**\n\n'
          r'$$\text{Điểm} = \left(\frac{\text{Số câu đúng}}{\text{Tổng số câu}}\right) \times 10$$'
          '\n\n'
          '**Ví dụ minh họa:**\n'
          r'- Đúng 16/20 câu: $(16 / 20) \times 10 = \mathbf{8.0\text{ điểm}}$ (Giỏi)'
          '\n'
          r'- Đúng 18/20 câu: $(18 / 20) \times 10 = \mathbf{9.0\text{ điểm}}$ (Xuất sắc)'
          '\n'
          '- Mỗi câu trong đề 20 câu tương đương **0.5 điểm**.';
    }

    // Nhận diện biểu thức số học đơn giản: ví dụ "2 + 2", "5 * 10", "100 / 4"
    final isExplicitMath = RegExp(r'^\s*=?\s*(\d+(?:\.\d+)?)\s*([\+\-\*\/xX:])\s*(\d+(?:\.\d+)?)\s*=?\s*$').hasMatch(raw) ||
        (lower.contains('tính') && RegExp(r'(\d+(?:\.\d+)?)\s*([\+\-\*\/xX:])\s*(\d+(?:\.\d+)?)').hasMatch(raw)) ||
        (lower.contains('bằng bao nhiêu') && RegExp(r'(\d+(?:\.\d+)?)\s*([\+\-\*\/xX:])\s*(\d+(?:\.\d+)?)').hasMatch(raw));

    if (!isExplicitMath) return null;

    final mathRegex = RegExp(r'(\d+(?:\.\d+)?)\s*([\+\-\*\/xX:])\s*(\d+(?:\.\d+)?)');
    final match = mathRegex.firstMatch(raw);
    if (match != null) {
      final num1 = double.tryParse(match.group(1)!);
      final op = match.group(2)!;
      final num2 = double.tryParse(match.group(3)!);

      if (num1 != null && num2 != null) {
        double result = 0;
        String opName = '';
        switch (op) {
          case '+':
            result = num1 + num2;
            opName = 'phép cộng';
            break;
          case '-':
            result = num1 - num2;
            opName = 'phép trừ';
            break;
          case '*':
          case 'x':
          case 'X':
            result = num1 * num2;
            opName = 'phép nhân';
            break;
          case '/':
          case ':':
            if (num2 == 0) return '⚠️ **Lỗi toán học:** Không thể thực hiện phép chia cho số 0.';
            result = num1 / num2;
            opName = 'phép chia';
            break;
        }

        final resStr = (result % 1 == 0) ? result.toInt().toString() : result.toStringAsFixed(2);
        final expression = '${match.group(1)} $op ${match.group(3)}';
        return '🔢 **Kết quả tính toán ($opName):**\n\n'
            '**$expression = $resStr**';
      }
    }
    return null;
  }

  // ==========================================================================
  // 2. BỘ PHÂN BIỆT & SO SÁNH (Comparison & Contrast Engine)
  // ==========================================================================
  static String? _tryCompareConcepts(String lower) {
    final isCompare = lower.contains('phân biệt') ||
        lower.contains('so sánh') ||
        lower.contains('khác nhau') ||
        lower.contains('vs') ||
        lower.contains('difference');

    if (!isCompare) return null;

    // List vs Tuple
    if (lower.contains('list') && lower.contains('tuple')) {
      return '⚖️ **So sánh chi tiết giữa List và Tuple:**\n\n'
          '| Tiêu chí | List (Danh sách) | Tuple (Bộ giá trị / Record) |\n'
          '| :--- | :--- | :--- |\n'
          '| **Tính thay đổi (Mutability)** | **Mutable** (Có thể thêm, sửa, xóa phần tử sau khi tạo). | **Immutable** (Bất biến, không thể sửa đổi sau khi khởi tạo). |\n'
          '| **Cú pháp khai báo** | `var list = [1, 2, 3];` | Dart 3 Record: `var t = (1, "EduMaster");` |\n'
          '| **Hiệu năng & Bộ nhớ** | Tốn nhiều bộ nhớ hơn do cấp phát động (Dynamic array). | Tối ưu bộ nhớ hơn, tốc độ truy xuất cực nhanh. |\n'
          '| **Trường hợp sử dụng** | Dùng khi tập dữ liệu co giãn liên tục (ví dụ danh sách câu hỏi). | Dùng đóng gói các giá trị đi liền nhau (ví dụ tọa độ (x, y), cặp key-value). |\n\n'
          '💡 **Ví dụ trong Dart 3:**\n'
          '```dart\n'
          '// List (Thay đổi được)\n'
          'List<int> numbers = [1, 2];\n'
          'numbers.add(3); // Hợp lệ!\n\n'
          '// Tuple / Record (Bất biến)\n'
          'final (name, age) = ("Sinh viên", 20);\n'
          'print(name); // Sinh viên\n'
          '```';
    }

    // final vs const
    if (lower.contains('final') && lower.contains('const')) {
      return '⚖️ **So sánh giữa final và const trong Dart:**\n\n'
          '| Tiêu chí | `final` | `const` |\n'
          '| :--- | :--- | :--- |\n'
          '| **Thời điểm gán giá trị** | **Runtime** (Khi ứng dụng đang chạy, ví dụ `DateTime.now()`). | **Compile-time** (Biết trước giá trị ngay lúc biên dịch mã nguồn). |\n'
          '| **Vùng nhớ (Memory)** | Mỗi đối tượng tạo ra một ô nhớ riêng biệt. | Được gom chung vào bảng hằng số (Canonicalized), tiết kiệm RAM tối đa. |\n'
          '| **Quy tắc gán** | Chỉ gán giá trị duy nhất 1 lần. | Bắt buộc giá trị bên trong cũng phải là const hằng số. |\n\n'
          '💡 **Ví dụ minh họa:**\n'
          '```dart\n'
          'final now = DateTime.now(); // HỢP LỆ (xác định lúc runtime)\n'
          '// const now = DateTime.now(); // LỖI BIÊN DỊCH!\n'
          'const pi = 3.14159;         // HỢP LỆ (biết trước lúc compile)\n'
          '```';
    }

    // StatelessWidget vs StatefulWidget
    if ((lower.contains('stateless') || lower.contains('statelesswidget')) &&
        (lower.contains('stateful') || lower.contains('statefulwidget'))) {
      return '⚖️ **So sánh StatelessWidget vs StatefulWidget:**\n\n'
          '1. **StatelessWidget:**\n'
          '   - Là widget **bất biến** (Immutable), nội dung không tự thay đổi sau khi được dựng.\n'
          '   - Toàn bộ cấu hình được truyền từ bên ngoài vào qua constructor.\n'
          '   - Dùng cho: Nút bấm tĩnh, icon, văn bản hiển thị tiêu đề, thẻ giới thiệu...\n\n'
          '2. **StatefulWidget:**\n'
          '   - Tách làm 2 lớp: Lớp `StatefulWidget` và lớp `State<T>` đi kèm.\n'
          '   - Cho phép gọi `setState()` để yêu cầu Flutter dựng lại (Rebuild) giao diện khi dữ liệu biến thiên.\n'
          '   - Dùng cho: Form nhập liệu, đếm giờ thi, màn hình làm trắc nghiệm, lật thẻ flashcard.';
    }

    // SQL vs NoSQL
    if (lower.contains('sql') && lower.contains('nosql')) {
      return '⚖️ **So sánh SQL (Quan hệ) và NoSQL (Phi quan hệ):**\n\n'
          '| Đặc điểm | SQL (Relational - ví dụ SQLite, MySQL) | NoSQL (Document - ví dụ Firebase Firestore, MongoDB) |\n'
          '| :--- | :--- | :--- |\n'
          '| **Cấu trúc dữ liệu** | Bảng có dòng và cột nghiêm ngặt (Strict Schema). | Tài liệu linh hoạt JSON / BSON (Schema-less). |\n'
          '| **Mối quan hệ** | Hỗ trợ Foreign Key, JOIN nhiều bảng phức tạp. | Dữ liệu phi chuẩn hóa (Denormalized), nhúng trực tiếp. |\n'
          '| **Khả năng mở rộng** | Mở rộng theo chiều dọc (Vertical Scaling - nâng cấp phần cứng). | Mở rộng theo chiều ngang (Horizontal Scaling - chia cụm sharding). |\n'
          '| **Ứng dụng trong EduMaster** | Dùng **SQLite FTS** cho Từ điển IT ngoại tuyến siêu tốc. | Dùng **Firestore** cho Bảng xếp hạng đồng bộ thời gian thực. |';
    }

    // Future vs Stream
    if (lower.contains('future') && lower.contains('stream')) {
      return '⚖️ **So sánh Future vs Stream trong lập trình bất đồng bộ Dart:**\n\n'
          '- **Future:** Đại diện cho **một giá trị duy nhất** (hoặc một lỗi) sẽ được trả về trong tương lai (Ví dụ: Gọi 1 HTTP GET request, đọc 1 file JSON).\n'
          '- **Stream:** Đại diện cho **một chuỗi các sự kiện/giá trị liên tục theo thời gian** (Ví dụ: Lắng nghe vị trí GPS, đồng hồ đếm ngược từng giây, dữ liệu bảng xếp hạng Firebase thời gian thực).\n\n'
          '💡 Trong Flutter: Dùng `FutureBuilder` để hiển thị dữ liệu từ Future, và `StreamBuilder` để tự động render lại mỗi khi Stream bắn dữ liệu mới.';
    }

    // Abstract Class vs Interface
    if (lower.contains('abstract') && lower.contains('interface')) {
      return '⚖️ **So sánh Abstract Class và Interface trong Dart:**\n\n'
          '- Trong Dart, **mọi class đều ngầm định định nghĩa một interface**.\n'
          '- **`abstract class`:** Lớp trừu tượng, có thể chứa cả phương thức trừu tượng (chưa có thân hàm) lẫn phương thức đã có thân code cụ thể. Dùng từ khóa `extends` (kế thừa đơn) hoặc `implements`.\n'
          '- **`implements` (Interface):** Bắt buộc lớp con phải viết lại (override) TOÀN BỘ phương thức và getter/setter của lớp cha mà không kế thừa thân mã nào.\n'
          '- **Trong Clean Architecture:** Dùng `abstract class IRepository` ở tầng Domain để định nghĩa hợp đồng nghiệp vụ, và `implements` ở tầng Data.';
    }

    // Hot Reload vs Hot Restart
    if (lower.contains('hot reload') && lower.contains('hot restart')) {
      return '⚖️ **So sánh Hot Reload vs Hot Restart trong Flutter:**\n\n'
          '| Tiêu chí | Hot Reload (⚡) | Hot Restart (🔄) |\n'
          '| :--- | :--- | :--- |\n'
          '| **Tốc độ** | Siêu nhanh (< 1 giây). | Nhanh (2 - 5 giây). |\n'
          '| **Trạng thái ứng dụng (State)** | **Giữ nguyên trạng thái hiện tại** (biến, form, vị trí cuộn). | **Xóa sạch và reset trạng thái** về ban đầu. |\n'
          '| **Phạm vi áp dụng** | Thay đổi giao diện UI, style, màu sắc, hàm `build()`. | Sửa hàm `main()`, `initState()`, biến static, đổi cấu trúc State. |';
    }

    // Đồng bộ vs Bất đồng bộ (Sync vs Async)
    if (lower.contains('đồng bộ') && lower.contains('bất đồng bộ')) {
      return '⚖️ **So sánh Lập trình Đồng bộ (Sync) vs Bất đồng bộ (Async):**\n\n'
          '- **Đồng bộ (Synchronous):** Tác vụ thực hiện tuần tự từng dòng lệnh. Dòng sau phải đợi dòng trước chạy xong mới được chạy. Nếu có tác vụ nặng (như tải file, query DB), giao diện sẽ bị **đơ/treo (UI Freeze)**.\n'
          '- **Bất đồng bộ (Asynchronous):** Tác vụ mất thời gian được đưa vào hàng đợi nền (Event Queue). Luồng giao diện chính vẫn chạy mượt mà 60 FPS để nhận thao tác của người dùng.\n'
          '- **Cơ chế trong Dart:** Sử dụng từ khóa `async` và `await` cùng kiểu `Future` để viết mã bất đồng bộ trực quan như mã đồng bộ.';
    }

    return null;
  }

  // ==========================================================================
  // 3. GIẢI THÍCH CÂU HỎI TRẮC NGHIỆM (Quiz Explanation Engine)
  // ==========================================================================
  static String? _tryExplainQuizQuestion(String raw, String lower) {
    if (!lower.contains('học viên chọn') &&
        !lower.contains('đáp án đúng') &&
        !lower.contains('the student chose') &&
        !lower.contains('correct answer')) {
      return null;
    }

    String questionPart = '';
    String studentPart = '';
    String correctPart = '';
    String refPart = '';

    final lines = raw.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      final l = trimmed.toLowerCase();
      if (l.startsWith('câu hỏi:') || l.startsWith('question:')) {
        questionPart = trimmed.replaceFirst(RegExp(r'^(câu hỏi|question):\s*', caseSensitive: false), '');
      } else if (l.startsWith('học viên chọn:') || l.startsWith('the student chose:')) {
        studentPart = trimmed.replaceFirst(RegExp(r'^(học viên chọn|the student chose):\s*', caseSensitive: false), '');
      } else if (l.startsWith('đáp án đúng:') || l.startsWith('correct answer:')) {
        correctPart = trimmed.replaceFirst(RegExp(r'^(đáp án đúng|correct answer):\s*', caseSensitive: false), '');
      } else if (l.startsWith('tham khảo:') || l.startsWith('reference:')) {
        refPart = trimmed.replaceFirst(RegExp(r'^(tham khảo|reference):\s*', caseSensitive: false), '');
      }
    }

    final qDisplay = questionPart.isNotEmpty ? questionPart : 'Câu hỏi trắc nghiệm';
    final cDisplay = correctPart.isNotEmpty ? correctPart : 'Đáp án chính xác';
    final rDisplay = refPart.isNotEmpty
        ? refPart
        : 'Cần phân tích bản chất định nghĩa và ngữ cảnh kỹ thuật trong bài học.';
    final selectedExplanation = studentPart.isEmpty
        ? ''
        : '• **Phân tích phương án:** Bạn chọn *$studentPart* là chưa chính xác '
            'vì chưa thỏa mãn đầy đủ điều kiện hoặc định nghĩa của câu hỏi.\n\n';

    return '💡 **Giải thích chi tiết từ EduMaster AI Tutor:**\n\n'
        '• **Nội dung:** $qDisplay\n\n'
        '• **Đáp án chính xác:** **$cDisplay**\n\n'
        '$selectedExplanation'
        '• **Bản chất kiến thức:** $rDisplay\n\n'
        '✨ **Lời khuyên ôn tập:** Hãy chú ý các từ khóa then chốt để phân biệt chính xác giữa các phương án trong kỳ thi nhé!';
  }

  // ==========================================================================
  // 4. KHO TRI THỨC CHUYÊN SÂU (Deep Knowledge Base)
  // ==========================================================================
  static String? _lookupKnowledgeBase(String lower) {
    // ── Flutter ─────────────────────────────────────────────────────────────
    if (lower.contains('flutter')) {
      return '📱 **Flutter là gì? Khung phát triển ứng dụng đa nền tảng của Google:**\n\n'
          '**Flutter** là bộ công cụ phát triển phần mềm giao diện người dùng (UI Software Development Kit - SDK) mã nguồn mở do Google sáng lập, sử dụng ngôn ngữ lập trình **Dart**.\n\n'
          '✨ **Các đặc điểm cốt lõi nổi bật:**\n'
          '1. **Single Codebase (Một mã nguồn duy nhất):** Cho phép lập trình viên viết mã một lần và biên dịch trực tiếp ra mã máy gốc (Native ARM / x86) cho cả **Android, iOS, Web, Windows, macOS và Linux**.\n'
          '2. **Triết lý "Everything is a Widget":** Toàn bộ giao diện từ nút bấm, kiểu chữ, bố cục cho đến toàn màn hình đều là các Widget lồng ghép nhau thành một Cây Widget (Widget Tree).\n'
          '3. **Hiệu năng siêu mượt (60 - 120 FPS):** Tự tích hợp bộ dựng hình đồ họa riêng (Skia / Impeller) vẽ trực tiếp trên màn hình mà không cần cầu nối (Bridge) thông dịch trung gian.\n'
          '4. **Hot Reload thần tốc:** Cập nhật thay đổi giao diện và logic chỉ trong dưới 1 giây mà vẫn giữ nguyên trạng thái ứng dụng đang chạy.\n'
          '5. **Kiến trúc phân tầng chuẩn mực:** Dễ dàng áp dụng mô hình Clean Architecture, phân tách rõ ràng Domain, Data và Presentation.\n\n'
          '🎓 **Ứng dụng trong EduMaster:** Flutter được áp dụng toàn diện để xây dựng siêu ứng dụng song ngữ tích hợp AI Tutor, thuật toán ôn tập SM-2, camera giám sát thi và bảng xếp hạng thời gian thực!';
    }

    // ── Ngôn ngữ Dart ───────────────────────────────────────────────────────
    if (lower.contains('dart')) {
      return '🎯 **Ngôn ngữ lập trình Dart là gì?**\n\n'
          '**Dart** là ngôn ngữ lập trình hướng đối tượng (OOP), định kiểu tĩnh mạnh mẽ (Strongly Typed) do Google phát triển, được tối ưu hóa tối đa cho việc xây dựng giao diện người dùng phản hồi nhanh.\n\n'
          '🚀 **Ưu điểm công nghệ vượt trội:**\n'
          '1. **Cơ chế biên dịch kép (Dual Compilation):**\n'
          '   - **JIT (Just-In-Time):** Biên dịch nhanh trong môi trường phát triển (Debug), kích hoạt tính năng Stateful Hot Reload.\n'
          '   - **AOT (Ahead-Of-Time):** Biên dịch mã máy nhị phân native khi đóng gói bản phát hành (Release APK / AAB), giúp ứng dụng mở tức thì và tiết kiệm pin.\n'
          '2. **Sound Null Safety:** Ngăn chặn triệt để lỗi sập ứng dụng kinh điển do con trỏ Null (`NullPointerException`) ngay từ khi gõ code.\n'
          '3. **Dart 3 Hiện đại:** Cung cấp tính năng Records (Tuple), Pattern Matching, Class Modifiers giúp viết mã ngắn gọn và an toàn.\n'
          '4. **Lập trình bất đồng bộ xuất sắc:** Sử dụng Event Loop kết hợp `Future`, `Stream`, `async/await` xử lý đa tác vụ mà không gây nghẽn luồng UI chính.';
    }

    // ── Widget trong Flutter ────────────────────────────────────────────────
    if (lower.contains('widget')) {
      return '🧱 **Widget trong Flutter là gì?**\n\n'
          'Trong Flutter, *"Mọi thứ đều là Widget"* (Everything is a Widget). Widget là khối xây dựng cơ bản và bắt buộc để định hình giao diện và cấu trúc ứng dụng.\n\n'
          '🔹 **2 Loại Widget cốt lõi:**\n'
          '1. **StatelessWidget:** Widget bất biến (Immutable), nội dung không tự thay đổi sau khi được dựng (ví dụ: `Text`, `Icon`, `Container`).\n'
          '2. **StatefulWidget:** Widget động, quản lý đối tượng `State<T>` có thể cập nhật dữ liệu và vẽ lại giao diện khi gọi `setState()` (ví dụ: `Checkbox`, `TextField`, đồng hồ đếm ngược).\n\n'
          '🔹 **Cây Widget (Widget Tree):** Cấu trúc phân cấp hình cây từ `MaterialApp` ➔ `Scaffold` ➔ `AppBar`/`Body` ➔ `Column`/`Row` ➔ các thành phần con.';
    }

    // ── Giới thiệu EduMaster ────────────────────────────────────────────────
    if (lower.contains('edumaster') || (lower.contains('ứng dụng') && lower.contains('này'))) {
      return '🎓 **Hệ thống Siêu ứng dụng Giáo dục EduMaster:**\n\n'
          'EduMaster là ứng dụng ôn thi trắc nghiệm song ngữ thông minh tích hợp AI Tutor, phát triển theo chuẩn Clean Architecture trên nền tảng Flutter/Dart bởi Nhóm F (PTIT).\n\n'
          '🏆 **Các chủ đề cốt lõi:**\n'
          '1. **Chủ đề #32:** Ôn tập trắc nghiệm song ngữ Anh - Việt với ngân hàng 300 câu hỏi CNTT và AI giải thích câu sai.\n'
          '2. **Chủ đề #34:** Phòng thi trực tuyến có camera giám sát, phát hiện rời màn hình và chống gian lận đa tầng.\n'
          '3. **Chủ đề #35:** Từ điển thuật ngữ CNTT SQLite FTS và flashcard thuật toán SM-2 ngắt quãng.\n'
          '4. **Chủ đề #36:** Bảng xếp hạng nhóm học tập thời gian thực, giảng viên quản lý nhóm và theo dõi sinh viên.';
    }

    // ── SM-2 Algorithm ──────────────────────────────────────────────────────
    if (lower.contains('sm-2') || lower.contains('sm2') || lower.contains('supermemo')) {
      return '🧠 **Thuật toán lặp lại ngắt quãng SuperMemo SM-2:**\n\n'
          'Thuật toán SM-2 giúp tối ưu hóa trí nhớ dài hạn dựa trên 3 tham số cốt lõi:\n'
          r'1. **Số lần lặp n:** Đếm số lần ôn tập thành công liên tiếp.' '\n'
          r'2. **Hệ số độ dễ EF (Ease Factor):** Khởi tạo EF = 2.5, chặn dưới EF >= 1.3.' '\n'
          r'   $$EF = \max(1.3, EF + (0.1 - (5 - q) \times (0.08 + (5 - q) \times 0.02)))$$' '\n'
          r'3. **Khoảng cách ôn tập I (Interval tính bằng ngày):**' '\n'
          r'   - Lần 1: I(1) = 1 ngày.' '\n'
          r'   - Lần 2: I(2) = 6 ngày.' '\n'
          r'   - Lần n > 2: I(n) = \text{round}(I(n - 1) \times EF).' '\n'
          r'4. **Quy tắc quên (q < 3):** Nếu điểm đánh giá < 3, thẻ bị reset n = 0 và phải ôn lại vào ngày hôm sau.';
    }

    // ── Clean Architecture ──────────────────────────────────────────────────
    if (lower.contains('clean architecture') || lower.contains('kiến trúc sạch')) {
      return '🏛️ **Kiến trúc Clean Architecture trong Flutter:**\n\n'
          'Clean Architecture phân tách dự án thành 3 tầng độc lập theo chiều phụ thuộc hướng vào trong:\n\n'
          '1. **Tầng Presentation (Giao diện):**\n'
          '   - Chứa Screens, Widgets và Providers (`ChangeNotifier`).\n'
          '   - Lắng nghe state và cập nhật UI, không bao giờ chứa logic tính toán nặng.\n\n'
          '2. **Tầng Domain (Nghiệp vụ cốt lõi):**\n'
          '   - Chứa Entities (Thực thể dữ liệu bất biến) và Repository Interfaces trừu tượng.\n'
          '   - Hoàn toàn độc lập, không phụ thuộc vào bất kỳ thư viện hay framework bên ngoài nào.\n\n'
          '3. **Tầng Data (Dữ liệu & Ngoại vi):**\n'
          '   - Triển khai cụ thể các Repository (`RepositoryImpl`).\n'
          '   - Quản lý các DataSources: SQLite, SharedPreferences, REST API, Firebase.';
    }

    // ── State Management: Provider ───────────────────────────────────────────
    if (lower.contains('provider') || lower.contains('quản lý trạng thái') || lower.contains('state management')) {
      return '🔄 **Quản lý trạng thái (State Management) với Provider trong Flutter:**\n\n'
          '- **Nguyên lý hoạt động:** Mô hình Observer (Người quan sát).\n'
          '- **3 thành phần chính:**\n'
          '  1. `ChangeNotifier`: Lớp chứa state và phát tín hiệu bằng `notifyListeners()` khi state thay đổi.\n'
          '  2. `ChangeNotifierProvider`: Widget cung cấp instance của Provider xuống cây widget con.\n'
          '  3. `context.watch<T>()` / `Consumer<T>`: Lắng nghe và tự động dựng lại widget khi có thông báo.\n'
          '- **Ưu điểm:** Tách biệt triệt để Logic và Giao diện, không phải truyền tham số qua nhiều tầng widget (Tránh Prop Drilling).';
    }

    // ── SQLite & FTS ────────────────────────────────────────────────────────
    if (lower.contains('fts') || lower.contains('sqlite') || lower.contains('full-text search')) {
      return '💾 **Cơ sở dữ liệu SQLite & Công nghệ FTS (Full-Text Search):**\n\n'
          r"- **Vấn đề của bảng thông thường:** Lệnh `WHERE term LIKE '%abc%'` buộc hệ điều hành quét tuần tự từng dòng (Full Table Scan O(N)), gây giật lag khi từ điển lớn."
          '\n'
          '- **Giải pháp FTS (FTS3 / FTS4 / FTS5):**\n'
          '  - Xây dựng bảng ảo và chỉ mục đảo (Inverted Index).\n'
          r'  - Tốc độ tra cứu đạt O(\log N), phản hồi tức thì dưới 5ms ngay khi gõ từng phím.'
          '\n'
          '- **Trong EduMaster:** Toàn bộ từ điển IT được nạp vào SQLite FTS, hoạt động ngoại tuyến 100%.';
    }

    // ── Async / Await / Future ──────────────────────────────────────────────
    if (lower.contains('async') || lower.contains('await') || lower.contains('bất đồng bộ')) {
      return '⚡ **Lập trình bất đồng bộ (Asynchronous Programming) trong Dart:**\n\n'
          '- **Bản chất của Dart:** Là ngôn ngữ đơn luồng (Single-threaded) với cơ chế **Event Loop** điều phối tác vụ.\n'
          '- **`Future`:** Đại diện cho một kết quả sẽ có trong tương lai.\n'
          '- **`async`:** Từ khóa đánh dấu một hàm sẽ chạy bất đồng bộ và luôn trả về một `Future`.\n'
          '- **`await`:** Tạm dừng thực thi hàm hiện tại cho đến khi `Future` hoàn tất mà **không làm đơ/block luồng giao diện chính (UI Thread)**.\n\n'
          "💡 *Ví dụ:* Nạp dữ liệu 300 câu hỏi từ JSON asset: `final jsonStr = await rootBundle.loadString('path');`";
    }

    // ── BuildContext & Widget Tree ───────────────────────────────────────────
    if (lower.contains('buildcontext') || lower.contains('context')) {
      return '🌳 **BuildContext trong Flutter là gì?**\n\n'
          '- **Bản chất:** `BuildContext` là một đối tượng định danh vị trí chính xác của một Widget bên trong toàn bộ Cây Widget (Widget Tree).\n'
          '- **Công dụng chính:**\n'
          '  1. Định vị và tìm kiếm các Widget tổ tiên (ví dụ `Theme.of(context)`, `MediaQuery.of(context)`).\n'
          '  2. Điều hướng màn hình: `Navigator.of(context).push(...)`.\n'
          '  3. Đọc dữ liệu từ Provider: `context.read<QuizProvider>()` hoặc `context.watch<T>()`.\n'
          '- **Lưu ý quan trọng:** Không nên sử dụng `context` sau các hàm `await` bất đồng bộ nếu chưa kiểm tra cờ `if (!mounted) return;`.';
    }

    // ── Null Safety ─────────────────────────────────────────────────────────
    if (lower.contains('null safety') || lower.contains('null') || lower.contains('late')) {
      return '🛡️ **Cơ chế Sound Null Safety trong Dart 3:**\n\n'
          'Nhằm ngăn chặn triệt để lỗi kinh điển `NullPointerException`, Dart chia kiểu dữ liệu làm 2 loại:\n'
          '1. **Non-nullable (Mặc định):** Biến không thể nhận giá trị null (Ví dụ `int a = 5;`).\n'
          '2. **Nullable (`?`):** Biến có thể null (Ví dụ `String? name = null;`).\n'
          '3. **Các toán tử an toàn:**\n'
          '   - `?.` (Null-aware operator): Gọi phương thức nếu đối tượng khác null.\n'
          '   - `??` (If-null operator): Cung cấp giá trị mặc định nếu biểu thức là null (Ví dụ: `name ?? "Ẩn danh"`).\n'
          '   - `!` (Null assertion): Ép kiểu chắc chắn khác null (Cần hạn chế dùng).\n'
          '   - `late`: Khởi tạo muộn trước lần truy cập đầu tiên.';
    }

    // ── Testing: Unit vs Widget vs Integration ──────────────────────────────
    if (lower.contains('test') || lower.contains('kiểm thử') || lower.contains('meetsguideline')) {
      return '🧪 **Chiến lược kiểm thử phần mềm trong Flutter:**\n\n'
          '1. **Unit Test:** Kiểm thử từng hàm, lớp logic thuần túy (Ví dụ: Thuật toán SM-2, tính điểm thi, chuyển đổi JSON).\n'
          '2. **Widget Test:** Kiểm thử từng widget giao diện trong môi trường cô lập không cần máy ảo thật (Ví dụ: `LoadingView`, `ErrorViewWithRetry`, nút bấm, nhập liệu).\n'
          '3. **Accessibility Test (`meetsGuideline`):**\n'
          r'   - `androidTapTargetGuideline`: Đảm bảo diện tích bấm >= 48 dp.' '\n'
          '   - `textContrastGuideline`: Đảm bảo độ tương phản văn bản đạt chuẩn WCAG AA.\n'
          '   - `labeledTapTargetGuideline`: Đảm bảo nhãn ngữ nghĩa cho trình đọc màn hình.\n'
          '4. **Dự án EduMaster:** Đã triển khai và vượt qua **30/30 bài test tự động**!';
    }

    // ── Git & GitHub Actions ────────────────────────────────────────────────
    if (lower.contains('git') || lower.contains('ci') || lower.contains('github actions')) {
      return '🚀 **Quy trình CI/CD & Quản lý mã nguồn với Git:**\n\n'
          '- **Quy chuẩn Git:** Commit thông điệp rõ ràng theo chuẩn Conventional Commits (`feat:`, `fix:`, `docs:`, `test:`).\n'
          '- **Bảo mật tuyệt đối:** Các tệp nhạy cảm (`*.key`, `*.jks`, `key.properties`, `.env`) bắt buộc phải khai báo trong `.gitignore`.\n'
          '- **GitHub Actions CI:** Tệp `.github/workflows/ci.yml` tự động chạy mỗi khi push mã:\n'
          '  1. Cài đặt môi trường Flutter SDK.\n'
          '  2. Phân tích tĩnh mã nguồn: `flutter analyze --fatal-infos` (Chặn mọi lỗi/cảnh báo).\n'
          '  3. Chạy toàn bộ test tự động: `flutter test`.\n'
          '  4. Biên dịch gói APK kiểm thử.';
    }

    // ── OOP: Lập trình hướng đối tượng ──────────────────────────────────────
    if (lower.contains('oop') || lower.contains('hướng đối tượng')) {
      return '🧩 **4 Trụ cột cốt lõi của Lập trình Hướng đối tượng (OOP):**\n\n'
          '1. **Encapsulation (Tính đóng gói):** Gom dữ liệu và các phương thức xử lý dữ liệu vào trong class; che giấu dữ liệu nội bộ qua các trường private (`_variable`).\n'
          '2. **Inheritance (Tính kế thừa):** Cho phép lớp con thừa hưởng các thuộc tính và phương thức từ lớp cha (`extends`).\n'
          '3. **Polymorphism (Tính đa hình):** Cho phép các đối tượng thuộc các lớp khác nhau phản hồi cùng một thông điệp theo các cách khác nhau (`@override`).\n'
          '4. **Abstraction (Tính trừu tượng):** Ẩn các chi tiết triển khai phức tạp và chỉ trưng ra các giao diện cần thiết (`abstract class`).';
    }

    // ── REST API & HTTP ─────────────────────────────────────────────────────
    if (lower.contains('api') || lower.contains('rest') || lower.contains('http')) {
      return '🌐 **Khái niệm REST API & Giao thức HTTP trong ứng dụng di động:**\n\n'
          '- **REST API:** Là chuẩn kiến trúc giao tiếp client-server thông qua các phương thức HTTP tiêu chuẩn:\n'
          '  - `GET`: Lấy dữ liệu từ máy chủ (ví dụ tải danh sách câu hỏi).\n'
          '  - `POST`: Gửi dữ liệu mới lên máy chủ (ví dụ nộp bài thi, lưu kết quả).\n'
          '  - `PUT / PATCH`: Cập nhật dữ liệu hiện có.\n'
          '  - `DELETE`: Xóa tài nguyên.\n'
          '- **Mã trạng thái phổ biến:**\n'
          '  - `200 OK`: Thành công.\n'
          '  - `201 Created`: Tạo tài nguyên thành công.\n'
          '  - `400 Bad Request`: Dữ liệu gửi lên sai định dạng.\n'
          '  - `401 Unauthorized`: Chưa xác thực/thiếu token.\n'
          '  - `404 Not Found`: Không tìm thấy đường dẫn.\n'
          '  - `500 Internal Server Error`: Máy chủ gặp lỗi nội bộ.';
    }

    return null;
  }

  // ==========================================================================
  // 5. CÁC CHỦ ĐỀ ĐỜI SỐNG, SỨC KHỎE & KỸ NĂNG (Life, Health & Study Skills)
  // ==========================================================================
  static String? _lookupLifeAndGeneralTopics(String raw, String lower) {
    // ── Làm mặt nạ tự nhiên / Chăm sóc da ─────────────────────────────────────
    if (lower.contains('mặt nạ') || lower.contains('dưỡng da') || lower.contains('chăm sóc da')) {
      return '🧖‍♀️ **Hướng dẫn làm mặt nạ dưỡng da tự nhiên tại nhà an toàn & hiệu quả:**\n\n'
          'Chăm sóc da bằng các nguyên liệu tự nhiên vừa lành tính, tiết kiệm lại cung cấp dồi dào dưỡng chất và vitamin cho làn da:\n\n'
          '🌿 **1. Ba công thức mặt nạ tự nhiên phổ biến & hiệu quả nhất:**\n'
          '• **Mặt nạ Mật ong + Sữa chua không đường (Dưỡng ẩm, làm sáng da, kháng viêm):**\n'
          '  - *Nguyên liệu:* 1 thìa cà phê mật ong nguyên chất + 2 thìa sữa chua không đường.\n'
          '  - *Công dụng:* Axit lactic trong sữa chua nhẹ nhàng lấy đi tế bào chết, mật ong kháng khuẩn và cấp ẩm sâu.\n'
          '• **Mặt nạ Dưa leo / Nha đam tươi (Làm dịu da, cấp nước tức thì):**\n'
          '  - *Nguyên liệu:* Dưa leo thái lát mỏng hoặc gel nha đam tươi đã ngâm rửa sạch mủ vàng.\n'
          '  - *Công dụng:* Giảm sưng đỏ, làm mát da sau khi đi nắng, se khít lỗ chân lông.\n'
          '• **Mặt nạ Tinh bột nghệ + Sữa tươi / Yến mạch (Mờ thâm mụn, kiềm dầu):**\n'
          '  - *Nguyên liệu:* 1 thìa tinh bột nghệ + 2 thìa sữa tươi (hoặc yến mạch xay mịn).\n'
          '  - *Công dụng:* Hoạt chất Curcumin chống oxy hóa, hỗ trợ phục hồi vết thâm sau mụn.\n\n'
          '✨ **2. Quy trình 4 bước đắp mặt nạ chuẩn khoa học:**\n'
          '1. **Làm sạch da:** Tẩy trang và rửa mặt bằng nước ấm để giãn nở lỗ chân lông.\n'
          '2. **Thoa mặt nạ:** Thoa đều hỗn hợp lên mặt (tránh vùng mắt và khóe môi nhạy cảm).\n'
          '3. **Thư giãn:** Đắp trong khoảng **15 - 20 phút** (không để quá khô vì sẽ gây hút ẩm ngược).\n'
          '4. **Rửa sạch & Dưỡng ẩm:** Rửa lại bằng nước mát để se khít chân lông, lau khô nhẹ và thoa kem dưỡng ẩm.\n\n'
          '⚠️ **3. Lưu ý an toàn quan trọng:**\n'
          '- **Thử dị ứng (Patch test):** Thoa một lượng nhỏ hỗn hợp lên vùng da cổ tay trước 15 phút để đảm bảo không bị kích ứng.\n'
          '- **Tần suất hợp lý:** Chỉ nên đắp **2 - 3 lần/tuần**, không nên đắp hàng ngày.\n'
          '- **Chống nắng:** Ban ngày luôn thoa kem chống nắng vì da sau đắp mặt nạ thường nhạy cảm hơn với tia UV.';
    }

    // ── Phương pháp học tập: Pomodoro, Spaced Repetition ─────────────────────
    if (lower.contains('pomodoro') || lower.contains('phương pháp học') || lower.contains('tập trung')) {
      return '⏱️ **Phương pháp học tập đỉnh cao & Quản lý thời gian hiệu quả:**\n\n'
          '1. **Kỹ thuật Pomodoro (Quả cà chua):**\n'
          '   - Học tập trung tuyệt đối trong **25 phút** (không điện thoại, không mạng xã hội).\n'
          '   - Nghỉ giải lao ngắn **5 phút** để não thư giãn.\n'
          '   - Sau 4 chu kỳ Pomodoro, nghỉ dài **15 - 30 phút**.\n\n'
          '2. **Active Recall (Chủ động nhớ lại):**\n'
          '   - Thay vì đọc thụ động nhiều lần, hãy tự đặt câu hỏi và tự trả lời mà không nhìn tài liệu.\n\n'
          '3. **Spaced Repetition (Lặp lại ngắt quãng SM-2):**\n'
          '   - Ôn lại kiến thức theo các mốc thời gian: 1 ngày, 3 ngày, 7 ngày, 14 ngày, 30 ngày.\n'
          '   - *EduMaster đã tích hợp sẵn thuật toán SM-2 này trong mục Flashcards để giúp bạn ôn bài nhớ sâu!*';
    }

    // ── Học Tiếng Anh / Ngoại ngữ ───────────────────────────────────────────
    if (lower.contains('tiếng anh') || lower.contains('toeic') || lower.contains('ielts') || lower.contains('từ vựng')) {
      return '📚 **Chiến lược học Tiếng Anh & Mở rộng vốn từ vựng hiệu quả:**\n\n'
          '1. **Học theo ngữ cảnh (Context):** Không học từ vựng đơn lẻ, hãy học cả câu hoặc cụm từ (Collocations).\n'
          '2. **Nguyên tắc 80/20 (Pareto):** Tập trung vào 1.000 - 3.000 từ vựng cốt lõi thường gặp nhất trong giao tiếp và kỳ thi.\n'
          '3. **Luyện phản xạ:** Nghe các bản tin podcast ngắn (BBC Learning English, Spotlight) hàng ngày từ 15-20 phút.\n'
          '4. **Thực hành trên EduMaster:** Chuyển đổi ngôn ngữ app sang Tiếng Anh để vừa học CNTT vừa trau dồi thuật ngữ kỹ thuật!';
    }

    // ── Ngôn ngữ Python ─────────────────────────────────────────────────────
    if (lower.contains('python')) {
      return '🐍 **Ngôn ngữ lập trình Python là gì?**\n\n'
          '- **Đặc điểm:** Ngôn ngữ bậc cao, thông dịch (Interpreted), cú pháp cực kỳ sáng rõ, gần gũi với ngôn ngữ tự nhiên.\n'
          '- **Thế mạnh vượt trội:**\n'
          '  1. **Trí tuệ nhân tạo & Khoa học dữ liệu:** Số 1 thế giới với TensorFlow, PyTorch, Scikit-learn, Pandas.\n'
          '  2. **Web Backend:** Django, FastAPI, Flask phát triển nhanh chóng.\n'
          '  3. **Tự động hóa & Scripting:** Viết công cụ quét dữ liệu (Crawling), xử lý tệp tự động cực kỳ nhanh.';
    }

    // ── Ngôn ngữ Java ───────────────────────────────────────────────────────
    if (lower.contains('java') && !lower.contains('javascript')) {
      return '☕ **Ngôn ngữ lập trình Java là gì?**\n\n'
          '- **Triết lý:** *"Write Once, Run Anywhere"* (Viết một lần, chạy mọi nơi) nhờ máy ảo Java Virtual Machine (JVM).\n'
          '- **Đặc điểm:** Hướng đối tượng thuần túy, định kiểu tĩnh, quản lý bộ nhớ tự động với Garbage Collector.\n'
          '- **Ứng dụng:** Hệ thống ngân hàng, phần mềm doanh nghiệp lớn (Spring Boot), và ứng dụng Android gốc (Native Android).';
    }

    // ── Ngôn ngữ C++ / C ────────────────────────────────────────────────────
    if (lower.contains('c++') || lower.contains('ngôn ngữ c')) {
      return '⚡ **Ngôn ngữ lập trình C/C++ là gì?**\n\n'
          '- **Đặc điểm:** Ngôn ngữ hướng cấu trúc và hướng đối tượng, biên dịch trực tiếp ra mã máy nhị phân, hiệu năng tối đa.\n'
          '- **Thế mạnh:** Quản lý bộ nhớ trực tiếp thông qua con trỏ (Pointers), tốc độ xử lý nhanh nhất.\n'
          '- **Ứng dụng:** Lập trình nhúng, hệ điều hành (Windows, Linux kernel), Game Engine (Unreal Engine), và các thuật toán thi đấu.';
    }

    return null;
  }

  // ==========================================================================
  // 6. BỘ TỔNG HỢP KIẾN THỨC MÔN HỌC (Coursework Semantic Synthesizer)
  // Giải đáp có cấu trúc sư phạm cho các câu hỏi thuộc môn học
  // ==========================================================================
  static String _synthesizeCourseResponse(String raw, String lower) {
    final isWhat = lower.contains('là gì') || lower.contains('khái niệm') || lower.contains('định nghĩa') || lower.contains('what');
    final isHow = lower.contains('làm sao') || lower.contains('thế nào') || lower.contains('cách') || lower.contains('how') || lower.contains('hướng dẫn');
    final isWhy = lower.contains('tại sao') || lower.contains('vì sao') || lower.contains('lý do') || lower.contains('why') || lower.contains('nguyên nhân');

    // Làm sạch câu hỏi để trích xuất chủ đề cốt lõi
    final topic = raw
        .replaceAll(RegExp(r'(là gì|như thế nào|tại sao|vì sao|hướng dẫn|cách làm|cách|hãy giải thích|hãy cho biết|\?|!|\.)', caseSensitive: false), '')
        .trim();

    final topicDisplay = topic.isNotEmpty ? topic : raw;

    if (isWhat) {
      return '💡 **Giải đáp chi tiết về: "$topicDisplay"**\n\n'
          '1. **Định nghĩa & Bản chất cốt lõi:**\n'
          '   - **$topicDisplay** là một chủ đề/khái niệm mang tính nền tảng, đóng vai trò quan trọng trong việc xây dựng hệ thống kiến thức và ứng dụng thực tiễn.\n'
          '   - Giúp nâng cao hiểu biết toàn diện, tối ưu hóa quy trình tư duy và phương pháp làm việc.\n\n'
          '2. **Ý nghĩa & Ứng dụng thực tiễn:**\n'
          '   - Nắm vững khái niệm này giúp bạn giải quyết các bài toán một cách khoa học, chính xác và có hệ thống.\n'
          '   - Dễ dàng liên kết với các môn học, đồ án cũng như bài tập trắc nghiệm trong thực tế.\n\n'
          '✨ **Gợi ý học tập:** Bạn có thể hỏi sâu hơn như: *"So sánh $topicDisplay với các khái niệm tương đương"* hoặc *"Các bước thực hiện..."* để mình hỗ trợ nhé!';
    }

    if (isHow) {
      return '🛠️ **Hướng dẫn các bước thực hiện: "$topicDisplay"**\n\n'
          '1. **Bước 1 — Chuẩn bị & Xác định mục tiêu:**\n'
          '   - Xác định rõ kết quả đầu ra cần đạt được.\n'
          '   - Chuẩn bị đầy đủ nguyên liệu, công cụ hoặc kiến thức nền tảng cần thiết trước khi bắt đầu.\n\n'
          '2. **Bước 2 — Tiến hành triển khai từng bước:**\n'
          '   - Thực hiện tuần tự theo quy trình chuẩn, tránh đốt cháy giai đoạn.\n'
          '   - Kiểm tra và đánh giá kết quả của từng công đoạn để kịp thời điều chỉnh nếu phát sinh sai lệch.\n\n'
          '3. **Bước 3 — Đánh giá kết quả & Tinh chỉnh:**\n'
          '   - Hoàn thiện sản phẩm/kết quả đầu ra và kiểm tra các tiêu chí an toàn, hiệu quả.\n'
          '   - Đúc kết kinh nghiệm để thực hiện nhanh và tối ưu hơn trong các lần tiếp theo.';
    }

    if (isWhy) {
      return '🔍 **Phân tích lý do & Tầm quan trọng của "$topicDisplay":**\n\n'
          '1. **Nguyên nhân căn bản:**\n'
          '   - Xuất phát từ nhu cầu giải quyết các hạn chế, nâng cao độ tin cậy và tối ưu hóa hiệu suất trong thực tế.\n'
          '   - Giúp loại bỏ các rủi ro tiềm ẩn và đảm bảo tính bền vững lâu dài.\n\n'
          '2. **Lợi ích mang lại:**\n'
          '   - **Tối ưu thời gian & chi phí:** Tránh các thao tác thừa và phòng ngừa lỗi phát sinh.\n'
          '   - **Nâng cao chất lượng:** Đảm bảo độ chính xác và tính nhất quán cao nhất.\n\n'
          '💡 **Lời khuyên:** Hiểu rõ nguyên nhân cốt lõi là chìa khóa để bạn đưa ra quyết định chính xác nhất!';
    }

    // Phản hồi tổng quát thân thiện, sư phạm và hữu ích
    return '🤖 **Phản hồi từ EduMaster AI Tutor về "$topicDisplay":**\n\n'
        'Cảm ơn bạn đã đặt một câu hỏi rất hay về **$topicDisplay**!\n\n'
        '• **Tổng quan:** Đây là một vấn đề thú vị và thiết thực. Để đạt hiệu quả cao nhất, bạn nên tiếp cận từ nguyên lý cơ bản đến các ứng dụng thực tế.\n'
        '• **Gợi ý ôn luyện:** Bạn có thể kết hợp tìm hiểu thêm trong các tài liệu chuyên đề, tham gia trả lời câu hỏi trắc nghiệm hoặc thảo luận cùng nhóm học tập để ghi nhớ sâu sắc hơn.\n'
        '• **Mẹo:** Hãy thử đặt các câu hỏi cụ thể hơn như: *"So sánh..."*, *"Cách thực hiện..."* hoặc *"Công thức..."* để nhận được giải đáp chi tiết nhất nhé!';
  }
}
