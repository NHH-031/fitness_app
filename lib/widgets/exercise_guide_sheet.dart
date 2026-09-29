import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme.dart';
import '../utils/app_haptics.dart';
import 'app_ui_components.dart';

class FormTechniqueGuideData {
  final String title;
  final String targetMuscle;
  final String secondaryMuscles;
  final List<String> steps;
  final List<String> commonMistakes;
  final String safetyTip;

  const FormTechniqueGuideData({
    required this.title,
    required this.targetMuscle,
    required this.secondaryMuscles,
    required this.steps,
    required this.commonMistakes,
    required this.safetyTip,
  });
}


class ExerciseGuideSheet extends StatelessWidget {
  final String exerciseTitle;
  final String? targetMuscle;
  final String? secondaryMuscles;

  const ExerciseGuideSheet({
    super.key,
    required this.exerciseTitle,
    this.targetMuscle,
    this.secondaryMuscles,
  });

  static void show(
    BuildContext context, {
    required String exerciseTitle,
    String? targetMuscle,
    String? secondaryMuscles,
  }) {
    AppHaptics.light();
    AppBottomSheet.show(
      context: context,
      builder: (_) => ExerciseGuideSheet(
        exerciseTitle: exerciseTitle,
        targetMuscle: targetMuscle,
        secondaryMuscles: secondaryMuscles,
      ),
    );
  }

