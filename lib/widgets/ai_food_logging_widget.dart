import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../services/gemini_service.dart';
import '../services/speech_service.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import '../utils/app_haptics.dart';
import '../services/achievement_service.dart';
import 'app_ui_components.dart';
import 'barcode_scanner_sheet.dart';

class AiFoodLoggingWidget extends StatefulWidget {
  final VoidCallback? onFoodUpdated;
  final DateTime? selectedDate;

  const AiFoodLoggingWidget({
    super.key,
    this.onFoodUpdated,
    this.selectedDate,
  });

  @override
  State<AiFoodLoggingWidget> createState() => _AiFoodLoggingWidgetState();
}

class _AiFoodLoggingWidgetState extends State<AiFoodLoggingWidget>
    with SingleTickerProviderStateMixin {
  final SpeechService _speechService = SpeechService();
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLogging = false;
  bool _isVoiceMode = true;
  bool _isListening = false;
  bool _isLoading = false;
  String _speechStatus = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  List<FoodLogEntry> _loggedFoods = [];
  int _totalCaloriesIn = 0;
  Map<String, int> _macros = {'protein': 0, 'carbs': 0, 'fat': 0};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadFoodData();
    StorageService.foodUpdateNotifier.addListener(_loadFoodData);
    _initSpeech();
  }

  @override
  void didUpdateWidget(covariant AiFoodLoggingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _loadFoodData();
    }
  }

  Future<void> _loadFoodData() async {
    final targetDate = widget.selectedDate ?? DateTime.now();
    final list = await StorageService.getFoodLogsByDate(targetDate);
    final calories = await StorageService.getTotalCaloriesInByDate(targetDate);
    final macros = await StorageService.getTotalMacrosByDate(targetDate);
    if (mounted) {
      setState(() {
        _loggedFoods = list;
        _totalCaloriesIn = calories;
        _macros = macros;
      });
    }
  }

  Future<void> _initSpeech() async {
    await _speechService.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted && _isListening) {
            setState(() {
              _isListening = false;
              _speechStatus = 'Recording finished. Ready to analyze!';
            });
            if (_textController.text.trim().isNotEmpty) {
              _analyzeFood();
            }
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isListening = false;
            _speechStatus = 'Could not hear clearly: $error. Please try again!';
          });
        }
      },
    );
  }

  @override
  void dispose() {
    StorageService.foodUpdateNotifier.removeListener(_loadFoodData);
    _pulseController.dispose();
    _textController.dispose();
    _speechService.stopListening();
    super.dispose();
  }

  Future<void> _startVoiceListening() async {
    setState(() {
      _isListening = true;
      _speechStatus = 'Listening to your meal description...';
      _textController.clear();
    });

    await _speechService.startListening(
      onResult: (text, isFinal) {
        if (mounted) {
          setState(() {
            _textController.text = text;
          });
        }
      },
    );
  }

  Future<void> _stopVoiceListening() async {
    await _speechService.stopListening();
    if (mounted) {
      setState(() {
        _isListening = false;
      });
      if (_textController.text.trim().isNotEmpty) {
        _analyzeFood();
      }
    }
  }

  Future<void> _analyzeFood() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _speechStatus = 'Gemini AI estimating calories & nutrients...';
    });

    try {
      final result = await GeminiService.analyzeFood(text);
      if (result != null) {
        final targetDate = widget.selectedDate ?? DateTime.now();
        final now = DateTime.now();
        final timestamp = DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          now.hour,
          now.minute,
          now.second,
        );
        await StorageService.logFoodItem(result, timestamp: timestamp);
        AppHaptics.success();
        AchievementService.checkBadges();
        await _loadFoodData();
        widget.onFoodUpdated?.call();

        if (mounted) {
          setState(() {
            _textController.clear();
            _isLogging = false;
            _isListening = false;
            _speechStatus = 'Tap microphone and speak the food item';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added: ${result.name} (+${result.calories} kcal)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to analyze food. Please try again!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteFood(String id, String name) async {
    await StorageService.deleteFoodLog(id);
    await _loadFoodData();
    widget.onFoodUpdated?.call();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed: $name'),
          backgroundColor: Colors.grey.shade800,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12
        ? (dt.hour - 12).toString()
        : (dt.hour == 0 ? '12' : dt.hour.toString());
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Future<void> _showImageSourceDialog() async {
    AppBottomSheet.show(
      context: context,
      useRootNavigator: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF161A26),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BottomSheetDragHandle(),
              const SizedBox(height: 10),
              Text(
                LocaleService.tr('scan_photo_title'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF00F0FF)),
                ),
                title: Text(
                  LocaleService.tr('scan_photo_camera'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndAnalyzeImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF007AFF)),
                ),
                title: Text(
                  LocaleService.tr('scan_photo_gallery'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndAnalyzeImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9E00).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFFFF9E00)),
                ),
                title: Text(
                  LocaleService.tr('scan_barcode_option'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Open Food Facts database',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  BarcodeScannerSheet.show(
                    context,
                    onFoodLogged: (food, mealType) async {
                      await _loadFoodData();
                      widget.onFoodUpdated?.call();
                    },
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndAnalyzeImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return Dialog(
            backgroundColor: const Color(0xFF131722),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(picked.path),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Color(0xFF00F0FF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    LocaleService.tr('analyzing_food_image'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Đang trích xuất calo & dinh dưỡng macro...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        },
      );

      final bytes = await picked.readAsBytes();
      final foodInfo = await GeminiService.analyzeFoodImage(bytes);

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (foodInfo != null && foodInfo.name.isNotEmpty) {
        _showFoodConfirmationModal(foodInfo, picked.path);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleService.tr('food_analyzing_failed')),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _showFoodConfirmationModal(FoodInfo food, String imagePath) async {
    final nameCtrl = TextEditingController(text: food.name);
    final calCtrl = TextEditingController(text: '${food.calories}');
    final proteinCtrl = TextEditingController(text: '${food.protein}');
    final carbsCtrl = TextEditingController(text: '${food.carbs}');
    final fatCtrl = TextEditingController(text: '${food.fat}');

    await AppBottomSheet.show(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          File(imagePath),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              LocaleService.tr('confirm_meal_title'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              LocaleService.tr('edit_meal_hint'),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: LocaleService.tr('meal_name_label'),
                      labelStyle: const TextStyle(color: Color(0xFF00F0FF), fontSize: 13),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF00F0FF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildEditableMacroField('Calo (kcal)', calCtrl, Colors.orangeAccent),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildEditableMacroField('Đạm (g)', proteinCtrl, const Color(0xFF00F0FF)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildEditableMacroField('Carb (g)', carbsCtrl, const Color(0xFFFFD166)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildEditableMacroField('Béo (g)', fatCtrl, const Color(0xFFFF4D4D)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final cal = int.tryParse(calCtrl.text.trim()) ?? food.calories;
                        final p = int.tryParse(proteinCtrl.text.trim()) ?? food.protein;
                        final c = int.tryParse(carbsCtrl.text.trim()) ?? food.carbs;
                        final f = int.tryParse(fatCtrl.text.trim()) ?? food.fat;
                        final name = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : food.name;

                        final finalFood = FoodInfo(
                          name: name,
                          calories: cal,
                          protein: p,
                          carbs: c,
                          fat: f,
                        );

                        final targetDate = widget.selectedDate ?? DateTime.now();
                        final now = DateTime.now();
                        final timestamp = DateTime(
                          targetDate.year,
                          targetDate.month,
                          targetDate.day,
                          now.hour,
                          now.minute,
                          now.second,
                        );

                        await StorageService.logFoodItem(
                          finalFood,
                          timestamp: timestamp,
                          imagePath: imagePath,
                        );
                        AppHaptics.success();
                        AchievementService.checkBadges();
                        await _loadFoodData();
                        widget.onFoodUpdated?.call();

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã thêm món ăn: $name (+$cal kcal)'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FFA3),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: Text(
                        LocaleService.tr('confirm_and_save'),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditableMacroField(String label, TextEditingController ctrl, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double targetCalories = 2000.0;
    final double calRatio = (_totalCaloriesIn / targetCalories).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.06),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Widget
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.restaurant_rounded,
                      color: Color(0xFF00F0FF),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleService.tr('ai_food_logging_title'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        LocaleService.tr('ai_food_logging_sub'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_isLogging)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isVoiceMode = !_isVoiceMode;
                      _textController.clear();
                    });
                  },
                  icon: Icon(
                    _isVoiceMode ? Icons.keyboard : Icons.mic,
                    color: Colors.white70,
                  ),
                  tooltip: _isVoiceMode ? 'Type with keyboard' : 'Use voice',
                ),
            ],
          ),

          const SizedBox(height: 18),

          // Real-time Today's Nutrition Summary
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      LocaleService.tr('total_calories_in'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    Text(
                      '$_totalCaloriesIn / 2,000 kcal',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF00F0FF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: calRatio,
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      calRatio > 1.0 ? Colors.redAccent : const Color(0xFF00F0FF),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 3 Macro Chips
                Row(
                  children: [
                    _buildMacroChip(LocaleService.tr('macro_protein_short'), '${_macros['protein'] ?? 0}g', const Color(0xFF00F0FF)),
                    const SizedBox(width: 8),
                    _buildMacroChip(LocaleService.tr('macro_carbs_short'), '${_macros['carbs'] ?? 0}g', const Color(0xFFFFB800)),
                    const SizedBox(width: 8),
                    _buildMacroChip(LocaleService.tr('macro_fat_short'), '${_macros['fat'] ?? 0}g', const Color(0xFFFF2D55)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Main Action Buttons
          if (!_isLogging) ...[
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _showImageSourceDialog,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00F0FF), Color(0xFF0072FF)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F0FF).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              LocaleService.tr('log_food_camera_btn'),
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      BarcodeScannerSheet.show(
                        context,
                        onFoodLogged: (food, mealType) async {
                          await _loadFoodData();
                          widget.onFoodUpdated?.call();
                        },
                      );
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9E00), Color(0xFFFF5500)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF9E00).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 19),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              LocaleService.tr('log_food_barcode_btn'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isLogging = true;
                          _isVoiceMode = true;
                        });
                      },
                      icon: const Icon(Icons.mic_none_rounded, color: Color(0xFF00FFA3), size: 18),
                      label: Text(
                        LocaleService.tr('log_food_voice_short_btn'),
                        style: const TextStyle(
                          color: Color(0xFF00FFA3),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: const Color(0xFF00FFA3).withValues(alpha: 0.35)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        backgroundColor: const Color(0xFF00FFA3).withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isLogging = true;
                          _isVoiceMode = false;
                        });
                      },
                      icon: const Icon(Icons.keyboard_alt_outlined, color: Colors.white70, size: 18),
                      label: Text(
                        LocaleService.tr('type_with_keyboard'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        backgroundColor: Colors.white.withValues(alpha: 0.03),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ]
          else if (_isVoiceMode)
            _buildVoiceRecordingPanel()
          else
            _buildKeyboardInputPanel(),

          const SizedBox(height: 22),

          // Logged Food List Header
          Builder(
            builder: (context) {
              final isViewingToday = widget.selectedDate == null ||
                  StorageService.getTodayDateString(widget.selectedDate!) ==
                      StorageService.getTodayDateString();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isViewingToday
                        ? LocaleService.tr('todays_meals', args: {'count': '${_loggedFoods.length}'})
                        : LocaleService.tr('date_meals', args: {'count': '${_loggedFoods.length}'}),
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      fontSize: 12,
                    ),
                  ),
                  const Icon(Icons.history_rounded, size: 16, color: AppTheme.textSecondaryColor),
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          if (_loggedFoods.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.no_meals_rounded, color: AppTheme.textSecondaryColor, size: 30),
                  const SizedBox(height: 8),
                  Text(
                    (widget.selectedDate == null ||
                            StorageService.getTodayDateString(widget.selectedDate!) ==
                                StorageService.getTodayDateString())
                        ? LocaleService.tr('no_meals_today')
                        : LocaleService.tr('no_meals_date'),
                    style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    LocaleService.tr('speak_or_type_hint'),
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            )
          else
            ..._loggedFoods.map((food) => _buildFoodItem(food)),
        ],
      ),
    );
  }

  Widget _buildMacroChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Giao diện thu âm giọng nói với Animation sóng âm
  Widget _buildVoiceRecordingPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isListening
              ? AppTheme.primaryColor
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              if (_isListening) {
                _stopVoiceListening();
              } else {
                _startVoiceListening();
              }
            },
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isListening ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening
                          ? AppTheme.primaryColor
                          : Colors.grey.shade900,
                      boxShadow: _isListening
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(alpha: 0.6),
                                blurRadius: 25,
                                spreadRadius: 4,
                              )
                            ]
                          : [],
                    ),
                    child: Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Voice Status
          Text(
            _isListening
                ? LocaleService.tr('listening_status')
                : (_speechStatus.isEmpty
                    ? LocaleService.tr('speech_default_hint')
                    : _speechStatus),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _isListening ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
              fontWeight: _isListening ? FontWeight.bold : FontWeight.normal,
              fontSize: 12.5,
            ),
          ),

          if (_textController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                '“${_textController.text}”',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            ),
          ],

          if (_isLoading) ...[
            const SizedBox(height: 14),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryColor,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Gemini AI analyzing nutrients...',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),

          // Suggestions
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _buildExampleChip('1 bowl of beef pho'),
              _buildExampleChip('Grilled chicken salad'),
              _buildExampleChip('2 boiled eggs & 1 apple'),
            ],
          ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isVoiceMode = false;
                    _textController.clear();
                  });
                },
                icon: const Icon(Icons.keyboard_alt_outlined, size: 16, color: AppTheme.primaryColor),
                label: Text(
                  LocaleService.tr('type_with_keyboard'),
                  style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogging = false;
                    _isListening = false;
                    _speechService.stopListening();
                    _textController.clear();
                  });
                },
                child: Text(LocaleService.tr('cancel_btn'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExampleChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      onPressed: () {
        _textController.text = text;
        _analyzeFood();
      },
    );
  }

  /// Fallback keyboard input panel
  Widget _buildKeyboardInputPanel() {
    return Column(
      children: [
        TextField(
          controller: _textController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: LocaleService.tr('food_input_hint'),
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
            filled: true,
            fillColor: Colors.black,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppTheme.primaryColor),
                    onPressed: _analyzeFood,
                  ),
          ),
          onSubmitted: (_) => _analyzeFood(),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isVoiceMode = true;
                });
              },
              icon: const Icon(Icons.mic, size: 16, color: AppTheme.primaryColor),
              label: Text(
                LocaleService.tr('switch_to_voice'),
                style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLogging = false;
                  _textController.clear();
                });
              },
              child: Text(LocaleService.tr('cancel_btn'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFoodItem(FoodLogEntry food) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          if (food.imagePath != null && File(food.imagePath!).existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(food.imagePath!),
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.restaurant_rounded, color: AppTheme.primaryColor, size: 18),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        food.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatTime(food.timestamp),
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 13,
                      color: Colors.orangeAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${food.calories} kcal',
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'P: ${food.protein}g  •  C: ${food.carbs}g  •  F: ${food.fat}g',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.white38),
            onPressed: () => _deleteFood(food.id, food.name),
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}
