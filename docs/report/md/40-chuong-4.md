# CHƯƠNG 4. CÀI ĐẶT VÀ KẾT QUẢ CHỨC NĂNG

Chương này trình bày chi tiết kết quả cài đặt thực tế các chức năng chính trên ứng dụng Fitness Tracker, phân tích các giải pháp kỹ thuật trên nền tảng Flutter và Android SDK nhằm hiện thực hóa từng giao diện người dùng. Nội dung chương tập trung vào bốn phân hệ nòng cốt: màn hình bảng điều khiển trung tâm (*Dashboard*), phân hệ quản lý luyện tập và mô hình cấu trúc cơ 2D, phân hệ theo dõi dinh dưỡng kết hợp trí tuệ nhân tạo và tra cứu mã vạch, cùng phân hệ quản lý hồ sơ cá nhân, bảo mật sinh trắc học và đa ngôn ngữ. Mỗi chức năng được làm rõ qua các quyết định thiết kế kiến trúc, công thức tính toán khoa học, đoạn mã nguồn thực thi then chốt và các minh chứng giao diện thực tế.

## 4.1. Màn hình Dashboard và tổng quan theo dõi sức khỏe

Màn hình bảng điều khiển trung tâm (*DashboardScreen*) đóng vai trò là giao diện chính xuất hiện đầu tiên khi người dùng mở ứng dụng, cung cấp cái nhìn tổng quan về trạng thái vận động, mức độ tiêu hao năng lượng, thói quen uống nước và các chỉ số thể chất trong ngày.

### 4.1.1. Kiến trúc hiển thị và cơ chế phản ứng dữ liệu của Dashboard

Màn hình `DashboardScreen` được xây dựng theo kiến trúc ghép nối mô-đun hóa, phân rã các khối thông tin thành các widget độc lập: thẻ chỉ số calo tổng hợp (`CalorieBalanceHeroWidget`), vòng tiến độ đếm bước (`StepCounterWidget`), biểu đồ năng lượng (`CaloriesChartWidget`), thẻ ghi nhận món ăn bằng AI (`AiFoodLoggingWidget`), thẻ theo dõi nước uống (`WaterReminderWidget`), thẻ điểm số sức khỏe (`HealthScoreWidget`) và bản tin gợi ý ngày mới (`DailyAiBriefingWidget`). Thẻ ghi nhận món ăn hiển thị tổng calo nạp so với mục tiêu calo cá nhân trong hồ sơ (ví dụ 2.152 kcal với hồ sơ thử nghiệm), cùng các lối tắt chụp ảnh món ăn, quét mã vạch, nhập bằng giọng nói và bàn phím.

Các nhãn và tiêu đề một dòng trên Dashboard và các thẻ khác dùng widget `MarqueeText` tự viết: khi chữ vừa ô, widget hiển thị như `Text` thông thường; khi chữ dài hơn ô (ví dụ tiêu đề "NHẮC NHỞ UỐNG NƯỚC" trên màn hình hẹp hoặc tên món dài), chữ tự cuộn ngang theo chu kỳ dừng 1,5 giây — cuộn hết — dừng 1 giây — trở về đầu, thay vì bị cắt thành dấu "…". Widget dùng `LayoutBuilder` và `TextPainter` để đo chiều rộng chữ so với ô, rồi cuộn bằng `ScrollController.animateTo()`.

Để đảm bảo giao diện luôn phản ánh dữ liệu mới nhất mà không gây lãng phí tài nguyên kết xuất đồ họa (*re-render*), ứng dụng không sử dụng phương pháp gọi lại toàn bộ hàm dựng (`setState` toàn cục) của màn hình cha. Thay vào đó, nhóm áp dụng mẫu thiết kế phản ứng trạng thái nhẹ (*reactive state pattern*) dựa trên `ValueNotifier` của Flutter Foundation. Lớp quản trị lưu trữ `StorageService` cung cấp các kênh phát tín hiệu chuyên biệt như `stepUpdateNotifier`, `waterUpdateNotifier` và `profileUpdateNotifier`. Khi có sự thay đổi từ tiến trình đếm bước nền hoặc khi người dùng hoàn thành một lượt uống nước, chỉ các widget con trực tiếp lắng nghe mới thực hiện cập nhật giao diện tương ứng. Khi đặt trong khung điều hướng bốn tab của `MainScreen`, trạng thái của `DashboardScreen` được bảo toàn nguyên vẹn nhờ cơ chế `IndexedStack`, hạn chế việc tái khởi tạo dữ liệu mỗi khi người dùng chuyển đổi tab.

### 4.1.2. Vòng tiến độ bước chân, tính toán lượng calo tiêu thụ và quãng đường di chuyển

Thành phần `StepCounterWidget` trực quan hóa tiến trình vận động hàng ngày thông qua vòng tròn tiến độ `CircularPercentIndicator`. Tỷ lệ lấp đầy của vòng tròn được xác định bằng công thức tỉ lệ giữa số bước chân tích lũy hiện tại và mục tiêu bước chân hàng ngày (mặc định là 10.000 bước).

Số bước chân hiển thị được thu nhận liên tục từ cảm biến phần cứng `TYPE_STEP_COUNTER` của thiết bị Android thông qua kênh sự kiện `EventChannel` (`com.example.fitness_tracker/steps`), kết hợp cùng dịch vụ chạy nền `StepCounterService` được khởi chạy qua kênh phương thức `MethodChannel` (`com.example.fitness_tracker/service`).

Dựa trên số bước chân thu nhận được và thông số thể trạng người dùng (chiều cao, cân nặng), lớp tính toán sinh trắc học `UserMetricsService` thực hiện chuyển đổi thành các đại lượng thể chất trực quan:
1. **Quãng đường di chuyển ($d$):** Được tính theo công thức độ dài sải chân trung bình nhân với tổng số bước:
$$d = \frac{\text{steps} \times \text{strideMeter}}{1000} \quad (\text{km})$$
Trong đó, chiều dài sải chân ($\text{strideMeter}$) được ước tính theo tỷ lệ nhân trắc học tiêu chuẩn là $41,5\%$ chiều cao người dùng:
$$\text{strideMeter} = \frac{\text{heightCm} \times 0,415}{100} \quad (\text{m})$$
2. **Lượng calo tiêu hao từ vận động bước chân:** Ước tính theo định mức tiêu hao chuyển hóa thể thao trung bình là $0,04\text{ kcal}$ trên mỗi bước chân:
$$\text{stepCalories} = \text{round}(\text{steps} \times 0,04) \quad (\text{kcal})$$
3. **Tổng lượng calo đốt cháy tính đến thời điểm hiện tại:** Nhóm cài đặt thuật toán cộng dồn năng lượng tiêu hao tích lũy từ thời điểm 0 giờ sáng cho tới thời điểm hiện tại trong ngày. Thuật toán phân bổ tỷ lệ trao đổi chất cơ bản (*BMR*) theo số phút đã trôi qua kể từ nửa đêm, sau đó cộng thêm calo từ các bài tập luyện kháng lực và calo tiêu hao từ số bước chân:

```dart
static int calculateRealtimeCaloriesBurned({
  required double personalBmr,
  required int workoutCalories,
  required int stepCalories,
  DateTime? now,
}) {
  final currentTime = now ?? DateTime.now();
  final minutesSinceMidnight = (currentTime.hour * 60) + currentTime.minute;
  final bmrBurnedUntilNow = (personalBmr / 1440.0) * minutesSinceMidnight;

  return (bmrBurnedUntilNow + workoutCalories + stepCalories).round();
}
```
(Nguồn: lib/services/user_metrics_service.dart:128-139)

### 4.1.3. Thẻ theo dõi lượng nước uống trong ngày và cập nhật mục tiêu

Thành phần `WaterReminderWidget` hỗ trợ người dùng theo dõi mức độ bù nước (*hydration*) trong suốt ngày dài. Giao diện thiết lập đơn vị chuẩn hóa với 1 cốc nước tương đương $250\text{ ml}$, và mục tiêu mặc định hàng ngày là 8 cốc (tương đương $2.000\text{ ml}$).

Giao diện cung cấp các nút tương tác nhanh cho phép tăng hoặc giảm số cốc nước đã nạp. Khi người dùng thao tác, `StorageService.addWaterCupForDate()` / `removeWaterCupForDate()` cập nhật số cốc trong SharedPreferences (khóa `water_cups_today`, `water_volume_ml_today`) và ghi lịch sử ngày vào danh sách `daily_water_history`, đồng thời kích hoạt `StorageService.waterUpdateNotifier` để đồng bộ số liệu sang các thành phần phụ thuộc. Vì số cốc nằm trong `FlutterSharedPreferences`, App Widget ở tầng Kotlin đọc trực tiếp được giá trị này. Bên cạnh đó, widget sử dụng `AnimationController` kết hợp hàm sin lượng giác trong `_WavePainter` để mô phỏng mực nước dâng động bên trong bình chứa, tạo trải nghiệm thị giác sinh động.

Để hỗ trợ duy trì thói quen lành mạnh, widget tích hợp hệ thống nhắc nhở định kỳ (mặc định mỗi 2 giờ) thông qua `NotificationService`. Widget cũng đăng ký lắng nghe sự kiện vòng đời ứng dụng thông qua `WidgetsBindingObserver`. Khi người dùng mở lại ứng dụng vào ngày mới (`AppLifecycleState.resumed`), hàm `_checkDayRolloverAndRefresh()` gọi `StorageService.checkAndResetWaterDaily()` để chốt sổ lượng nước của ngày cũ vào lịch sử và đặt lại bộ đếm về 0, tránh hiển thị sai lệch dữ liệu của ngày hôm trước. Thẻ còn có nút "Gửi ngay" và "Thử hẹn giờ (5s)" để kiểm tra kênh thông báo nhắc uống nước.

### 4.1.4. Biểu đồ năng lượng trong ngày và trong tuần sử dụng thư viện fl_chart

Thành phần `CaloriesChartWidget` ("Biểu đồ năng lượng") có ba chế độ xem: **24h Hôm nay**, **7 Ngày (Tuần)** và **Cân nặng**. Chế độ mặc định 24h vẽ hai đường tích lũy theo giờ — calo nạp vào và calo tiêu hao — với chấm tròn đánh dấu thời điểm hiện tại; phía trên là bốn ô tách nguồn năng lượng: Nạp vào, BMR cơ bản, Bước chân và Bài tập.

![Hình 4.1: Biểu đồ năng lượng 24 giờ trên Dashboard](img/chup-calories-chart-24h.png)

Chế độ 7 ngày dùng biểu đồ cột kép `WeeklyCalorieBarChart`, đặt cạnh nhau hai thanh đo lường trên mỗi mốc ngày:
- Cột màu xanh lơ thể hiện năng lượng nạp vào (*Calorie Intake*) từ các bữa ăn được ghi nhận trong nhật ký dinh dưỡng.
- Cột tiêu hao (*Calorie Burned*) gồm BMR cả ngày, calo từ các buổi tập và calo từ số bước chân; cột có màu xanh lá khi ngày đó thâm hụt năng lượng và màu cam khi thặng dư.

Cấu trúc biểu đồ sử dụng `BarChart` kết hợp mảng dữ liệu `BarChartGroupData` và `BarChartRodData`. Nhóm thiết lập thuộc tính `FlTitlesData` để hiển thị nhãn các thứ trong tuần (T2 đến CN) trên trục hoành (trục X) và hiển thị chỉ số calo rút gọn (đơn vị k-kcal) trên trục tung (trục Y). Cơ chế tương tác chạm `BarTouchData` hiển thị khung chú giải (*tooltip*) chi tiết khi người dùng nhấn vào từng cột ngày, giúp nắm bắt mức độ thâm hụt hoặc thặng dư năng lượng trong tuần một cách rõ ràng.

### 4.1.5. Điểm số sức khỏe tổng hợp (Health Score)

Nhằm cung cấp một thước đo định lượng cô đọng về lối sống của người dùng trong ngày, ứng dụng cài đặt thuật toán tính điểm sức khỏe `HealthScoreCalculator.evaluate()` trong `lib/widgets/health_score_widget.dart`. Thuật toán đánh giá sự cân bằng của 4 trụ cột thể chất trên thang điểm tối đa 100:

Bảng 4.1: Bảng phân bổ trọng số tính toán Điểm số sức khỏe (Health Score)

| Trụ cột đánh giá | Trọng số tối đa | Tiêu chuẩn và công thức tính toán |
|---|---|---|
| **Vận động bước chân** | 20 điểm | Tỉ lệ số bước so với mục tiêu: $\text{stepScore} = \text{clamp}((\text{steps} / \text{goalSteps}) \times 20, 0, 20)$. Đạt 10.000 bước được trọn 20 điểm. |
| **Rèn luyện bài tập** | 35 điểm | Dựa trên thời lượng và số buổi tập: đạt từ 35 phút tập luyện trở lên hoặc hoàn thành tối thiểu 1 buổi tập có ghi nhận hiệp tập được từ 15 đến 35 điểm. |
| **Dinh dưỡng & Năng lượng** | 35 điểm | Điểm cơ bản dựa trên độ bám sát mục tiêu calo (bám sát từ 70% đến 110% mục tiêu được 28 điểm; vượt mức trên 130% chỉ được 15 điểm) cộng thêm tối đa 7 điểm thưởng nếu nạp đủ mục tiêu chất đạm (*protein*). |
| **Bù nước & Kỷ luật** | 10 điểm | Lượng nước uống đóng góp tối đa 7 điểm ($\text{cups} / 8 \times 7$), duy trì chuỗi đăng nhập rèn luyện liên tục (*streak*) thưởng thêm 3 điểm. |