  static const Map<String, FormTechniqueGuideData> _guideDatabase = {
    'bench press': FormTechniqueGuideData(
      title: 'Bench Press (Đẩy Ngực Ngang)',
      targetMuscle: 'Cơ ngực lớn (Pectoralis Major)',
      secondaryMuscles: 'Cơ vai trước (Anterior Deltoid), Cơ tay sau (Triceps)',
      steps: [
        'Nằm thẳng trên ghế, mắt nhìn thẳng lên thanh đòn.',
        'Hai bàn chân đạp chắc xuống sàn, ưỡn ngực, siết chặt xương bả vai (retract scapula).',
        'Nắm thanh đòn rộng hơn vai 1.5 lần, nhấc tạ ra khỏi giá.',
        'Hít sâu gồng cơ bụng (Valsalva maneuver), hạ tạ có kiểm soát chạm nhẹ vào điểm giữa ngực.',
        'Thở ra dứt khoát và đẩy tạ lên theo hình vòng cung nhẹ về phía mặt, không khóa khớp khuỷu tay.',
      ],
      commonMistakes: [
        'Cong cổ tay quá mức gây đau khớp cổ tay - Cần giữ cổ tay thẳng góc với thanh đòn.',
        'Nhấc mông khỏi mặt ghế khi dùng lực nặng - Phải giữ mông áp chặt vào mặt phẳng ghế.',
        'Mở rộng cùi chỏ vuông góc 90 độ với thân - Góc cùi chỏ tối ưu là 45-70 độ để bảo vệ bao khớp vai.',
      ],
      safetyTip: 'Luôn luôn sử dụng khóa đòn (collars) và nhờ người hỗ trợ (spotter) khi đẩy các mức tạ tiệm cận 1RM.',
    ),
    'barbell squat': FormTechniqueGuideData(
      title: 'Barbell Squat (Gánh Tạ Đùi)',
      targetMuscle: 'Đùi trước (Quads), Cơ mông (Glutes)',
      secondaryMuscles: 'Đùi sau (Hamstrings), Cơ dựng sống (Lower Back), Cơ lõi (Core)',
      steps: [
        'Đặt thanh đòn trên cơ cầu vai (High bar) hoặc gai vai (Low bar).',
        'Chân mở rộng bằng hoặc hơn vai một chút, mũi chân hơi chếch ra ngoài 15-30 độ.',
        'Hít sâu phình bụng nén khí, đẩy nhẹ hông ra sau và gập gối hạ thấp người.',
        'Hạ xuống cho đến khi đùi song song hoặc sâu hơn khớp gối (Crease of hip below knee).',
        'Đạp mạnh đều qua toàn bộ lòng bàn chân, đẩy hông tiến lên về vị trí thẳng đứng ban đầu.',
      ],
      commonMistakes: [
        'Đầu gối sụp vào trong (Knee Valgus) - Hãy luôn chủ động đẩy đầu gối hướng theo hướng mũi chân.',
        'Cong lưng dưới ở đáy động tác (Butt wink) - Hạn chế biên độ hoặc cải thiện độ linh hoạt của cổ chân.',
        'Nhấc gót chân khi ngồi xuống - Trọng tâm phải dồn đều vào giữa bàn chân (mid-foot).',
      ],
      safetyTip: 'Cài thanh an toàn (Safety pins) đúng tầm dưới đáy squat để dễ dàng xả tạ nếu bị kiệt sức.',
    ),
    'deadlift': FormTechniqueGuideData(
      title: 'Conventional Deadlift (Kéo Tạ Đất)',
      targetMuscle: 'Toàn bộ chuỗi cơ phía sau (Posterior Chain), Đùi sau, Mông',
      secondaryMuscles: 'Lưng dưới, Cầu vai, Cẳng tay, Cơ lõi',
      steps: [
        'Đứng với thanh đòn nằm ngay giữa bàn chân (cách cẳng chân khoảng 2-3 cm).',
        'Hạ hông xuống, nắm chặt thanh đòn ngay bên ngoài vị trí cẳng chân.',
        'Kéo căng người, mở ngực và kích hoạt cơ xô (Lats) như đang muốn bẻ cong thanh đòn.',
        'Hít sâu khóa bụng, dùng lực đạp sàn bằng chân rồi kéo tạ lên sát dọc ống chân.',
        'Đứng thẳng hoàn toàn, khóa khớp hông dứt khoát nhưng không ưỡn ngửa lưng ra sau.',
      ],
      commonMistakes: [
        'Cong lưng tôm (Lumbar flexion) - Nguy cơ thoát vị đĩa đệm cực cao. Lưng luôn phải thẳng tự nhiên.',
        'Kéo giật tạ đột ngột (Jerking the bar) - Phải kéo lấy độ rơ của thanh đòn (take the slack) trước khi kéo rời sàn.',
        'Để thanh đòn trôi ra xa cẳng chân - Khiến đòn bẩy dài ra và dồn áp lực khổng lồ lên đốt sống L4-L5.',
      ],
      safetyTip: 'Tập trung đạp sàn bằng gót chân và cạnh ngoài bàn chân hơn là cố gắng kéo thanh tạ bằng tay.',
    ),
    'overhead shoulder press': FormTechniqueGuideData(
      title: 'Overhead Press / OHP (Đẩy Tạ Qua Đầu)',
      targetMuscle: 'Cơ vai trước & ngang (Deltoids)',
      secondaryMuscles: 'Tay sau (Triceps), Cầu vai, Cơ ngực trên, Cơ lõi',
      steps: [
        'Đứng thẳng, hai chân mở rộng bằng vai, hai tay nắm đòn ngay ngoài bề rộng vai.',
        'Nâng thanh đòn tỳ trên xương quai xanh, cùi chỏ hướng nhẹ về phía trước.',
        'Siết chặt mông và cơ bụng, hơi ngả cằm về sau để nhường đường cho thanh đòn.',
        'Đẩy tạ thẳng đứng lên trên đỉnh đầu, khi đòn qua trán thì đưa đầu nhẹ về phía trước.',
        'Hạ tạ có kiểm soát về điểm xuất phát trên xương đòn.',
      ],
      commonMistakes: [
        'Ưỡn quá mức lưng dưới để đẩy tạ - Thay vào đó hãy siết chặt cơ mông và cơ bụng như một khối trụ.',
        'Cùi chỏ tõe sang hai bên quá rộng làm xoay khớp vai trong trạng thái bất lợi.',
      ],
      safetyTip: 'Không nên ngửa cổ ra sau khi nâng tạ nặng để tránh chóng mặt do mất cân bằng tiền đình.',
    ),
    'hip thrust': FormTechniqueGuideData(
      title: 'Barbell Hip Thrust (Đẩy Hông Tạ Đòn)',
      targetMuscle: 'Cơ mông lớn (Gluteus Maximus)',
      secondaryMuscles: 'Đùi sau (Hamstrings), Cơ lõi (Core), Đùi trước',
      steps: [
        'Tựa phần dưới xương bả vai lên mép ghế tập (băng ghế cao khoảng 35-40 cm).',
        'Đặt thanh đòn ngang nếp gấp hông (có đệm mút lót êm ái), hai bàn chân đặt phẳng trên sàn.',
        'Khoảng cách hai chân bằng vai, cẳng chân vuông góc 90 độ với sàn khi nâng hông lên đỉnh.',
        'Hít sâu, siết cơ bụng, mắt nhìn về phía trước (hơi gập cằm về ngực).',
        'Đạp mạnh gót chân đẩy hông lên cho đến khi thân người, hông và đầu gối tạo thành một đường thẳng.',
        'Siết chặt mông hết cỡ ở đỉnh trong 1-2 giây rồi hạ chậm có kiểm soát.',
      ],
      commonMistakes: [
        'Ngửa đầu và ưỡn quá mức thắt lưng ở đỉnh động tác - Gây đau lưng dưới; hãy luôn gập cằm và nhìn thẳng.',
        'Đặt bàn chân quá xa (ăn nhiều vào đùi sau) hoặc quá gần (ăn nhiều vào đùi trước).',
        'Đẩy tạ bằng mũi chân thay vì dùng lực dồn vào gót chân.',
      ],
      safetyTip: 'Luôn dùng đệm xốp bảo vệ thanh đòn (barbell pad) để tránh đau và bầm xương chậu.',
    ),
    'bulgarian split squat': FormTechniqueGuideData(
      title: 'Bulgarian Split Squat (Squat Một Chân Với Ghế)',
      targetMuscle: 'Cơ mông (Glutes), Đùi trước (Quadriceps)',
      secondaryMuscles: 'Đùi sau, Bắp chân, Cơ ổn định hông',
      steps: [
        'Đứng quay lưng về phía ghế tập, mu bàn chân sau đặt lên ghế.',
        'Chân trước bước lên một khoảng vừa đủ sao cho khi hạ xuống đầu gối không bị chèn ép quá mức.',
        'Giữ ngực mở, hơi nghiêng thân trên về phía trước khoảng 15-20 độ để dồn tối đa lực vào cơ mông.',
        'Hạ trọng tâm thẳng đứng xuống cho đến khi đùi chân trước gần như song song với mặt sàn.',
        'Dồn lực vào gót chân trước và đạp mạnh vươn người lên vị trí ban đầu.',
      ],
      commonMistakes: [
        'Đứng người quá thẳng đứng khiến khớp gối và cơ đùi trước chịu lực thay vì cơ mông.',
        'Đầu gối chân trước lắc lư hoặc sụp vào trong do cơ mông nhỡ yếu.',
        'Trọng tâm đổ quá nhiều về chân sau trên ghế.',
      ],
      safetyTip: 'Có thể tập với trọng lượng cơ thể trước khi cầm thêm tạ đơn (dumbbells) ở hai tay.',
    ),
    'cable kickback': FormTechniqueGuideData(
      title: 'Cable Glute Kickback (Đá Cáp Kích Hoạt Mông)',
      targetMuscle: 'Cơ mông lớn & Mông nhỡ (Gluteus Maximus & Medius)',
      secondaryMuscles: 'Đùi sau, Cơ ổn định thân',
      steps: [
        'Đeo đai cổ chân kết nối với ròng rọc cáp ở mức thấp nhất.',
        'Đứng đối diện máy cáp, hơi gập hông nghiêng người về trước, tay bám vào khung máy để giữ thăng bằng.',
        'Siết chặt cơ bụng để khóa đốt sống thắt lưng cố định hoàn toàn.',
        'Dùng cơ mông đá chân có đeo đai ra sau và hơi chếch nhẹ 30 độ ra phía ngoài.',
        'Giữ siết chặt cơ mông ở điểm co thắt tối đa trong 1 giây trước khi trả chân về chậm rãi.',
      ],
      commonMistakes: [
        'Võng lưng dưới để đá chân lên cao - Đây là lỗi rất phổ biến khiến mỏi lưng thay vì mông.',
        'Dùng quán tính vung giật chân thay vì kiểm soát chuyển động.',
      ],
      safetyTip: 'Ưu tiên cảm nhận cơ (mind-muscle connection) hơn là cài mức tạ cáp quá nặng.',
    ),
    'sumo squat': FormTechniqueGuideData(
      title: 'Sumo Squat (Squat Thế Đứng Rộng)',
      targetMuscle: 'Cơ mông, Cơ đùi trong (Adductors)',
      secondaryMuscles: 'Đùi trước, Đùi sau, Cơ lõi',
      steps: [
        'Đứng chân rộng hơn vai khoảng 1.5 - 2 lần, mũi bàn chân xoay chếch ra ngoài 45 độ.',
        'Cầm một quả tạ đơn thẳng trước người hoặc gánh tạ đòn trên vai.',
        'Mở khớp háng, đẩy đầu gối theo đúng hướng chỉ của ngón chân cái và hạ hông xuống.',
        'Hạ sâu cho đến khi đùi song song với sàn, cảm nhận cơ đùi trong và mông căng tối đa.',
        'Đạp mạnh từ lòng bàn chân, siết cơ đùi trong và mông để đứng thẳng dậy.',
      ],
      commonMistakes: [
        'Để đầu gối sụp vào trong (không mở theo hướng mũi chân).',
        'Gập người quá nhiều về phía trước làm mất thăng bằng.',
      ],
      safetyTip: 'Khởi động kỹ khớp háng và hông trước khi tập để tránh căng cơ đùi trong.',
    ),
    'romanian deadlift': FormTechniqueGuideData(
      title: 'Romanian Deadlift / RDL (Kéo Đùi Sau & Mông)',
      targetMuscle: 'Đùi sau (Hamstrings), Cơ mông (Gluteus Maximus)',
      secondaryMuscles: 'Lưng dưới (Erectors), Cơ xô, Cẳng tay',
      steps: [
        'Cầm tạ đòn hoặc 2 quả tạ đơn trước đùi, hai chân mở rộng bằng hông.',
        'Đầu gối hơi chùng nhẹ và giữ góc gối này cố định trong suốt bài tập.',
        'Bắt đầu chuyển động Hinge: đẩy hông ra sau hết mức có thể như muốn chạm mông vào tường phía sau.',
        'Trượt tạ sát dọc theo đùi xuống qua đầu gối cho đến khi cảm thấy đùi sau căng mạnh.',
        'Siết chặt mông và đẩy khớp hông về trước để trở lại tư thế đứng thẳng.',
      ],
      commonMistakes: [
        'Gập đầu gối quá nhiều biến bài tập thành squat thường.',
        'Cong lưng dưới khi hạ tạ xuống quá thấp (vượt quá độ linh hoạt của đùi sau).',
        'Để tạ trôi ra xa chân làm dồn lực xấu vào cột sống.',
      ],
      safetyTip: 'Chỉ cần hạ tạ đến dưới xương bánh chè một chút, không cần chạm sàn.',
    ),
    'lat pulldown': FormTechniqueGuideData(
      title: 'Lat Pulldown (Kéo Cáp Xô Xuống)',
      targetMuscle: 'Cơ xô lưng (Latissimus Dorsi)',
      secondaryMuscles: 'Cơ lưng giữa, Tay trước (Biceps), Vai sau',
      steps: [
        'Ngồi vào máy tập, chỉnh đệm đùi ôm sát để giữ cố định thân dưới.',
        'Nắm thanh đòn rộng hơn vai, lòng bàn tay hướng về phía trước.',
        'Ưỡn ngực nhẹ, ngả người về sau khoảng 10-15 độ, siết xương bả vai.',
        'Kéo thanh đòn xuống chạm nhẹ vào phần ngực trên, hướng cùi chỏ ra sau và xuống sàn.',
        'Nhả thanh đòn từ từ lên trên để cảm nhận toàn bộ cơ xô giãn hết cỡ.',
      ],
      commonMistakes: [
        'Vung vẩy giật người ra sau để kéo tạ nặng.',
        'Kéo thanh đòn ra sau gáy (Behind the neck) - Gây chấn thương khớp vai và cổ.',
        'Dùng lực bắp tay trước quá nhiều thay vì dùng lưng xô.',
      ],
      safetyTip: 'Hình dung việc đưa cùi chỏ kéo sát xuống sàn thay vì tập trung kéo bàn tay.',
    ),
  };

