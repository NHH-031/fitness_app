# LỜI MỞ ĐẦU

## 1. Lý do chọn đề tài

Theo dõi vận động, kiểm soát dinh dưỡng và duy trì lối sống lành mạnh là nhu cầu thiết yếu hiện nay. Người dùng mong muốn ứng dụng di động tự động ghi nhận hoạt động, nhắc uống nước và phân tích khẩu phần ăn hàng ngày.

Hệ điều hành Android áp dụng chính sách quản lý tài nguyên nghiêm ngặt: siết chặt tác vụ ngầm qua chế độ ngủ sâu (*Doze Mode*), phân loại dịch vụ tiền cảnh (*Foreground Service Types* như `health` từ Android 14), và kiểm soát quyền truy cập cảm biến. Điều này đòi hỏi ứng dụng phải đếm bước liên tục, bền bỉ ngay cả khi tắt màn hình hay khởi động lại máy, đồng thời giảm tiêu hao pin.

Mô hình Google Gemini (`gemini-2.5-flash`) hỗ trợ nhận diện món ăn qua hình ảnh, văn bản và giọng nói để ước tính năng lượng, dinh dưỡng.

Từ thực tiễn đó, nhóm chọn đề tài: **"Xây dựng ứng dụng theo dõi sức khỏe và luyện tập Fitness Tracker trên nền tảng Android tích hợp trí tuệ nhân tạo Gemini"** cho đồ án môn Lập trình Android nâng cao.

## 2. Mục tiêu của đề tài

Đề tài xây dựng ứng dụng kết hợp Flutter và native Android (Kotlin) với các mục tiêu:

- **Ứng dụng thành phần cốt lõi Android**: Hiện thực dịch vụ tiền cảnh `StepCounterService` loại `health` kết hợp gộp mẫu cảm biến (*Sensor Batching 10s*) trên `TYPE_STEP_COUNTER` để tiết kiệm pin; đăng ký `BootReceiver` tự phục hồi sau khởi động máy; phát triển tiện ích màn hình chính (*App Widget*) bằng `AppWidgetProvider` và `RemoteViews`.
- **Thiết lập cầu nối nền tảng**: Xây dựng kênh giao tiếp hai chiều qua `MethodChannel` (điều khiển dịch vụ, xin miễn trừ Doze Mode, làm mới widget) và `EventChannel` (truyền luồng bước chân); chia sẻ dữ liệu qua `FlutterSharedPreferences`.
- **Kiến trúc dữ liệu cục bộ trước tiên (*Local-First*)**: Lưu trữ dữ liệu trên thiết bị bằng SQLite (7 bảng có chỉ mục) kết hợp SharedPreferences, bảo đảm hoạt động khi mất mạng; đồng bộ hai chiều với Cloud Firestore khi đăng nhập Google.
- **Tích hợp trí tuệ nhân tạo**: Ứng dụng Gemini AI (`gemini-2.5-flash`) kết hợp quét mã vạch Open Food Facts và nhận diện giọng nói để ghi nhận thực phẩm, tư vấn dinh dưỡng và tạo bài tập.

## 3. Phạm vi nghiên cứu & phát triển

- **Phạm vi nền tảng**: Nghiên cứu Android từ `minSdk = 26` đến Android 16 (API 36). Thử nghiệm thực tế trên Xiaomi HyperOS 3.0 (Android 16) và môi trường ADB.
- **Phạm vi chức năng**: Ứng dụng gồm 4 phân hệ chính:
  1. *Vận động và sinh hoạt*: Đếm bước chân nền, tính calo tiêu hao, theo dõi nước uống và nhắc nhở theo giờ.
  2. *Luyện tập thể chất*: Danh mục 17 bài tập, mô phỏng động tác trên mô hình cấu trúc cơ 2D (18 khớp, 21 động tác), AI tạo bài tập, thông báo đếm ngược nghỉ hiệp.
  3. *Dinh dưỡng thông minh*: Quét mã vạch sản phẩm, nhận diện món ăn qua ảnh, văn bản và giọng nói bằng Gemini AI, tính calo nạp/tiêu.
  4. *Hồ sơ và an toàn*: Tính chỉ số sinh trắc (BMI, BMR, TDEE, tỷ lệ mỡ), khóa bảo vệ sinh trắc học (*BiometricPrompt*), kết nối Health Connect.
- **Giới hạn đề tài**: Sử dụng cảm biến tích hợp trên điện thoại; tính năng AI gọi API trực tuyến của Google.

## 4. Cấu trúc báo cáo

Báo cáo gồm 5 chương:

- **Chương 1. Giới thiệu chung & cơ sở lý thuyết**: Trình bày bài toán theo dõi sức khỏe, thành phần Android cơ bản, kiến trúc Flutter, Platform Channels, bảng công nghệ và môi trường phát triển.
- **Chương 2. Phân tích & thiết kế hệ thống**: Trình bày yêu cầu hệ thống, use case, kiến trúc dữ liệu cục bộ trước tiên (*Local-First*), cấu trúc mã nguồn, thiết kế CSDL SQLite, SharedPreferences, Firestore và luồng khởi chạy.
- **Chương 3. Các kỹ thuật lập trình Android trong ứng dụng**: Trình bày Foreground Service loại `health`, giải thuật bù trừ bước chân sau reboot, gộp mẫu cảm biến, BootReceiver, App Widget, tối ưu pin Doze Mode, Platform Channels, Health Connect và sinh trắc học.
- **Chương 4. Cài đặt & kết quả chức năng**: Trình bày kết quả giao diện: Dashboard, phân hệ luyện tập và mô hình cấu trúc cơ 2D, phân hệ dinh dưỡng thông minh với Gemini AI, hồ sơ và đồng bộ dữ liệu.
- **Chương 5. Kiểm thử, đánh giá & kết luận**: Đánh giá kiểm thử tự động (123 test case), CI/CD, thử nghiệm thiết bị thật qua lệnh ADB, hạn chế tồn đọng, hướng phát triển và kết luận.