```dart
// Đánh giá 4 trụ cột lối sống trên thang điểm 100
double stepRatio = goalSteps > 0 ? (currentSteps / goalSteps) : 0.0;
int stepScore = (stepRatio * 20).round().clamp(0, 20);

int workoutScore = 0;
if (workoutMinutes > 0 || workoutCount > 0) {
  workoutScore = (workoutMinutes / 30.0 * 30).round();
  if (workoutCount > 0 && workoutScore < 15) workoutScore = 15;
  if (workoutMinutes >= 35) workoutScore = 35;
}
workoutScore = workoutScore.clamp(0, 35);

int habitScore = ((waterCups / 8.0 * 7).round().clamp(0, 7) + (streakDays > 0 ? 3 : 0)).clamp(0, 10);
int totalScore = (stepScore + workoutScore + nutritionScore + habitScore).clamp(0, 100);
```
(Nguồn: lib/widgets/health_score_widget.dart:76-124)

Điểm số tổng hợp được phân chia thành 5 bậc xếp hạng trạng thái kèm màu sắc trực quan: *Đỉnh cao* (90–100 điểm, xanh ngọc), *Rất tốt* (75–89 điểm, xanh lơ), *Tiến bộ* (60–74 điểm, vàng hổ phách), *Cần cố gắng* (40–59 điểm, cam), và *Cần cải thiện* (dưới 40 điểm, đỏ san hô). Cùng với điểm số, hệ thống tự động sinh lời khuyên động tương ứng (ví dụ: nhắc bổ sung nước nếu điểm bù nước thấp, hoặc khuyến khích đi bộ thêm nếu chưa đạt nửa mục tiêu bước).

Hình 4.2 là Dashboard trên thiết bị thử nghiệm: thẻ cân bằng calo (nạp 410 kcal, tiêu hao 947 kcal, thâm hụt 537 kcal), Điểm sức khỏe 36/100 kèm lời khuyên đi bộ thêm, và vòng tiến độ bước chân.

![Hình 4.2: Giao diện màn hình Dashboard tổng quan](img/chup-dashboard.png)
> CHỤP: Tab Dashboard (tab 1) / thẻ cân bằng calo, điểm sức khỏe và vòng tiến độ bước chân / mở ứng dụng ở màn hình chính.

## 4.2. Quản lý luyện tập và mô hình cấu trúc cơ 2D

Phân hệ luyện tập (`WorkoutScreen` và `ActiveWorkoutScreen`) được thiết kế nhằm hỗ trợ người dùng thực hiện các bài rèn luyện thể chất một cách bài bản, trực quan hóa các nhóm cơ vận động thông qua mô hình cấu trúc cơ 2D và ghi nhận chi tiết lịch sử từng hiệp tập.

### 4.2.1. Phân loại bài tập theo nhóm cơ chính và trang thiết bị

Hệ thống quản lý danh mục bài tập đa dạng, được phân chia theo 6 nhóm cơ chính của cơ thể:
- **Ngực (*Chest*):** Các bài tập đẩy tạo độ dày và khung ngực như Hít đất (*Push-ups*), Đẩy ngực tạ đơn (*Dumbbell Bench Press*).
- **Lưng (*Back*):** Các bài tập kéo phát triển cơ lưng xô và độ dày lưng như Hít xà đơn (*Pull-ups*), Kéo tạ lưng xô (*Dumbbell Row*).
- **Chân (*Legs*):** Các bài tập phát triển đùi trước, đùi sau và bắp chân như Gập gối (*Squat*), Chùng chân (*Lunges*), Deadlift tạ đơn (*RDL*).
- **Vai (*Shoulders*):** Các bài tập phát triển cơ vai trước, vai giữa và vai sau như Đẩy vai qua đầu (*Overhead Press*), Dang tạ ngang (*Lateral Raises*).
- **Tay (*Arms*):** Tập trung vào tay trước (*Biceps*) và tay sau (*Triceps*) như Cuốn tạ tay trước (*Dumbbell Bicep Curl*).
- **Bụng/Lõi (*Core*):** Tăng cường sự ổn định cột sống và cơ bụng như Plank, Gập bụng (*Crunches*), Leo núi (*Mountain Climbers*).

Danh mục hiện có 17 bài tập. Ứng dụng cung cấp thanh lọc thiết bị (`ExerciseEquipmentFilter`) với 3 chế độ: *Tất cả* (17), *Tự do (Bodyweight)* (9 bài) dành cho người tập tại nhà không có dụng cụ, và *Tạ đơn (Dumbbell)* (8 bài) dành cho người có trang bị tạ tự do. Bên cạnh đó, người dùng có thể chuyển đổi giao diện hình thể giữa Nam và Nữ để hệ thống điều chỉnh tỷ lệ đồ họa và đề xuất bài tập phù hợp với giới tính.

Bảng 4.2: Cấu trúc thông tin bài tập và nhóm cơ mục tiêu trong hệ thống

| Tên bài tập | Nhóm cơ chính | Phân loại thiết bị | Chế độ mặc định | Mức năng lượng ước tính |
|---|---|---|---|---|
| **Hít đất** (*Push-ups*) | Cơ Ngực (*Chest*) | Bodyweight | 3 hiệp × 15 reps | 120 kcal / bài |
| **Đẩy ngực tạ đơn** | Cơ Ngực (*Chest*) | Tạ đơn (*Dumbbell*) | 3 hiệp × 12 reps (10 kg) | 115 kcal / bài |
| **Hít xà đơn** (*Pull-ups*) | Cơ Lưng (*Back*) | Bodyweight | 3 hiệp × 8 reps | 110 kcal / bài |
| **Kéo tạ lưng xô** | Cơ Lưng (*Back*) | Tạ đơn (*Dumbbell*) | 3 hiệp × 12 reps (10 kg) | 110 kcal / bài |
| **Squat ôm tạ Goblet** | Đùi & Mông (*Legs*) | Tạ đơn (*Dumbbell*) | 3 hiệp × 12 reps (12 kg) | 130 kcal / bài |
| **Đẩy vai qua đầu** | Cơ Vai (*Shoulders*) | Tạ đơn (*Dumbbell*) | 3 hiệp × 10 reps (8 kg) | 105 kcal / bài |
| **Plank siết cơ bụng** | Cơ Bụng (*Core*) | Bodyweight | Đếm giờ 60 giây | 35 kcal / hiệp |

