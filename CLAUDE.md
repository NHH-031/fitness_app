# CLAUDE.md

Hướng dẫn cho Claude Code khi làm việc trong repo này. Ngôn ngữ trao đổi và comment trong code: **tiếng Việt** (identifier giữ tiếng Anh).

## Tổng quan

**Fitness Tracker** — ứng dụng theo dõi sức khỏe viết bằng **Flutter (Dart)** kèm lớp **native Android (Kotlin)**. Đây là đồ án môn *Android nâng cao*, nên phần native Android và cầu nối Flutter↔Android là trọng tâm khi phân tích/báo cáo.

- Package name: `fitness_tracker`, `applicationId = com.nhh031.fitness_tracker`, nhưng Kotlin `namespace`/package và tên platform channel vẫn là `com.example.fitness_tracker` (không phải lỗi, đừng "sửa đồng bộ" khi chưa kiểm tra).
- `minSdk = 26`, Java/Kotlin target 17, core library desugaring bật.
- Dart SDK `^3.11.5`. Không dùng package state management (Provider/Riverpod/Bloc); state đi qua `ValueNotifier` tĩnh trong `StorageService`.
- Lộ trình phân tích code phục vụ báo cáo: [docs/report-roadmap.md](docs/report-roadmap.md).

## Lệnh thường dùng

```bash
flutter pub get
flutter analyze                                   # CI yêu cầu 0 issues
flutter test                                      # ~123 test case, 17 file trong test/
flutter test test/storage_service_test.dart       # chạy 1 file
flutter run --dart-define-from-file=.env          # chạy debug, nạp GEMINI_API_KEY
flutter build apk --debug                         # CI cũng build bước này
flutter build apk --release --dart-define-from-file=.env
```

- `.env` bị gitignore; copy từ `.env.example` và điền `GEMINI_API_KEY`. Key cũng có thể nhập runtime (lưu qua `StorageService.saveGeminiApiKey`).
- CI: [.github/workflows/flutter_ci.yml](.github/workflows/flutter_ci.yml) chạy `analyze` → `test` → `build apk --debug` trên Java 17.
- Không có test native Kotlin; muốn kiểm tra phần native phải chạy trên emulator/thiết bị thật (`adb logcat`, `adb shell dumpsys`).
- Release build hiện ký bằng **debug key** (`android/app/build.gradle.kts`) — chưa sẵn sàng lên store.

## Cây thư mục (phần tự viết)

```
lib/
  main.dart              Khởi tạo Firebase → Notification → Locale → Auth → SQLite → Health → Gemini key
  theme.dart             AppTheme (dark theme)
  database/              app_database.dart — SQLite (sqflite; sqflite_common_ffi cho desktop/test)
  models/                Model thuần dữ liệu (UserProfile, FoodLogEntry, ChatMessage, ...)
  repositories/          Truy cập dữ liệu theo miền: step, water, workout, nutrition, chat, body_measurement, auth
  services/              Logic nghiệp vụ + tích hợp ngoài (Gemini, Firestore, Health Connect, Notification, ...)
  screens/               Màn hình; screens/profile/ gồm các card con của tab Profile
  widgets/               Widget tái sử dụng, chart (fl_chart), CustomPainter giải phẫu, bottom sheet
  utils/                 app_formatters, app_haptics
android/app/src/main/
  AndroidManifest.xml    Quyền, service, receiver, widget provider
  kotlin/.../            MainActivity, StepCounterService, BootReceiver, FitnessAppWidgetProvider
  res/layout|xml|drawable  Layout & metadata của App Widget
assets/i18n/             en.json, vi.json (tra bằng LocaleService.tr(key))
test/                    Unit + widget test (SQLite chạy in-memory khi FLUTTER_TEST)
docs/plans/              Kế hoạch tính năng
ios/ macos/ linux/ windows/ web/   Thư mục nền tảng do Flutter sinh ra, hầu như không chỉnh tay
```

## Kiến trúc & luồng chính

**Khởi động**: `main()` → `FitnessTrackerApp` → `AuthGate` (Firebase Auth stream; chế độ Khách qua `StorageService.isGuestMode`) → onboarding nếu chưa có hồ sơ → `BiometricGate` → `MainScreen` (4 tab: Dashboard, Workout, Food, Profile; chuyển tab qua `MainScreen.switchTab`).

**Phân tầng dữ liệu (local-first)**: UI → `StorageService` (facade tĩnh + các `*UpdateNotifier`) → `repositories/*` → `AppDatabase` (SQLite) / `SharedPreferences`. `FirestoreService` đồng bộ lên cloud khi đăng nhập Google (`syncOnLogin`). Lần mở đầu có migrate từ SharedPreferences sang SQLite (`_migrateFromSharedPreferences`). Dùng `StorageService.notifyXxxChanged()` sau khi ghi để UI rebuild; riêng step/water còn kích hoạt cập nhật Home Widget.

**Cầu nối Flutter ↔ Android** (đều dùng chung tiền tố `com.example.fitness_tracker`):

