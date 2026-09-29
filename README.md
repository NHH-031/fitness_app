# 🏋️ Fitness Tracker (Fitness App)

Một ứng dụng theo dõi sức khỏe và thể hình thông minh trên nền tảng **Flutter**, tích hợp Huấn luyện viên AI cá nhân hóa (Google Gemini), mô hình giải phẫu động học cử động bài tập chuẩn xác (Kinematic Anatomy Models), đếm bước chân thời gian thực qua Android Foreground Service, tiện ích màn hình chính (Android Home Screen Widget), đồng bộ thiết bị đeo thông minh (Smartwatch qua Health Connect / Apple Health), quét mã vạch dinh dưỡng (Open Food Facts), bảo mật sinh trắc học (Biometric Lock), lưu trữ cục bộ bảo mật SQLite (Local-First Architecture) và đồng bộ đám mây Firebase.

- **Định danh gói ứng dụng (Application ID)**: `com.nhh031.fitness_tracker`
- **Tên hiển thị ứng dụng (App Name)**: `Fitness Tracker`
- **Kho lưu trữ chính thức (GitHub)**: [https://github.com/NHH-031/fitness_app](https://github.com/NHH-031/fitness_app)

---

## ✨ Tính năng nổi bật

### 🦾 1. Mô hình Giải phẫu Động học Cử động Bài tập (Kinematic Anatomy Models v2.0)
- **Mô phỏng 2D sinh cơ học thời gian thực** (`AnatomyKinematicPainter`, `ExercisePoseWidget`): Tái hiện chuyển động khung xương và cơ bắp người tập trực tiếp bằng Vector Canvas 60 FPS mượt mà, không phụ thuộc vào video clip dung lượng nặng.
- **Thanh điều khiển Hoạt ảnh Tương tác Trực tiếp (Interactive Playback Controls)**:
  - **Nút Tạm dừng / Tiếp tục (Play/Pause `⏸` / `▶`)**: Dừng khung hình ở bất kỳ thời điểm nào để người tập chỉnh phom.
  - **Thanh kéo Scrubber Slider**: Tự do kéo tua tiến / lùi mượt mà đến từng góc uốn gập của khớp xương và cơ bắp.
  - **Nút đổi tốc độ phát (Speed Toggle `1.0x` / `0.5x` / `1.5x`)**: Chế độ tua chậm Slow-motion 0.5x hỗ trợ người mới quan sát chuẩn xác từng kỹ thuật động tác.
- **Vệt Chuyển Động Phát Sáng Huỳnh Quang (Glowing Motion Trajectory Trails)**: Vẽ vệt sáng neon chuyển động mềm mại theo quỹ đạo của cổ tay và mắt cá chân, hỗ trợ định hướng đường đi lực đẩy/kéo chuẩn thể hình.
- **Cải tiến Sinh cơ học Động tác Chân thực (10/10 Biomechanics)**:
  - **Mountain Climber (Leo núi)**: Tái hiện chân gần và chân xa co duỗi so le lệch pha 180° chân thực theo nhịp đạp xe/chạy leo núi.
  - **Nhảy Burpees đốt mỡ**: Chu kỳ 4 pha chuẩn mực: Đứng thẳng $\to$ Hạ người chống tay $\to$ Bật 2 chân ra sau hạ ngực hít đất $\to$ Thu chân co gối $\to$ Bật nhảy cao vươn 2 tay qua đầu.
- **Bảo toàn chiều dài xương (Constant-Length Bones)**: Tính toán lượng giác học ($\sin / \cos$), giữ nguyên độ dài cẳng chân, đùi, cánh tay, cẳng tay trong suốt chuyển động (loại bỏ hiện tượng xương bị co giãn biến dạng cao su).
- **Phát sáng kích hoạt nhóm cơ mục tiêu (Target Muscle Activation Glow)**: Nhóm cơ tác động chính (Ngực, Đùi trước, Mông, Lưng xô, Vai, Tay trước/sau, Cơ bụng...) phát sáng cường độ cao kèm hiển thị tỷ lệ % co cơ thời gian thực.
- **Phân loại bài tập Bodyweight vs Dumbbell (Tạ đơn)**: Hỗ trợ bài tập tự do tại nhà và bài tập tạ đơn chuyên sâu kèm trọng lượng tạ thực tế.
- **Bảng hướng dẫn kỹ thuật chi tiết (Exercise Guide Sheet)**: Cung cấp đầy đủ các bước thực hiện, phân tích cơ mục tiêu, cơ bổ trợ, các lỗi sai thường gặp (Common Mistakes), nhịp thở chuẩn và lưu ý an toàn tránh chấn thương.

---

### 🤖 2. Huấn luyện viên AI & Phân tích dinh dưỡng (Google Gemini 2.5 Flash)
- **Phân tích hình ảnh món ăn đa phương thức (Multimodal AI Vision)**: Chụp ảnh trực tiếp hoặc chọn từ thư viện, AI tự động nhận diện món ăn và ước lượng Calo, Đạm (Protein), Tinh bột (Carbs), Chất béo (Fat).
- **Trò chuyện & Tư vấn 24/7**: Chatbot AI đóng vai huấn luyện viên thể hình cá nhân hóa, tư vấn dinh dưỡng và lịch tập dựa trên chỉ số sinh trắc học và lịch sử hoạt động thực tế.
- **Bản tin sức khỏe hàng ngày (Daily AI Health Briefing)**: Đánh giá tự động chất lượng ngày tập luyện, giấc ngủ, lượng nước và đưa ra lời khuyên khởi động ngày mới.
- **Bộ nhớ đệm dinh dưỡng thông minh (Zero-latency offline cache)**: Tự động ghi nhớ các món đã tra cứu, truy vấn tức thì kể cả khi mất kết nối mạng.

---

### 🏷️ 3. Quét mã vạch thực phẩm (Barcode Nutrition Scanner)
- Tích hợp camera quét mã vạch thời gian thực (`mobile_scanner`).
- Kết nối trực tiếp cơ sở dữ liệu thực phẩm quốc tế & Việt Nam **Open Food Facts REST API**.
- Tự động bóc tách năng lượng (kcal/kJ), Đạm (Protein), Tinh bột (Carbs), Chất béo (Fat).
- Tùy chỉnh khẩu phần ăn linh hoạt (0.5x, 1x, 1.5x, 2x) và ghi log theo từng bữa (Sáng, Trưa, Tối, Bữa phụ).

---

### 📱 4. Tiện ích Màn hình chính Android (Android Home Screen Widget)
- Tích hợp **Android AppWidget Provider** (`FitnessAppWidgetProvider.kt`): Hiển thị trực tiếp số bước chân hàng ngày (Step Count), tiến độ mục tiêu (%) và lượng calo tiêu hao ra ngay màn hình chính điện thoại mà không cần mở ứng dụng.
- Tự động làm mới và đồng bộ theo thời gian thực mỗi khi có bước chân mới từ Foreground Service.

---

### 🔒 5. Bảo mật Sinh trắc học (Biometric App Lock & Privacy Gate)
- Bảo vệ dữ liệu sức khỏe và hình thể cá nhân bằng dấu vân tay (Fingerprint) hoặc nhận diện khuôn mặt (Face Unlock / Biometrics) qua `local_auth`.
- Tự động kích hoạt màn hình khóa riêng tư (`BiometricGate`) khi ứng dụng tạm ẩn hoặc sau khoảng thời gian chờ an toàn.

---

### ⌚ 6. Đồng bộ thiết bị đeo & Google Health Connect / Apple Health
- Tự động đọc dữ liệu bước chân, nhịp tim (Heart Rate), thời lượng giấc ngủ (Sleep) và calo tiêu hao từ Smartwatch (Samsung Galaxy Watch, Apple Watch, Garmin, Xiaomi Mi Band,...).
- Thẻ quản lý đồng bộ trực quan trong màn hình Hồ sơ với nút "ĐỒNG BỘ NGAY".

---

### 🚶 7. Đếm bước chân nền bền vững (Persistent Background Step Tracker)
- Sử dụng Android Foreground Service kết hợp cảm biến phần cứng chuyên dụng của thiết bị.
- Tích hợp bộ lọc chống rung xe (Anti-Jitter) và cơ chế lưu trữ bảo toàn số bước kể cả khi thiết bị khởi động lại (Reboot resilience).

---

### 🗄️ 8. Kiến trúc Local-First SQLite Database & Clean Architecture
- Lưu trữ độc lập toàn bộ lịch sử tập luyện, nhật ký dinh dưỡng, nước uống và hội thoại AI vào cơ sở dữ liệu SQLite (`sqflite`).
- Thiết kế theo mô hình Repository Pattern chuẩn mực (`WorkoutRepository`, `NutritionRepository`, `WaterRepository`, `ChatRepository`, `StepRepository`, `AuthRepository`).
- Tách biệt module tính toán chỉ số cơ thể `UserMetricsService` (BMI, BMR, TDEE, Calorie Deficit) giúp giảm tải code và tối ưu bộ nhớ.
- Quản lý vòng đời `ActiveWorkoutScreen` với cơ chế hủy Timer (`dispose()`) an toàn, triệt tiêu nguy cơ rò rỉ bộ nhớ (memory leak).

---

### 💧 9. Theo dõi Nước uống (Hydration) & Sức khỏe toàn diện
- Ghi nhận lượng nước uống theo cốc/ml, tùy chỉnh lời nhắc uống nước định kỳ thông minh kèm phản hồi rung Haptic.
- **Điểm Sức Khỏe Toàn Diện (Holistic Health Score)**: Thuật toán chấm điểm dựa trên 5 trụ cột: Vận động, Giấc ngủ, Nước uống, Dinh dưỡng và Tỷ lệ Calo tiêu thụ/nạp.
- Tính toán TDEE, BMR, Calorie Deficit/Surplus và phân bổ Macro phù hợp mục tiêu: Siết mỡ (Cutting), Tăng cơ (Bulking), Bền bỉ (Endurance), Cân bằng (Balanced).
- Hệ thống huy hiệu thành tích (Achievement Badges) và chuỗi ngày rèn luyện liên tục (Streaks).
- Đa ngôn ngữ: Chuyển đổi linh hoạt giữa Tiếng Việt và English.
- Hỗ trợ đăng nhập Google Sign-In, Firebase Auth hoặc Chế độ Khách (Guest Mode) không cần tài khoản.

---

## 🛠️ YÊU CẦU MÔI TRƯỜNG & CHUẨN BỊ BAN ĐẦU

### 1. Yêu cầu hệ thống
- **Flutter SDK**: Phiên bản `>= 3.24.0` (Khuyên dùng Flutter 3.27+).
- **Dart SDK**: Phiên bản `>= 3.5.0 < 4.0.0`.
- **Java Development Kit (JDK)**: JDK 17 (khuyên dùng OpenJDK 17).
- **Android Studio & SDK**:
  - Android SDK Platform 34 hoặc 35.
  - Android SDK Build-Tools 34.0.0+.
  - Android SDK Command-line Tools & Platform-tools (`adb`).
- **Hệ điều hành**: Windows 10/11, macOS, hoặc Linux.

### 2. Cài đặt các gói phụ thuộc (Dependencies)
Mở Terminal tại thư mục `fitness_tracker/` và chạy:
```bash
flutter pub get
```

### 3. Cấu hình biến môi trường (`.env`)
Tạo file `.env` tại thư mục gốc của dự án `fitness_tracker/`:
```bash
cp .env.example .env
```
Mở file `.env` và điền API Key từ [Google AI Studio](https://aistudio.google.com/):
```env
GEMINI_API_KEY=your_actual_gemini_api_key_here
```

---

## 💻 PHẦN A: HƯỚNG DẪN CHẠY TRÊN MÁY ẢO ANDROID (ANDROID EMULATOR)

Máy ảo Android (AVD - Android Virtual Device) trong Android Studio là môi trường lý tưởng để lập trình, debug giao diện, kiểm tra hoạt ảnh và phát triển tính năng với tốc độ tải lại (Hot Reload) cực nhanh.

### Bước A1: Khởi tạo và bật máy ảo Android
1. Mở **Android Studio** $\to$ Chọn **Tools** $\to$ **Device Manager** (hoặc biểu tượng điện thoại ở góc phải).
2. Nhấn **Create Device** (hoặc dấu `+`):
   - **Device Definition**: Chọn điện thoại phổ biến như **Pixel 7**, **Pixel 8**, hoặc **Phone 1080x2400**.
   - **System Image**: Chọn bản phát hành Android hiện đại kiến trúc `x86_64` (Khuyên dùng **API 34 / Android 14** hoặc **API 35 / Android 15** có sẵn Google APIs / Google Play Store).
3. Nhấn **Finish**, sau đó nhấn nút **Play (▶)** để khởi động máy ảo.
4. Chờ máy ảo khởi động hoàn tất lên màn hình chính của Android.

### Bước A2: Kiểm tra thiết bị máy ảo từ Terminal
Mở cửa sổ dòng lệnh (PowerShell / Command Prompt / Terminal) và kiểm tra danh sách thiết bị:
```bash
flutter devices
```
*Kết quả sẽ hiển thị thiết bị máy ảo, ví dụ:*
```
sdk gphone64 x86 64 (mobile) • emulator-5554 • android-x86_64 • Android 14 (API 34) (emulator)
```

> **Mẹo hữu ích với công cụ ADB trên Windows:**
> Nếu lệnh `adb` báo không tìm thấy, đường dẫn mặc định nằm tại:
> `C:\Users\<Tên_User>\AppData\Local\Android\Sdk\platform-tools\adb.exe`
> Bạn có thể chạy lệnh kiểm tra:
> ```powershell
> & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
> ```

### Bước A3: Khởi chạy ứng dụng lên máy ảo
Chạy lệnh sau tại thư mục `fitness_tracker`:
```bash
flutter run -d emulator-5554 --dart-define-from-file=.env
```
*(Nếu chỉ có 1 máy ảo đang mở, bạn chỉ cần gõ `flutter run --dart-define-from-file=.env`)*.

### Bước A4: Các phím tắt tương tác hữu ích trong Terminal khi chạy Flutter
Khi ứng dụng đang chạy ở chế độ Debug trên máy ảo:
- **`r`**: **Hot Reload** ngay lập tức (cập nhật giao diện trong tích tắc mà không làm mất trạng thái dữ liệu màn hình).
- **`R`**: **Hot Restart** (khởi động lại toàn bộ state ứng dụng).
- **`h`**: Xem danh sách tất cả các lệnh tương tác.
- **`c`**: Xóa sạch màn hình console log.
- **`d`**: Tách kết nối debug (Detach) để ứng dụng tiếp tục chạy độc lập trên máy ảo.
- **`q`**: Thoát phiên chạy và đóng ứng dụng.

### Bước A5: Cài đặt trực tiếp file APK vào máy ảo (Không cần mã nguồn)
Nếu bạn đã xuất sẵn file APK (`app-x86_64-debug.apk` hoặc `app-debug.apk`), bạn có 2 cách cài đặt cực nhanh:
- **Cách 1 (Kéo & Thả)**: Nắm kéo file `.apk` từ thư mục trên máy tính rồi thả thẳng vào cửa sổ máy ảo Android, hệ thống sẽ tự động cài đặt trong 3 giây.
- **Cách 2 (Dùng lệnh ADB)**:
  ```powershell
  & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
  ```

### Bước A6: Hướng dẫn giả lập cảm biến trên máy ảo (Extended Controls)
Trên thanh công cụ cạnh máy ảo, nhấn biểu tượng **`...` (Extended Controls)**:
1. **Giả lập Bước chân & Cảm biến chuyển động**:
   - Chọn tab **Virtual Sensors** $\to$ **Device Pose** hoặc **Additional sensors**.
   - Điều chỉnh thanh trượt Accelerometer hoặc gửi sự kiện bước chân để kiểm tra tính năng đếm bước `StepCounterWidget`.
2. **Giả lập Camera để test Quét mã vạch & Chụp món ăn AI**:
   - Chọn tab **Camera** $\to$ Chọn **VirtualScene** cho Camera sau (Back camera).
   - Khi vào tính năng "Quét mã vạch" hoặc "Chụp món ăn", máy ảo sẽ hiện không gian phòng 3D ảo cho phép bạn di chuyển camera đến trước các đồ vật/mã vạch mẫu để quét trực tiếp.
3. **Giả lập Pin & Chế độ sạc**:
   - Chọn tab **Battery** để thử nghiệm ngưỡng tiết kiệm pin và trạng thái sạc.

---

## 📱 PHẦN B: HƯỚNG DẪN CHẠY TRÊN MÁY THẬT ANDROID (PHYSICAL DEVICE)

Chạy trên máy thật là cách tốt nhất để sử dụng **100% sức mạnh cảm biến phần cứng** (Cảm biến đếm bước chân chuyên dụng, Camera quét mã vạch thật, Bảo mật vân tay thật, Foreground Service chạy ngầm vĩnh viễn không bị hệ điều hành tắt, Ghim Widget màn hình chính và Đồng bộ Smartwatch).

### Bước B1: Bật chế độ Nhà phát triển & Gỡ lỗi USB trên điện thoại
1. Mở **Cài đặt (Settings)** trên điện thoại $\to$ Tìm mục **Thông tin điện thoại (About phone)**.
2. Tìm dòng **Số bản dựng (Build number)** (trên điện thoại Xiaomi là *Phiên bản OS / MIUI version*):
   - **Nhấn liên tục 7 lần** vào dòng này cho đến khi hiện thông báo: *"Bạn đã là nhà phát triển!"*.
3. Quay lại trang Cài đặt chính $\to$ Chọn **Cài đặt bổ sung (Additional Settings)** hoặc **Hệ thống (System)** $\to$ Vào **Tùy chọn nhà phát triển (Developer options)**.
4. Bật 2 tùy chọn quan trọng:
   - **Gỡ lỗi qua USB (USB debugging)**: Bật **ON**.
   - *(Dành cho máy Xiaomi, Redmi, POCO, Oppo, Realme, Vivo)*: Bật thêm **Cài đặt qua USB (Install via USB)** và **Gỡ lỗi USB (Cài đặt bảo mật)** để máy tính có quyền cài file APK qua cáp.

### Bước B2: Kết nối điện thoại với máy tính
1. Cắm cáp USB nối điện thoại với máy tính.
2. Trên màn hình điện thoại, vuốt thanh thông báo xuống và chọn kiểu kết nối USB là **Truyền tệp (File Transfer / MTP)** (không để ở chế độ "Chỉ sạc").
3. Màn hình điện thoại sẽ bật lên hộp thoại: **"Cho phép gỡ lỗi USB từ máy tính này?" (Allow USB debugging?)**:
   - Tích chọn ô: **"Luôn cho phép từ máy tính này" (Always allow from this computer)**.
   - Nhấn **Cho phép (Allow / OK)**.
4. Kiểm tra trên Terminal máy tính:
   ```bash
   flutter devices
   ```
   *Điện thoại thật của bạn sẽ xuất hiện trong danh sách (Ví dụ: `SM-S918B`, `Xiaomi 2201116SG`, `Pixel 8 Pro`,...)*.

> **💡 Tùy chọn: Kết nối không dây qua Wi-Fi (Wireless Debugging - Android 11+)**
> Không cần dùng cáp USB rườm rà:
> 1. Đảm bảo điện thoại và máy tính kết nối chung một mạng Wi-Fi.
> 2. Trên điện thoại: Vào *Tùy chọn nhà phát triển* $\to$ Bật **Gỡ lỗi không dây (Wireless debugging)** $\to$ Nhấn vào dòng đó $\to$ Chọn **Ghép nối thiết bị bằng mã ghép nối (Pair device with pairing code)**.
> 3. Trên máy tính: Chạy lệnh `adb pair <IP>:<PORT>` và nhập mã số 6 chữ số hiển thị trên điện thoại. Sau khi ghép nối, chạy `adb connect <IP>:<PORT_CHÍNH>` để kết nối hoàn tất.

### Bước B3: Chạy ứng dụng trực tiếp từ máy tính lên điện thoại
Chạy lệnh sau:
```bash
flutter run -d <ID_THIẾT_BỊ_THẬT> --dart-define-from-file=.env
```
*(Nếu chỉ có 1 thiết bị Android cắm vào, bạn chỉ cần gõ `flutter run --dart-define-from-file=.env`)*.

---

### Bước B4: Biên dịch file APK độc lập cài lên điện thoại (Không cần cắm cáp)
Bạn có thể tự xuất file APK tối ưu dung lượng siêu nhẹ bằng kỹ thuật tách kiến trúc CPU (`--split-per-abi`):

#### 1. Biên dịch bản Debug APK:
```bash
flutter build apk --debug --split-per-abi --dart-define-from-file=.env
```
📁 File xuất ra tại:
- `build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk` *(Dành cho 99% điện thoại Android hiện nay)*.
- `build/app/outputs/flutter-apk/app-armeabi-v7a-debug.apk` *(Dành cho các dòng máy Android đời cũ 32-bit)*.

#### 2. Biên dịch bản Release APK (Tối ưu hóa hiệu năng, dung lượng siêu nhẹ ~97MB):
```bash
flutter build apk --release --split-per-abi --dart-define-from-file=.env
```
📁 File xuất ra tại: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

#### 3. Cài đặt file APK lên điện thoại:
- Gửi file `.apk` vào điện thoại qua Zalo, Telegram, Google Drive, hoặc cắm cáp chép vào bộ nhớ trong máy.
- Mở ứng dụng **Quản lý tệp (File Manager)** trên điện thoại, tìm file APK và nhấn **Cài đặt**.
- Nếu có thông báo *"Cho phép cài đặt từ nguồn không xác định"*, bấm **Cài đặt / Vẫn cài đặt (Install anyway)**.

---

### Bước B5: Cấp các quyền quan trọng trên máy thật để trải nghiệm 100% tính năng

| Quyền hạn | Mục đích sử dụng trong ứng dụng | Cách kích hoạt |
| :--- | :--- | :--- |
| **Cảm biến Hoạt động thể chất** (`ACTIVITY_RECOGNITION`) | Đếm bước chân liên tục từ phần cứng điện thoại | App sẽ tự hỏi quyền khi mở lần đầu $\to$ Chọn **Cho phép (Allow)** |
| **Bỏ tối ưu hóa Pin** (`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`) | Giữ Foreground Service đếm bước không bị hệ điều hành tắt khi khoá màn hình | Vào tab **Hồ sơ** $\to$ Thẻ **Chạy nền & Pin** $\to$ Bấm **CẤP QUYỀN CHẠY NỀN** $\to$ Chọn **Không hạn chế (No restrictions)** |
| **Camera** | Quét mã vạch Open Food Facts và chụp ảnh món ăn AI | Bấm nút camera ở tính năng quét mã hoặc chụp thức ăn $\to$ Chọn **Cho phép khi dùng ứng dụng** |
| **Thông báo** (`POST_NOTIFICATIONS`) | Hiển thị thông báo bước chân chạy nền, đếm ngược nghỉ ngơi hiệp tập, nhắc uống nước | Chọn **Cho phép (Allow)** khi mở app |
| **Google Health Connect** | Đồng bộ Smartwatch (Samsung Galaxy Watch, Garmin, Mi Band,...) | Vào tab **Hồ sơ** $\to$ Thẻ **Kết nối Thiết bị đeo** $\to$ Tích chọn cấp quyền đọc Bước chân, Giấc ngủ, Nhịp tim, Calo |
| **Tiện ích Màn hình chính (Widget)** | Hiển thị số bước chân & calo ra ngoài màn hình chính | Ra màn hình chính điện thoại $\to$ **Nhấn giữ vào chỗ trống** $\to$ Chọn **Tiện ích (Widgets)** $\to$ Tìm **Fitness Tracker** $\to$ Kéo ra màn hình |

---

## 🧪 Kiểm thử tự động & Tiêu chuẩn chất lượng (Testing)

Dự án tuân thủ nghiêm ngặt nguyên tắc **Zero Regression** và kiểm soát chất lượng mã nguồn:

```bash
# 1. Kiểm tra phân tích tĩnh mã nguồn (0 issues found)
flutter analyze

# 2. Chạy toàn bộ 123+ bài kiểm thử tự động (Unit & Widget Tests)
flutter test
```

- **Kết quả kiểm thử**: 123/123 bài test vượt qua (100% Passed).
- **Phạm vi kiểm thử tự động**:
  - Động học giải phẫu & nhịp điệu bài tập (`anatomy_kinematic_painter_test.dart`, `exercise_pose_widget_test.dart`).
  - Bản đồ cơ bắp 2D tương tác (`muscle_anatomy_map_test.dart`).
  - Điểm số sức khỏe toàn diện (`health_score_test.dart`).
  - Bản tin sức khỏe hàng ngày AI (`daily_ai_briefing_test.dart`).
  - Ghi nhận dinh dưỡng, nước uống, streak ngày liên tục (`storage_service_test.dart`).
  - Đồng bộ thiết bị đeo qua Health Connect (`phase_4_features_test.dart`).

---

## 📁 Cấu trúc thư mục dự án

```
lib/
├── main.dart                  # Khởi tạo App, Database, Firebase, Health, Locale, Widget Sync
├── theme.dart                 # Cyber Dark Theme & Typographic tokens
├── database/
│   └── app_database.dart      # Quản lý SQLite database, migration & schema
├── repositories/              # Repository Pattern tách biệt nghiệp vụ
│   ├── auth_repository.dart
│   ├── chat_repository.dart
│   ├── nutrition_repository.dart
│   ├── step_repository.dart
│   ├── water_repository.dart
│   └── workout_repository.dart
├── models/                    # Data models: UserProfile, FoodLogEntry, DailyWaterLog, Badge...
├── screens/                   # Các màn hình chính (Dashboard, Workout, Food, Profile, ActiveWorkout...)
│   └── profile/               # Các module thẻ chức năng màn hình Hồ sơ
├── services/                  # HealthSyncService, OpenFoodFactsService, GeminiService, StorageService, UserMetricsService...
├── utils/                     # Formatters, AppHaptics, Helpers
└── widgets/                   # AnatomyKinematicPainter, ExercisePoseWidget, BiometricGate,
                               # BarcodeScannerSheet, DonutChart, DailyAiBriefing, WaterReminderWidget...
android/
└── app/src/main/kotlin/com/nhh031/fitness_tracker/
    └── FitnessAppWidgetProvider.kt # Android AppWidget Provider cập nhật bước chân ra Home Screen
```

---

## 👥 Tác giả & Đóng góp
- **Tác giả / Nhà phát triển**: Nguyễn Hữu Hoàng ([NHH-031](https://github.com/NHH-031))
- **Dự án**: [Fitness Tracker](https://github.com/NHH-031/fitness_app)
- **Bản quyền**: Phát hành theo giấy phép mã nguồn mở MIT License.