### 4.2.2. Mô hình cấu trúc cơ tương tác bằng CustomPainter

Điểm nhấn kỹ thuật nổi bật trong phân hệ luyện tập là bản đồ nhóm cơ tương tác (`MuscleAnatomyMapWidget`). Thay vì nạp các tệp hình ảnh tĩnh hoặc hoạt cảnh Lottie có dung lượng lớn và khó tùy biến màu sắc, nhóm chọn giải pháp vẽ trực tiếp mô hình cơ thể người 2D lên Canvas bằng `CustomPainter`.

Giải pháp này bao gồm hai lớp vẽ vector:
1. `_AnatomySilhouettePainter`: Vẽ đường viền bóng hình cơ thể người ở cả hai góc nhìn mặt trước (*Anterior*) và mặt sau (*Posterior*), hỗ trợ hình dáng cơ thể riêng cho Nam giới và Nữ giới. Các khối cơ được định vị bằng hệ tọa độ chuẩn hóa tương đối `Offset(x, y)` trên khung vẽ kích thước $140 \times 280\text{ dp}$, giúp tỷ lệ cơ thể luôn giữ nguyên hình dạng chuẩn trên mọi độ phân giải màn hình điện thoại Android.
2. `_AnatomyLeaderLinesPainter`: Khi một nhóm cơ được kích hoạt hoặc người dùng chạm chọn trên màn hình, hệ thống vẽ các đường chỉ dẫn vector nối từ điểm neo trên khối cơ tới nhãn tên nhóm cơ ở hai cột bên cạnh. Khối cơ đang chọn được tô màu xanh neon hoặc cam phát sáng nhằm làm nổi bật vùng vận động, đồng thời bên dưới sẽ hiển thị danh sách các bài tập tác động trực tiếp lên nhóm cơ đó.

```dart
class MuscleGroupInfo {
  final String id;
  final String nameVi;
  final String nameEn;
  final String category; // 'chest', 'back', 'legs', 'arms', 'shoulders', 'core'
  final bool isFront;
  final MuscleSide side; // left or right callout column
  final Offset relativePos; // (x, y) normalized anchor on 140x280 body canvas
  final List<String> primaryExercises;
  final String description;

  const MuscleGroupInfo({
    required this.id, required this.nameVi, required this.nameEn,
    required this.category, required this.isFront, required this.side,
    required this.relativePos, required this.primaryExercises,
    required this.description,
  });
}
```
(Nguồn: lib/widgets/muscle_anatomy_map_widget.dart:9-31)

![Hình 4.3: Giao diện danh mục bài tập và mô hình cấu trúc cơ](img/chup-workout-anatomy.png)
> CHỤP: Tab Luyện tập (tab 2) / hiển thị mô hình cấu trúc cơ với các nhóm cơ được tô màu và danh sách bài tập / chuyển sang tab Workout.

### 4.2.3. Quản lý buổi tập, bấm giờ nghỉ ngơi và lưu lịch sử hiệp tập vào SQLite

Khi người dùng chọn một bài tập cụ thể, ứng dụng điều hướng sang màn hình thực hiện bài tập trực tiếp (`ActiveWorkoutScreen`). Màn hình hỗ trợ hai phương thức quản lý buổi tập linh hoạt:
- **Chế độ đếm thời gian (*Timer Mode*):** Dành cho các bài tập giữ tĩnh hoặc cardio cường độ cao (như Plank, Burpees, Mountain Climbers — mặc định 60 giây). Đồng hồ đếm ngược được kích hoạt kèm hoạt cảnh hướng dẫn tư thế động học.
- **Chế độ số hiệp và lần lặp (*Reps & Sets Mode*):** Dành cho các bài tập kháng lực với tạ. Người dùng có thể tùy chỉnh số hiệp mục tiêu (mặc định 3 hiệp), số lần lặp mục tiêu trên mỗi hiệp (ví dụ 10–12 reps) và mức tạ đang tập (kg).

Sau khi hoàn thành một hiệp tập, hệ thống tự động kích hoạt đồng hồ đếm ngược thời gian nghỉ ngơi (*Rest Timer*, mặc định 60 giây). Bộ đếm này phát cảnh báo rung xúc giác nhẹ qua `AppHaptics` khi hết giờ, đồng thời gửi thông báo trạng thái qua `NotificationService` giúp người tập không bỏ lỡ hiệp tiếp theo ngay cả khi chuyển sang ứng dụng khác.

Ngoài ra, màn hình tích hợp nguyên lý theo dõi tăng tiến tải trọng (*Progressive Overload Tracking*). Ứng dụng truy vấn buổi tập gần nhất của cùng bài từ bảng `workout_logs` và hiển thị thẻ gợi ý, ví dụ "Buổi trước: 10.0kg × 10 reps → Hôm nay: +1 rep hoặc +1–2.5kg"; nếu mức tạ hoặc số reps của buổi hiện tại vượt thành tích cũ, hệ thống đánh dấu kỷ lục cá nhân mới (*Personal Record - PR*). Khi kết thúc toàn bộ buổi tập, phương thức `StorageService.logCompletedWorkout()` lưu trữ toàn bộ dữ liệu (tên bài, thời lượng, calo, số hiệp, mức tạ) vào bảng `workout_logs` của cơ sở dữ liệu SQLite:

```dart
StorageService.logCompletedWorkout(
  durationMinutes: durationMinutes,
  title: _currentTitle,
  calories: _currentCalories,
  sets: _isRepsMode ? loggedSets : null,
  reps: _isRepsMode ? loggedReps : null,
  weightKg: _hasWeight ? _weightKg : null,
  equipment: _equipment,
);
AppHaptics.success();
AchievementService.checkBadges();
```
(Nguồn: lib/screens/active_workout_screen.dart:420-430)

Thời lượng được lưu theo đơn vị phút. Số reps người dùng đếm được ở mỗi hiệp được ghi lại trong danh sách `_repsPerSet`; khi kết thúc, ứng dụng lưu số hiệp đã tập và số reps trung bình mỗi hiệp (ví dụ tập 1 hiệp, đếm 3 reps thì nhật ký ghi 1 × 3 dù mục tiêu là 3 × 10). Nếu người dùng không dùng bộ đếm, ứng dụng ghi theo mục tiêu đã cấu hình. Khi hoàn thành, hộp thoại tổng kết hiển thị calo tiêu hao, thời gian tập, hiệp × reps và mức tạ.