| Kênh | Hướng | Dùng cho |
|---|---|---|
| `MethodChannel …/service` | Dart → Kotlin | `startService`, `isIgnoringBatteryOptimizations`, `requestIgnoreBatteryOptimizations`, `updateWidget` |
| `EventChannel …/steps` | Kotlin → Dart | Stream số bước cứng từ `StepCounterService` (qua `sendBroadcast` + `BroadcastReceiver` trong `MainActivity`) |
| `MethodChannel …/speech` + `EventChannel …/speech_events` | Hai chiều | Nhận dạng giọng nói native (`SpeechRecognizerBridge`): `isAvailable`, `start {locale}`, `stop`, `cancel`; sự kiện status/result/error |
| `SharedPreferences` (`FlutterSharedPreferences`, key tiền tố `flutter.`) | Hai chiều | Kotlin và Dart cùng đọc/ghi `today_steps`, `step_baseline_*`, `step_reboot_offset`, `water_cups_today` |

**Đếm bước nền**: `StepCounterService` (foreground service, `foregroundServiceType="health"`, `START_STICKY`) đăng ký `TYPE_STEP_COUNTER` với batching 10 s; `BootReceiver` khởi động lại sau boot/cập nhật app; `FitnessAppWidgetProvider` đọc prefs để vẽ widget. Dart cần quyền `ACTIVITY_RECOGNITION` (xin ở `step_counter_widget.dart`).

**AI**: `GeminiService` (`google_generative_ai`, chỉ dùng một model `gemini-2.5-flash` (hằng số `_modelName` ở đầu `GeminiService`, gọi qua `_generate()` / `_generateStream()`, không có model dự phòng). Đã bỏ 3.8/3.7 vì hay trả 503/429 hoặc treo > 90 s với ảnh, còn 2.5-flash ổn định 3–7 s. Model Gemini bị Google tắt định kỳ — `gemini-2.0-flash` và `1.5-flash` đã ngừng, nên kiểm tra lại danh sách model khi AI báo lỗi). Thực phẩm: `OpenFoodFactsService` (barcode qua `mobile_scanner`). Giọng nói: `SpeechService` → `SpeechRecognizerBridge.kt` (không dùng plugin `speech_to_text`: plugin luôn lấy dịch vụ mặc định, trên Xiaomi là mibrain chỉ nghe tiếng Anh; bridge ưu tiên `GoogleRecognitionService` nếu có và đang bật).

## Cạm bẫy cần biết trước khi sửa

1. **Logic đếm bước bị lặp ở 3 nơi**: `StepCounterService.processNativeHardwareSteps` (Kotlin), `StepRepository.processHardwareSteps` và `StorageService.processHardwareSteps` (Dart). Cả ba ghi cùng key prefs → có thể race. Chỉ bản Dart có bộ lọc anti-jitter. Khi sửa thuật toán phải sửa đồng bộ hoặc hợp nhất.
2. **Kiểu dữ liệu prefs**: Dart lưu `int` thành `Long` trong `FlutterSharedPreferences`; Kotlin dùng `getSafeLong` để chịu cả Int/Long. Đừng đổi kiểu key đã có.
3. **Key bí mật**: `android/app/google-services.json` đang được commit; `serverClientId` Google Sign-In hard-code trong `auth_service.dart`. Không commit `.env` hoặc API key thật.
4. **`main()` nuốt lỗi** khi mở DB/Health (`try { … } catch (_) {}`) — lỗi khởi tạo DB sẽ không hiện ra.
5. **Widget Android hard-code** chuỗi tiếng Việt và mục tiêu `10.000` bước / `8` cốc trong `FitnessAppWidgetProvider.kt` và layout; không đi qua `LocaleService`.
6. **Test DB**: `AppDatabase` tự chuyển sang SQLite in-memory khi có biến môi trường `FLUTTER_TEST`; `StepRepository.disableAntiJitterForTesting` tắt lọc rung trong test.
7. `lottie` được khai báo trong `pubspec.yaml` nhưng chưa import ở đâu trong `lib/`.
8. File rất lớn (đọc theo đoạn, đừng đọc cả file): `storage_service.dart` (~2270 dòng), `anatomy_kinematic_painter.dart` (~2230), `muscle_anatomy_map_widget.dart` (~1830), `meal_category_card_widget.dart` (~1750), `active_workout_screen.dart` (~1590), `gemini_service.dart` (~1380).

## Quy ước

- Theo `flutter_lints` (`analysis_options.yaml`); giữ `flutter analyze` sạch.
- Chuỗi UI đi qua `LocaleService.tr('key')`; thêm key vào **cả** `assets/i18n/en.json` và `vi.json`.
- Màu/nền dùng `AppTheme`; component dùng chung ở `widgets/app_ui_components.dart`.
- Tên file `snake_case`; mỗi service/repository là singleton (`X.instance` hoặc factory) hoặc lớp static.
- Muốn thêm quyền Android: sửa `AndroidManifest.xml`, và nếu cần runtime permission thì xin bằng `permission_handler` ở Dart.