  FormTechniqueGuideData _resolveGuide() {
    final lower = exerciseTitle.toLowerCase();
    for (final key in _guideDatabase.keys) {
      if (lower.contains(key)) {
        return _guideDatabase[key]!;
      }
    }
    // Generic fallback for any other exercise
    return FormTechniqueGuideData(
      title: exerciseTitle,
      targetMuscle: targetMuscle ?? 'Nhóm cơ mục tiêu chính',
      secondaryMuscles: secondaryMuscles ?? 'Các nhóm cơ ổn định và bổ trợ chuyển động',
      steps: [
        'Chuẩn bị tư thế: Đứng hoặc ngồi vững chắc, hít thở sâu, ổn định trục cột sống.',
        'Bắt đầu chuyển động với tốc độ có kiểm soát, tập trung cảm nhận nhóm cơ co bóp.',
        'Giữ cơ ở đỉnh co thắt (peak contraction) trong 0.5 - 1 giây.',
        'Hạ tạ chậm rãi trong 2-3 giây ở pha giãn cơ (Eccentric phase).',
        'Duy trì nhịp thở: Hít vào khi giãn cơ, thở ra dứt khoát khi dùng lực đẩy/kéo.',
      ],
      commonMistakes: [
        'Dùng quán tính cơ thể (cheating / vung lắc) thay vì dùng sức của nhóm cơ chính.',
        'Khóa cứng khớp ở đỉnh chuyển động gây áp lực bào mòn sụn khớp.',
        'Thở gấp hoặc nín thở quá lâu gây tụt huyết áp.',
      ],
      safetyTip: 'Hãy ưu tiên thực hiện đúng biên độ chuyển động (Full ROM) trước khi nghĩ đến việc tăng tải trọng.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final guide = _resolveGuide();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF131722),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BottomSheetDragHandle(),
            const SizedBox(height: 10),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00F0FF).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const HugeIcon(
                              icon: HugeIcons.strokeRoundedDumbbell01,
                              color: Color(0xFF00F0FF),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'KỸ THUẬT ĐỘNG TÁC CHUẨN',
                            style: AppTheme.font(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF00F0FF),
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        guide.title,
                        style: AppTheme.font(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Muscles Anatomy Info Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🎯 Cơ mục tiêu: ',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Expanded(
                        child: Text(
                          guide.targetMuscle,
                          style: const TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⚡ Cơ bổ trợ:   ',
                        style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w500, fontSize: 12),
                      ),
                      Expanded(
                        child: Text(
                          guide.secondaryMuscles,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Step by Step Execution
            Row(
              children: [
                const Icon(Icons.format_list_numbered, color: Color(0xFF00F0FF), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Các bước thực hiện chuẩn:',
                  style: AppTheme.font(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...guide.steps.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final stepText = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '$idx',
                        style: const TextStyle(
                          color: Color(0xFF00F0FF),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        stepText,
                        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 14),

            // Common Mistakes & Injury Prevention Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4D4D).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFF4D4D).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFFF4D4D), size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Lỗi sai phổ biến & Cảnh báo chấn thương:',
                        style: TextStyle(color: Color(0xFFFF4D4D), fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...guide.commonMistakes.map(
                    (mistake) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: Color(0xFFFF4D4D), fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              mistake,
                              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Safety Tip Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9E00).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFF9E00).withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, color: Color(0xFFFF9E00), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lời khuyên an toàn: ${guide.safetyTip}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Got it button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F0FF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Đã hiểu kỹ thuật', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