![Hình 4.4: Giao diện chi tiết bài tập và ghi nhận hiệp tập](img/chup-workout-detail.png)
> CHỤP: Màn hình thực hiện bài tập / hoạt cảnh động học và bộ đếm rep / chọn một bài tập từ danh sách.

![Hình 4.5: Gợi ý tăng tiến tải trọng dựa trên buổi tập trước](img/chup-progressive-overload.png)

![Hình 4.6: Hộp thoại tổng kết khi hoàn thành bài tập](img/chup-workout-complete.png)

**AI Huấn luyện viên cá nhân.** Ở tab Hoạt động, người dùng chọn thời gian rảnh (10–30 phút), mục tiêu (đốt mỡ toàn thân, bụng & core, thân trên, chân & mông, dẻo dai, cardio hoặc tự nhập) và dụng cụ (tự do / tạ đơn). Gemini sinh một giáo án gồm danh sách động tác kèm số hiệp, số reps hoặc thời gian và lời dặn kỹ thuật; người dùng có thể bắt đầu tập ngay hoặc tạo lại.

![Hình 4.7: Giáo án do AI Huấn luyện viên tạo theo mục tiêu Bụng & Core](img/chup-ai-workout-generator.png)

## 4.3. Theo dõi dinh dưỡng và tích hợp trí tuệ nhân tạo Gemini

Theo dõi dinh dưỡng là phân hệ quan trọng giúp người dùng cân bằng năng lượng nạp vào với năng lượng tiêu hao. Ứng dụng kết hợp giữa các công thức sinh trắc học chuẩn y khoa, mô hình thị giác trí tuệ nhân tạo của Google để nhận diện bữa ăn qua ảnh, cùng cơ chế tra cứu mã vạch hàng hóa thương mại.

### 4.3.1. Tính toán nhu cầu năng lượng theo công thức BMR (Mifflin-St Jeor) và TDEE

Để đưa ra mục tiêu dinh dưỡng cá nhân hóa, ứng dụng cài đặt các công thức sinh trắc học trong `UserMetricsService`:
1. **Tỷ lệ trao đổi chất cơ bản (BMR):** Ứng dụng áp dụng phương trình Mifflin-St Jeor, công thức được đánh giá có độ chính xác cao trong các nghiên cứu dinh dưỡng lâm sàng hiện đại:
   - Nam giới:
$$\text{BMR} = 10 \times \text{weight (kg)} + 6,25 \times \text{height (cm)} - 5 \times \text{age} + 5$$
   - Nữ giới:
$$\text{BMR} = 10 \times \text{weight (kg)} + 6,25 \times \text{height (cm)} - 5 \times \text{age} - 161$$
2. **Tổng tiêu hao năng lượng hàng ngày (TDEE):** Được tính bằng BMR nhân với hệ số mức độ hoạt động thể chất (*Physical Activity Level - PAL*), người dùng chọn một trong bốn mức khi thiết lập hồ sơ: 1,2 (ít vận động), 1,375 (nhẹ nhàng), 1,55 (vừa phải) và 1,725 (năng động) — tương ứng thang từ 1,2 đến 1,9 (vận động viên cường độ cao):
$$\text{TDEE} = \text{BMR} \times \text{activityMultiplier}$$
3. **Mục tiêu năng lượng theo định hướng thể hình:**
   - Giảm mỡ (*Cutting*): thâm hụt khoảng $450\text{ kcal}$ so với TDEE nhằm kích thích đốt mỡ tự nhiên mà không làm mất cơ bắp.
   - Tăng cơ (*Bulking*): thặng dư khoảng $350\text{ kcal}$ so với TDEE để hỗ trợ quá trình tổng hợp cơ.
   - Sức bền (*Endurance*): thặng dư nhẹ $150\text{ kcal}$ bù đắp lượng glycogen tiêu hao.
   - Duy trì cân bằng (*Balanced*): nạp đúng mức năng lượng TDEE.
4. **Phân bổ tỷ lệ các chất dinh dưỡng đa lượng (*Macros*):**
   - Đạm (*Protein*): phân bổ từ 1,6 đến 2,2 g trên mỗi kg thể trọng tùy mục tiêu (1g protein = 4 kcal).
   - Chất béo (*Fat*): phân bổ chiếm 22% đến 25% tổng năng lượng mục tiêu (1g fat = 9 kcal).
   - Tinh bột (*Carbohydrates*): nhận phần năng lượng còn lại chia cho 4 (1g carbs = 4 kcal).

Các mục tiêu tính toán này được biểu diễn trực quan trên màn hình dinh dưỡng (`FoodScreen`) bằng biểu đồ tròn rỗng tâm `MacroDonutChartWidget`, so sánh giữa lượng đạm, đường, béo mục tiêu và lượng thực tế đã nạp trong các bữa ăn.

![Hình 4.8: Giao diện theo dõi dinh dưỡng và các bữa ăn trong ngày](img/chup-nutrition-tab.png)
> CHỤP: Tab Dinh dưỡng (tab 3) / hiển thị tổng lượng calo trong ngày và các bữa ăn sáng, trưa, tối / chuyển sang tab Nutrition.

### 4.3.2. Nhận diện món ăn tự động qua ảnh bằng Google Gemini Vision

Nhằm đơn giản hóa thao tác ghi chép món ăn, ứng dụng tích hợp mô hình thị giác của Google thông qua gói thư viện chính thức `google_generative_ai`. Người dùng có thể chụp ảnh bằng camera hoặc chọn ảnh từ thư viện (`image_picker`). Chức năng nhận diện đĩa thức ăn qua hình ảnh trong `GeminiService.analyzeFoodImage()` hoạt động theo quy trình:

1. **Xác định định dạng MIME từ mảng byte:** Trước khi gửi ảnh lên máy chủ, ứng dụng không phụ thuộc vào đuôi mở rộng của tệp tin mà đọc trực tiếp các byte đầu (*byte signature*) của mảng `Uint8List` (`0x89 0x50 0x4E 0x47` cho PNG, `RIFF...WEBP` cho WebP, còn lại mặc định là `image/jpeg`). Điều này giúp đối tượng `DataPart` luôn được gán đúng chuẩn MIME type.
2. **Thiết kế câu chỉ dẫn có cấu trúc (Structured Prompt):** Nhóm thiết lập prompt yêu cầu mô hình đóng vai trò chuyên gia dinh dưỡng, ước lượng kích thước khẩu phần hợp lý và bắt buộc chỉ trả về duy nhất chuỗi đối tượng JSON khớp với lược đồ: `{"name": "...", "calories": int, "protein": int, "carbs": int, "fat": int}`.
3. **Lựa chọn mô hình và giới hạn thời gian:** Toàn bộ chức năng AI dùng một mô hình duy nhất `gemini-2.5-flash`, khai báo bằng hằng số `_modelName` và được gọi qua hàm `_generate()` (bản truyền luồng `_generateStream()` dùng cho chat). Nhóm chọn mô hình này vì khi đo thực tế, nó trả kết quả ổn định trong 3–7 giây với cả ảnh và văn bản, trong khi các mô hình bản 3.x thường quá tải (`503`, `429`) hoặc phản hồi rất chậm. Mỗi lời gọi được giới hạn thời gian (30 giây với phân tích ảnh, 12 giây với tính dinh dưỡng theo định lượng); khi quá thời gian hoặc lỗi mạng, ứng dụng chuyển sang nhập tay hoặc dùng dữ liệu tính sẵn.
4. **Phân tích và làm sạch JSON:** Kết quả văn bản trả về được hàm `parseFoodJson()` lọc bỏ các ký tự bọc markdown (` ```json `), cắt bỏ khoảng trắng và chuyển đổi thành đối tượng `FoodInfo`.

```dart
static const String _modelName = 'gemini-2.5-flash';

static GenerativeModel _createModel({Content? systemInstruction}) {
  return GenerativeModel(
    model: _modelName,
    apiKey: apiKey,
    systemInstruction: systemInstruction,
  );
}

static Future<GenerateContentResponse> _generate(
  List<Content> contents, {
  Content? systemInstruction,
}) {
  return _createModel(systemInstruction: systemInstruction).generateContent(contents);
}
```
(Nguồn: lib/services/gemini_service.dart:44-83, rút gọn)

Kết quả thử nghiệm (18/10/2026, ảnh phở bò 800×600): trên thiết bị, ứng dụng nhận diện "Phở Bò" — 780 kcal, đạm 45 g, tinh bột 60 g, béo 40 g (Hình 4.9); người dùng có thể chỉnh các trị số trước khi lưu. Đo riêng bằng API, `gemini-2.5-flash` nhận diện đúng 6/6 lần với ảnh (3,3–7,5 giây) và trả lời 3/3 yêu cầu văn bản trong 5,6–6,3 giây. Ngoài ảnh, người dùng có thể nhập mô tả bằng văn bản (ví dụ gõ không dấu "2 qua trung op la va 1 banh mi" → "2 trứng ốp la và 1 bánh mì", 680 kcal, đạm 27 g, tinh bột 81 g, béo 29 g), kết quả được lưu vào bảng `food_entries`. Các prompt đều yêu cầu mô hình trả tên món, tên giáo án, hướng dẫn và lời khuyên theo ngôn ngữ giao diện hiện tại (`LocaleService.isVietnamese`), trong khi khóa JSON vẫn giữ tiếng Anh để phân tích ổn định.

![Hình 4.9: Chức năng nhận diện món ăn bằng AI Gemini qua ảnh](img/chup-ai-food-scanner.png)
> CHỤP: Màn hình xác nhận món ăn / ảnh món ăn kèm kết quả ước tính dinh dưỡng từ Gemini / chọn ảnh trong tab Dinh dưỡng.

### 4.3.3. Tra cứu thông tin thực phẩm qua mã vạch với Open Food Facts và cơ chế dự phòng ngoại tuyến

Đối với các thực phẩm đóng gói sẵn có nhãn mác thương mại (sữa chua, bánh kẹo, đồ hộp), ứng dụng cung cấp tính năng quét mã vạch qua camera thông qua thư viện `mobile_scanner` kết hợp dịch vụ `OpenFoodFactsService`.

Quy trình tra cứu mã vạch:
- Khi camera quét được chuỗi mã vạch chuẩn EAN-13 hoặc UPC, chuỗi số được gửi tới REST API v2 của Open Food Facts thông qua yêu cầu HTTP GET: `https://world.openfoodfacts.org/api/v2/product/{barcode}.json`.
- Yêu cầu được gắn tiêu đề định danh `User-Agent: FitnessTrackerApp - Android - Version 1.0.0` theo quy định của tổ chức Open Food Facts, kèm thời gian chờ tối đa 8 giây để tránh nghẽn luồng xử lý.
- Dữ liệu JSON phản hồi được bóc tách: hệ thống ưu tiên lấy tên sản phẩm tiếng Việt (`product_name_vi`), sau đó tới tên tiếng Anh (`product_name_en`). Về chỉ số năng lượng, hệ thống đọc trường `energy-kcal_100g`; nếu trường này bị thiếu, hệ thống tự động quy đổi từ chỉ số kilojoule `energy_100g` sang kilocalorie theo công thức $1\text{ kcal} \approx 4,184\text{ kJ}$. Các chỉ số chất đạm, tinh bột, chất béo cũng được trích xuất theo định mức 100g và hỗ trợ nhân hệ số khẩu phần ăn.

Nhằm bảo đảm tính sẵn sàng của ứng dụng khi thiết bị hoạt động ở khu vực mất sóng hoặc không có kết nối internet, nhóm xây dựng bảng giá trị dinh dưỡng tính sẵn gồm 23 món ăn Việt Nam và thể hình phổ biến (như cơm trắng, ức gà luộc, trứng luộc, phở bò, bún chả, chuối, whey protein) được lưu trữ sẵn trong bộ nhớ RAM (`_nutritionCache`). Khi người dùng nhập tên món ăn, hệ thống thực hiện thuật toán tìm kiếm gần đúng (*fuzzy matching*) trên bảng dữ liệu này trước; nếu tìm thấy kết quả phù hợp, dữ liệu dinh dưỡng được phản hồi ngay lập tức mà không cần phụ thuộc vào kết nối mạng hay khóa API bên ngoài.

Bảng 4.3: So sánh cơ chế nhận diện dinh dưỡng qua AI Gemini Vision và quét mã vạch Open Food Facts

| Tiêu chí so sánh | Nhận diện món ăn AI Gemini Vision | Quét mã vạch Open Food Facts |
|---|---|---|
| **Đối tượng áp dụng** | Đĩa thức ăn nấu tại nhà, món ăn nhà hàng, đĩa cơm văn phòng, món ăn phức hợp. | Thực phẩm đóng gói thương mại, đồ hộp, bánh kẹo, sữa, thực phẩm bổ sung. |
| **Giao thức kết nối** | Google Generative AI SDK (HTTPS), mô hình `gemini-2.5-flash`. | REST API v2 (HTTP GET) tới máy chủ Open Food Facts, định dạng JSON. |
| **Dữ liệu đầu vào** | Mảng byte ảnh chụp từ camera hoặc thư viện (`Uint8List`). | Chuỗi mã vạch số (EAN-13, EAN-8, UPC) qua `mobile_scanner`. |
| **Thời gian xử lý** | Thường 3–7 giây, phụ thuộc chất lượng mạng; giới hạn tối đa 30 giây. | Dưới 1 giây với sản phẩm đã có trong cơ sở dữ liệu quốc tế (ví dụ Nutella `3017620422003`). |
| **Cơ chế dự phòng** | Nếu lỗi hoặc quá thời gian, ứng dụng mở biểu mẫu nhập tay kèm ảnh; bảng 23 món tính sẵn cho tra cứu văn bản. | Cho phép người dùng chỉnh sửa thủ công các chỉ số nếu sản phẩm chưa có trên máy chủ hoặc thiếu trường dữ liệu. |

Hình 4.10 là kết quả quét mã vạch Nutella (`3017620422003`) trên thiết bị thử nghiệm: ứng dụng hiển thị ảnh sản phẩm, nhà sản xuất Ferrero, 539 kcal, đạm 6 g, carbs 58 g, béo 31 g trên 100 g, cùng bộ chọn khẩu phần 0.5×–2.0× và bữa ăn.

![Hình 4.10: Quét mã vạch thực phẩm qua Open Food Facts](img/chup-barcode-scanner.png)
> CHỤP: Bảng quét mã vạch BarcodeScannerSheet / thông tin sản phẩm và dinh dưỡng sau khi quét / bấm nút Quét mã vạch trên Dashboard.

**Chuyên gia dinh dưỡng AI.** Nút "Chuyên gia AI" ở tab Dinh dưỡng mở `AiNutritionistChatDialog`, nơi người dùng hỏi đáp với Gemini (ví dụ "Nên ăn gì sau buổi tập?"). Ngữ cảnh gửi kèm gồm hồ sơ, mục tiêu calo và nhật ký trong ngày, nên câu trả lời được cá nhân hóa (nhắc lượng nước đã uống, cân nặng mục tiêu...). Câu trả lời được truyền luồng và lưu vào lịch sử tư vấn, có tìm kiếm và lọc theo câu hỏi / lời khuyên. Định dạng Markdown trong câu trả lời (chữ đậm `**…**`, chữ nghiêng `*…*`, gạch đầu dòng, tiêu đề `#`) được hàm `chatMarkdownSpan()` (`lib/utils/chat_markdown.dart`) chuyển thành `TextSpan` có định dạng tương ứng, nên người dùng không thấy ký hiệu thô. Ở chế độ Khách, màn hình lịch sử ghi rõ "Lưu trên thiết bị"; khi đã đăng nhập mới hiển thị nhãn đồng bộ Cloud.

![Hình 4.11: Hội thoại với Chuyên gia dinh dưỡng AI](img/chup-ai-chat.png)

![Hình 4.12: Lịch sử tư vấn AI](img/chup-ai-chat-history.png)

## 4.4. Quản lý hồ sơ cá nhân, đồng bộ dữ liệu và đa ngôn ngữ

Phân hệ quản lý hồ sơ cá nhân (`ProfileScreen`) cung cấp các thiết lập quản trị thể chất, theo dõi thành tích rèn luyện, bảo vệ quyền riêng tư qua xác thực sinh trắc học và tùy biến ngôn ngữ hiển thị.

### 4.4.1. Quản lý thông tin thể chất và tính chỉ số BMI

Trong màn hình hồ sơ, người dùng có thể cập nhật các thông số nhân trắc học cơ bản bao gồm chiều cao, cân nặng, độ tuổi, giới tính và cấp độ hoạt động thể chất. Các thông số này được lưu dưới dạng chuỗi JSON trong SharedPreferences (khóa `user_profile`) và đóng vai trò làm tham số đầu vào cho mọi thuật toán tính toán năng lượng trong ứng dụng. Với hồ sơ thử nghiệm (nam, 24 tuổi, 175 cm, 70 kg, vận động vừa phải, mục tiêu siết mỡ), ứng dụng tính được BMI 22,9; BMR 1.679 kcal; TDEE 2.602 kcal (hệ số 1,55) và mục tiêu 2.152 kcal/ngày — khớp với công thức ở mục 4.3.1.

Ứng dụng tự động tính toán Chỉ số khối cơ thể (*Body Mass Index - BMI*) theo công thức:
$$\text{BMI} = \frac{\text{weight (kg)}}{(\text{height (m)})^2}$$
Dựa trên chỉ số BMI tính được, hệ thống phân loại tình trạng thể chất của người dùng theo khuyến nghị y tế thành 4 cấp độ: *Thiếu cân* ($\text{BMI} < 18,5$), *Bình thường* ($18,5 \le \text{BMI} < 24,9$), *Thừa cân* ($24,9 \le \text{BMI} < 29,9$), và *Béo phì* ($\text{BMI} \ge 29,9$).

Ngoài ra, ứng dụng còn tích hợp công thức đo chu vi của Hải quân Hoa Kỳ (*US Navy Circumference Method*) để ước tính tỷ lệ mỡ cơ thể (*Body Fat Percent*) từ số đo vòng cổ, vòng eo, vòng hông và chiều cao. Dữ liệu này được đối chiếu với thang phân loại của Hội đồng Thể dục Hoa Kỳ (*ACE*) để giúp người dùng có cái nhìn chuẩn xác hơn về cấu trúc cơ thể so với chỉ số BMI đơn thuần. Ví dụ trên thiết bị thử nghiệm: vòng eo 82 cm, vòng cổ 38 cm, chiều cao 175 cm cho kết quả 14,5 % (nhóm "Săn chắc thể hình"); bản ghi được lưu vào bảng `body_measurements`.

![Hình 4.13: Màn hình số đo cơ thể và tỷ lệ mỡ theo phương pháp US Navy](img/chup-body-measurements.png)

### 4.4.2. Hệ thống huy hiệu thành tích (Achievement System)

Nhằm khuyến khích người dùng duy trì kỷ luật rèn luyện lâu dài, ứng dụng xây dựng hệ thống game hóa (*gamification*) với 9 huy hiệu thành tích chính thức được quản lý qua `AchievementService`:

Bảng 4.4: Danh mục hệ thống huy hiệu thành tích (Achievement Badges) trong ứng dụng

| Mã huy hiệu | Tên huy hiệu (Vi / En) | Danh mục | Điều kiện mở khóa thành tích |
|---|---|---|---|
| `streak_3` | Khởi đầu vàng (*Golden Start*) | Chuỗi ngày | Đăng nhập và duy trì chuỗi rèn luyện 3 ngày liên tục. |
| `streak_7` | Chiến thần kiên trì (*Persistence Warrior*) | Chuỗi ngày | Hoàn thành chuỗi kỷ luật 7 ngày liên tiếp không gián đoạn. |
| `streak_14` | Kỷ luật bất diệt (*Unstoppable Momentum*) | Chuỗi ngày | Chinh phục cột mốc rèn luyện 14 ngày liên tiếp. |
| `water_master` | Bậc thầy Hydration (*Hydration Master*) | Nước uống | Uống đủ 8 cốc nước (2.000ml) trong ít nhất 3 ngày. |
| `water_8_today` | Thủy thần 8 cốc (*Hydration Hero*) | Nước uống | Hoàn thành đủ 8 cốc nước trong một ngày duy nhất. |
| `walking_king` | Vua đi bộ (*Walking King*) | Bước chân | Chinh phục cột mốc 10.000 bước chân trong một ngày. |
| `iron_discipline` | Kỷ luật thép (*Iron Discipline*) | Dinh dưỡng | Ghi nhận 3 bữa ăn khác nhau (hoặc ít nhất 3 món) trong một ngày. |
| `fat_burner` | Siết mỡ siêu đẳng (*Ultimate Deficit*) | Năng lượng | Đạt mức thâm hụt năng lượng trên 500 kcal trong một ngày. |
| `workout_champion`| Chiến binh phòng tập (*Workout Champion*) | Luyện tập | Hoàn thành ít nhất một buổi tập được lưu vào nhật ký. |

Cơ chế đánh giá mở khóa huy hiệu (`AchievementService.checkBadges()`) được kích hoạt tự động sau mỗi hành vi có ý nghĩa của người dùng (hoàn thành bài tập, ghi món ăn từ thẻ AI trên Dashboard, thêm cốc nước, hoặc mở Dashboard). Khi một huy hiệu mới được mở khóa, dịch vụ lưu định danh huy hiệu vào `SharedPreferences` dưới khóa `unlocked_achievement_badges_v1`, kích hoạt rung phản hồi xúc giác `AppHaptics.success()` và phát sóng sự kiện qua luồng `StreamController<FitnessBadge>.broadcast()`. Màn hình đang mở sẽ lắng nghe luồng này để hiển thị hộp thoại vinh danh `BadgeUnlockDialog`. Riêng huy hiệu `fat_burner` chỉ tính thâm hụt khi trong ngày đã có ít nhất một món ăn được ghi nhận, tránh mở khóa khi lượng nạp bằng 0 chỉ vì chưa nhập dữ liệu.

Bên cạnh 9 huy hiệu trên, thẻ "Huy hiệu thành tích" ở tab Hoạt động (`BadgesAchievementWidget`) hiển thị bốn thử thách luyện tập riêng kèm thanh tiến độ: Chiến binh 10k bước, Bậc thầy Cardio, Chiến binh Bình minh (hoàn thành trước 7:00) và Ngọn lửa bất diệt (chuỗi 7 ngày).

### 4.4.3. Khóa ứng dụng bằng sinh trắc học

Trong thẻ "Bảo mật & báo cáo thể hình" của tab Hồ sơ, người dùng bật công tắc "Khóa bảo mật Sinh trắc học"; ứng dụng xác thực một lần để xác nhận rồi lưu cờ vào SharedPreferences. Từ đó, mỗi lần mở ứng dụng sẽ phải xác thực bằng vân tay hoặc khuôn mặt (cơ chế trình bày ở mục 3.8). Hộp thoại xác thực là cửa sổ hệ thống không cho phép chụp màn hình, nên phần này không có ảnh minh họa.

![Hình 4.14: Giao diện hồ sơ cá nhân và cài đặt ứng dụng](img/chup-profile-settings.png)
> CHỤP: Tab Hồ sơ (tab 4) / thông tin người dùng, chọn ngôn ngữ, huy hiệu, đăng nhập Google và Health Connect / chuyển sang tab Profile.

![Hình 4.15: Chỉ số trao đổi chất và khóa bảo mật sinh trắc học trong tab Hồ sơ](img/chup-profile-bmi-security.png)

### 4.4.4. Hỗ trợ đa ngôn ngữ (Tiếng Việt và Tiếng Anh)

Ứng dụng được thiết kế với khả năng bản địa hóa hoàn toàn thông qua dịch vụ quản lý ngôn ngữ tập trung `LocaleService`.

Giải pháp kiến trúc đa ngôn ngữ bao gồm:
1. **Nạp tài nguyên từ điển JSON:** Toàn bộ chuỗi giao diện được định nghĩa trong hai tệp tài nguyên `assets/i18n/vi.json` (Tiếng Việt) và `assets/i18n/en.json` (Tiếng Anh). Khi ứng dụng khởi động, hàm `LocaleService.init()` sử dụng `rootBundle.loadString()` để giải nén và tải toàn bộ từ điển vào cấu trúc `Map<String, Map<String, String>>` trên bộ nhớ RAM.
2. **Quản lý trạng thái chuyển đổi ngôn ngữ:** Ngôn ngữ hiện tại được lưu giữ trong một biến phản ứng `ValueNotifier<String> languageNotifier` (mặc định là `'vi'`). Khi người dùng chọn thay đổi ngôn ngữ trong màn hình hồ sơ, phương thức `LocaleService.setLanguage()` cập nhật giá trị mới, lưu lựa chọn vào `SharedPreferences` dưới khóa `app_language` và kích hoạt tái dựng giao diện hiển thị.
3. **Tra cứu và nội suy chuỗi đồng bộ:** Hàm tiện ích `LocaleService.tr(key, args: {...})` cho phép tra cứu chuỗi văn bản theo mã khóa một cách đồng bộ. Hàm hỗ trợ cơ chế nội suy tham số chuỗi dạng `{tên_biến}`, giúp truyền các đại lượng số học hoặc tên người dùng vào câu thông báo một cách linh hoạt:

```dart
static String tr(String key, {Map<String, String>? args}) {
  final lang = languageNotifier.value;
  final dict = _translations[lang] ?? _translations['vi'] ?? {};
  String text = dict[key] ?? _translations['en']?[key] ?? key;

  if (args != null && args.isNotEmpty) {
    args.forEach((k, v) {
      text = text.replaceAll('{$k}', v);
    });
  }
  return text;
}
```
(Nguồn: lib/services/locale_service.dart:63-74)

Nhờ kiến trúc này, phần lớn văn bản giao diện — tên tab, danh mục bài tập, nhãn chỉ số, thông báo — được chuyển đổi ngay khi đổi ngôn ngữ mà không cần khởi động lại ứng dụng (Hình 4.16). Nội dung do Gemini sinh ra (tên món, giáo án, lời khuyên, bản tin ngày) cũng theo ngôn ngữ đang chọn vì prompt truyền kèm ngôn ngữ hiện tại.

![Hình 4.16: Tab Hồ sơ ở chế độ tiếng Anh](img/chup-profile-english.png)
