import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme.dart';
import '../services/gemini_service.dart';
import '../services/speech_service.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import '../utils/app_haptics.dart';
import '../models/favorite_food.dart';
import 'app_ui_components.dart';

class MealCategoryCardWidget extends StatefulWidget {
  final String mealType; // 'Breakfast', 'Lunch', 'Dinner', 'Snack'
  final String title;
  final String emoji;
  final List<List<dynamic>>? hugeIcon;
  final Color? iconColor;
  final String timeRange;
  final int budgetCalories;
  final VoidCallback? onFoodChanged;

  const MealCategoryCardWidget({
    super.key,
    required this.mealType,
    required this.title,
    this.emoji = '',
    this.hugeIcon,
    this.iconColor,
    required this.timeRange,
    required this.budgetCalories,
    this.onFoodChanged,
  });

  @override
  State<MealCategoryCardWidget> createState() => _MealCategoryCardWidgetState();
}

class _MealCategoryCardWidgetState extends State<MealCategoryCardWidget> {
  bool _isExpanded = true;
  List<FoodLogEntry> _items = [];
  int _totalMealCalories = 0;
  Set<String> _favoriteNames = {};

  @override
  void initState() {
    super.initState();
    _loadMealItems();
    StorageService.foodUpdateNotifier.addListener(_loadMealItems);
  }

  @override
  void dispose() {
    StorageService.foodUpdateNotifier.removeListener(_loadMealItems);
    super.dispose();
  }

  Future<void> _loadMealItems() async {
    final list = await StorageService.getTodayFoodLogsByMeal(widget.mealType);
    final favs = await NutritionRepository.instance.getFavoriteFoods();
    int sum = 0;
    for (final item in list) {
      sum += item.calories;
    }
    if (mounted) {
      setState(() {
        _items = list;
        _totalMealCalories = sum;
        _favoriteNames = favs.map((f) => f.name.trim().toLowerCase()).toSet();
      });
    }
  }

  Future<void> _deleteItem(String id, String name) async {
    await StorageService.deleteFoodLog(id);
    await _loadMealItems();
    widget.onFoodChanged?.call();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed $name from ${widget.title}'),
          backgroundColor: Colors.grey.shade900,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAddFoodDialog() {
    AppBottomSheet.show(
      context: context,
      builder: (ctx) => _AddFoodModal(
        mealType: widget.mealType,
        mealTitle: widget.title,
        onAdded: () {
          _loadMealItems();
          widget.onFoodChanged?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_totalMealCalories / widget.budgetCalories).clamp(0.0, 1.0);
    final isOverBudget = _totalMealCalories > widget.budgetCalories;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: SquircleCard(
        cornerRadius: 22,
        surfaceColor: const Color(0xFF131724),
        borderColor: Colors.white.withValues(alpha: 0.08),
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Header Section
            InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: ShapeDecoration(
                              color: (widget.iconColor ?? const Color(0xFF00F0FF)).withValues(alpha: 0.12),
                              shape: SmoothRectangleBorder(
                                borderRadius: SmoothBorderRadius(
                                  cornerRadius: 13,
                                  cornerSmoothing: 0.6,
                                ),
                                side: BorderSide(
                                  color: (widget.iconColor ?? const Color(0xFF00F0FF)).withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: widget.hugeIcon != null
                                ? HugeIcon(
                                    icon: widget.hugeIcon!,
                                    color: widget.iconColor ?? const Color(0xFF00F0FF),
                                    size: 22,
                                  )
                                : Text(
                                    widget.emoji,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: AppTheme.font(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                widget.timeRange,
                                style: AppTheme.font(
                                  fontSize: 11,
                                  color: Colors.white38,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$_totalMealCalories kcal',
                                style: AppTheme.font(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isOverBudget
                                      ? Colors.redAccent
                                      : const Color(0xFF00F0FF),
                                ),
                              ),
                              Text(
                                'Rec: ${widget.budgetCalories} kcal',
                                style: AppTheme.font(
                                  fontSize: 10,
                                  color: Colors.white38,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          HugeIcon(
                            icon: _isExpanded
                                ? HugeIcons.strokeRoundedArrowUp01
                                : HugeIcons.strokeRoundedArrowDown01,
                            color: Colors.white54,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOverBudget
                            ? Colors.redAccent
                            : const Color(0xFF00F0FF),
                      ),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (_isExpanded) ...[
            const Divider(height: 1, color: Colors.white10),
            if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedDish01,
                        size: 34,
                        color: Colors.white24,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${LocaleService.tr('no_food_logged')} • ${widget.title}',
                        style: AppTheme.font(
                          fontSize: 12,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: Colors.white10),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final timeStr =
                      "${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}";

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        if (item.imagePath != null &&
                            File(item.imagePath!).existsSync())
                          Container(
                            width: 44,
                            height: 44,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                image: FileImage(File(item.imagePath!)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 44,
                            height: 44,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const HugeIcon(
                              icon: HugeIcons.strokeRoundedDish01,
                              color: Colors.white54,
                              size: 20,
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: AppTheme.font(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$timeStr • P: ${item.protein}g | C: ${item.carbs}g | F: ${item.fat}g',
                                style: AppTheme.font(
                                  fontSize: 11,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '+${item.calories} kcal',
                          style: AppTheme.font(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF00F0FF),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: Icon(
                            _favoriteNames.contains(item.name.trim().toLowerCase())
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _favoriteNames.contains(item.name.trim().toLowerCase())
                                ? const Color(0xFFFF2A6D)
                                : Colors.white38,
                            size: 18,
                          ),
                          onPressed: () async {
                            AppHaptics.light();
                            final isFav = _favoriteNames.contains(item.name.trim().toLowerCase());
                            if (isFav) {
                              final existing = await NutritionRepository.instance.getFavoriteFoodByName(item.name);
                              if (existing != null) {
                                await NutritionRepository.instance.deleteFavoriteFood(existing.id);
                              }
                            } else {
                              final fav = FavoriteFood(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                name: item.name,
                                calories: item.calories,
                                protein: item.protein,
                                carbs: item.carbs,
                                fat: item.fat,
                                imagePath: item.imagePath,
                                createdAt: DateTime.now(),
                              );
                              await NutritionRepository.instance.addFavoriteFood(fav);
                            }
                            await _loadMealItems();
                          },
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedDelete02,
                            color: Colors.white38,
                            size: 18,
                          ),
                          onPressed: () => _deleteItem(item.id, item.name),
                        ),
                      ],
                    ),
                  );
                },
              ),

            // Add Food Button with BouncingTap & Squircle
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              child: BouncingTap(
                onTap: _showAddFoodDialog,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: ShapeDecoration(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.06),
                    shape: const SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius.all(
                        SmoothRadius(cornerRadius: 14, cornerSmoothing: 0.6),
                      ),
                      side: BorderSide(
                        color: Color(0x5200F0FF),
                        width: 1.2,
                      ),
                    ),
                    shadows: [
                      BoxShadow(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.05),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 18, color: Color(0xFF00F0FF)),
                      const SizedBox(width: 6),
                      Text(
                        '${LocaleService.tr('add_food_btn')} • ${widget.title}',
                        style: AppTheme.font(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00F0FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
}

class _AddFoodModal extends StatefulWidget {
  final String mealType;
  final String mealTitle;
  final VoidCallback onAdded;

  const _AddFoodModal({
    required this.mealType,
    required this.mealTitle,
    required this.onAdded,
  });

  @override
  State<_AddFoodModal> createState() => _AddFoodModalState();
}

class _AddFoodModalState extends State<_AddFoodModal> {
  final TextEditingController _textController = TextEditingController();
  final SpeechService _speechService = SpeechService();
  final ImagePicker _picker = ImagePicker();

  bool _isListening = false;
  bool _isLoading = false;
  String _statusText = 'Type, speak, or take a photo of your meal';
  String? _errorMessage;

  // In-sheet Food Confirmation State
  FoodInfo? _recognizedFood;
  Uint8List? _imageBytes;
  String? _savedImagePath;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _calController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();

  // Portion by Grams State
  int _inputMode = 0; // 0: Gram Portion Mode (Default), 1: Freeform / Mic / Photo
  final TextEditingController _riceGramsController = TextEditingController(text: '150');
  final TextEditingController _meatGramsController = TextEditingController(text: '150');
  final TextEditingController _vegGramsController = TextEditingController(text: '100');
  final TextEditingController _notesController = TextEditingController();
  String _selectedMeatType = 'gà';

  static const List<Map<String, dynamic>> _meatOptions = [
    {'id': 'gà', 'label_key': 'meat_chicken', 'icon': HugeIcons.strokeRoundedChickenThighs},
    {'id': 'bò', 'label_key': 'meat_beef', 'icon': HugeIcons.strokeRoundedSteak},
    {'id': 'lợn', 'label_key': 'meat_pork', 'icon': HugeIcons.strokeRoundedSteak},
    {'id': 'cá', 'label_key': 'meat_fish', 'icon': HugeIcons.strokeRoundedFishFood},
    {'id': 'tôm', 'label_key': 'meat_shrimp', 'icon': HugeIcons.strokeRoundedShrimp},
    {'id': 'trứng', 'label_key': 'meat_egg', 'icon': HugeIcons.strokeRoundedEgg},
    {'id': 'đậu', 'label_key': 'meat_tofu', 'icon': HugeIcons.strokeRoundedCheese},
    {'id': 'none', 'label_key': 'meat_none', 'icon': HugeIcons.strokeRoundedCancel01},
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    await _speechService.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted && _isListening) {
            setState(() {
              _isListening = false;
              _statusText = 'Voice recorded! Ready to analyze.';
            });
          }
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isListening = false;
            _statusText = 'Speech error: $err';
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _speechService.stopListening();
    _textController.dispose();
    _riceGramsController.dispose();
    _meatGramsController.dispose();
    _vegGramsController.dispose();
    _notesController.dispose();
    _nameController.dispose();
    _calController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _toggleSpeech() async {
    if (_isListening) {
      await _speechService.stopListening();
      setState(() {
        _isListening = false;
      });
    } else {
      setState(() {
        _isListening = true;
        _statusText = 'Listening to meal description...';
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
  }

  void _resetRecognizedFood() {
    setState(() {
      _recognizedFood = null;
      _imageBytes = null;
      _savedImagePath = null;
      _errorMessage = null;
      _isLoading = false;
      _statusText = 'Type, speak, or take a photo of your meal';
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _statusText = 'Gemini AI đang phân tích món ăn...';
      });

      // Always read bytes directly from XFile for cross-platform reliability
      final bytes = await pickedFile.readAsBytes();
      final foodInfo = await GeminiService.analyzeFoodImage(bytes);

      if (!mounted) return;

      if (foodInfo != null &&
          !foodInfo.name.toLowerCase().contains('no food') &&
          foodInfo.calories > 0) {
        setState(() {
          _isLoading = false;
          _recognizedFood = foodInfo;
          _imageBytes = bytes;
          _savedImagePath = pickedFile.path;
          _nameController.text = foodInfo.name;
          _calController.text = foodInfo.calories.toString();
          _proteinController.text = foodInfo.protein.toString();
          _carbsController.text = foodInfo.carbs.toString();
          _fatController.text = foodInfo.fat.toString();
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Gemini AI chưa nhận diện được món trong ảnh. Bạn có thể tự nhập tên món ăn và số calo bên dưới:';
          _recognizedFood = FoodInfo(
            name: '',
            calories: 300,
            protein: 20,
            carbs: 30,
            fat: 10,
          );
          _imageBytes = bytes;
          _savedImagePath = pickedFile.path;
          _nameController.text = '';
          _calController.text = '300';
          _proteinController.text = '20';
          _carbsController.text = '30';
          _fatController.text = '10';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sự cố khi quét ảnh ($e). Bạn có thể tự nhập món ăn bên dưới.';
          _recognizedFood = FoodInfo(name: '', calories: 0, protein: 0, carbs: 0, fat: 0);
        });
      }
    }
  }

  Future<void> _analyzeText() async {
    final query = _textController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusText = 'Gemini AI đang tính toán calo & macro...';
    });

    try {
      final foodInfo = await GeminiService.analyzeFood(query);
      if (!mounted) return;

      if (foodInfo != null) {
        setState(() {
          _isLoading = false;
          _recognizedFood = foodInfo;
          _imageBytes = null;
          _savedImagePath = null;
          _nameController.text = foodInfo.name;
          _calController.text = foodInfo.calories.toString();
          _proteinController.text = foodInfo.protein.toString();
          _carbsController.text = foodInfo.carbs.toString();
          _fatController.text = foodInfo.fat.toString();
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không thể tính toán cho "$query". Bạn hãy tự điền thông tin:';
          _recognizedFood = FoodInfo(name: query, calories: 250, protein: 15, carbs: 30, fat: 8);
          _nameController.text = query;
          _calController.text = '250';
          _proteinController.text = '15';
          _carbsController.text = '30';
          _fatController.text = '8';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Lỗi kết nối ($e). Bạn có thể tự điền calo:';
          _recognizedFood = FoodInfo(name: query, calories: 250, protein: 15, carbs: 30, fat: 8);
          _nameController.text = query;
          _calController.text = '250';
        });
      }
    }
  }

  Future<void> _analyzePortion() async {
    final riceGrams = int.tryParse(_riceGramsController.text.trim()) ?? 0;
    final meatGrams = int.tryParse(_meatGramsController.text.trim()) ?? 0;
    final vegGrams = int.tryParse(_vegGramsController.text.trim()) ?? 0;
    final notes = _notesController.text.trim();

    if (riceGrams <= 0 && meatGrams <= 0 && vegGrams <= 0) {
      setState(() {
        _errorMessage = LocaleService.tr('portion_error_empty');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusText = LocaleService.tr('analyzing_portion_cal');
    });

    try {
      final isVi = LocaleService.isVietnamese;
      final foodInfo = await GeminiService.analyzePortionedMeal(
        riceGrams: riceGrams,
        meatType: _selectedMeatType,
        meatGrams: _selectedMeatType == 'none' ? 0 : meatGrams,
        vegGrams: vegGrams,
        notes: notes.isNotEmpty ? notes : null,
        isVietnamese: isVi,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _recognizedFood = foodInfo;
        _imageBytes = null;
        _savedImagePath = null;
        _nameController.text = foodInfo.name;
        _calController.text = foodInfo.calories.toString();
        _proteinController.text = foodInfo.protein.toString();
        _carbsController.text = foodInfo.carbs.toString();
        _fatController.text = foodInfo.fat.toString();
      });
    } catch (e) {
      if (mounted) {
        final offlineInfo = GeminiService.calculatePortionedMealOffline(
          riceGrams: riceGrams,
          meatType: _selectedMeatType,
          meatGrams: _selectedMeatType == 'none' ? 0 : meatGrams,
          vegGrams: vegGrams,
          notes: notes.isNotEmpty ? notes : null,
          isVietnamese: LocaleService.isVietnamese,
        );
        setState(() {
          _isLoading = false;
          _recognizedFood = offlineInfo;
          _imageBytes = null;
          _savedImagePath = null;
          _nameController.text = offlineInfo.name;
          _calController.text = offlineInfo.calories.toString();
          _proteinController.text = offlineInfo.protein.toString();
          _carbsController.text = offlineInfo.carbs.toString();
          _fatController.text = offlineInfo.fat.toString();
        });
      }
    }
  }

  Widget _buildQuickGramsChips(TextEditingController controller, List<int> values) {
    final currentVal = int.tryParse(controller.text) ?? -1;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: values.map((val) {
          final isSelected = currentVal == val;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: BouncingTap(
              onTap: () {
                setState(() {
                  controller.text = val.toString();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: ShapeDecoration(
                  color: isSelected
                      ? const Color(0xFF00F0FF).withValues(alpha: 0.22)
                      : const Color(0xFF22222A),
                  shape: SmoothRectangleBorder(
                    borderRadius: const SmoothBorderRadius.all(
                      SmoothRadius(cornerRadius: 10, cornerSmoothing: 0.6),
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF00F0FF)
                          : Colors.white12,
                      width: isSelected ? 1.4 : 1.0,
                    ),
                  ),
                ),
                child: Text(
                  '${val}g',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected ? const Color(0xFF00F0FF) : Colors.white70,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMeatChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _meatOptions.map((opt) {
          final isSelected = _selectedMeatType == opt['id'];
          final label = LocaleService.tr(opt['label_key']!);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: BouncingTap(
              onTap: () {
                setState(() {
                  _selectedMeatType = opt['id']!;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: ShapeDecoration(
                  color: isSelected
                      ? const Color(0xFF00F0FF).withValues(alpha: 0.2)
                      : const Color(0xFF22222A),
                  shape: SmoothRectangleBorder(
                    borderRadius: const SmoothBorderRadius.all(
                      SmoothRadius(cornerRadius: 12, cornerSmoothing: 0.6),
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF00F0FF)
                          : Colors.white12,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  shadows: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                      icon: opt['icon'] as List<List<dynamic>>,
                      size: 15,
                      color: isSelected ? const Color(0xFF00F0FF) : Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _saveRecognizedFood() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final finalFood = FoodInfo(
      name: name,
      calories: int.tryParse(_calController.text) ?? (_recognizedFood?.calories ?? 0),
      protein: int.tryParse(_proteinController.text) ?? (_recognizedFood?.protein ?? 0),
      carbs: int.tryParse(_carbsController.text) ?? (_recognizedFood?.carbs ?? 0),
      fat: int.tryParse(_fatController.text) ?? (_recognizedFood?.fat ?? 0),
    );

    await StorageService.logFoodItem(
      finalFood,
      mealType: widget.mealType,
      imagePath: _savedImagePath,
    );

    AppHaptics.success();

    if (mounted) {
      Navigator.pop(context);
      widget.onAdded();
    }
  }

  Widget _buildMacroField({
    required TextEditingController controller,
    required String label,
    required List<List<dynamic>> icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF22222A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          HugeIcon(icon: icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 2),
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 16,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF18181E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            const BottomSheetDragHandle(),
            const SizedBox(height: 6),

            if (_recognizedFood != null) ...[
              // Recognized Food confirmation view directly in bottom sheet
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const HugeIcon(icon: HugeIcons.strokeRoundedAiSparkles, color: Color(0xFF00F0FF), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        LocaleService.tr('confirm_food_title'),
                        style: AppTheme.font(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: Colors.white54, size: 20),
                    onPressed: _resetRecognizedFood,
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppTheme.font(fontSize: 12, color: Colors.amberAccent),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (_imageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    _imageBytes!,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: LocaleService.tr('food_name_field'),
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF22222A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildMacroField(
                      controller: _calController,
                      label: LocaleService.tr('calories_field'),
                      icon: HugeIcons.strokeRoundedFire,
                      color: Colors.orangeAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMacroField(
                      controller: _proteinController,
                      label: LocaleService.tr('protein_field'),
                      icon: HugeIcons.strokeRoundedSteak,
                      color: const Color(0xFFFF5252),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMacroField(
                      controller: _carbsController,
                      label: LocaleService.tr('carbs_field'),
                      icon: HugeIcons.strokeRoundedRiceBowl01,
                      color: const Color(0xFFFFB74D),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMacroField(
                      controller: _fatController,
                      label: LocaleService.tr('fat_field'),
                      icon: HugeIcons.strokeRoundedCheese,
                      color: const Color(0xFF69F0AE),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: BouncingTap(
                      onTap: _resetRecognizedFood,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        alignment: Alignment.center,
                        decoration: ShapeDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: const SmoothRectangleBorder(
                            borderRadius: SmoothBorderRadius.all(
                              SmoothRadius(cornerRadius: 14, cornerSmoothing: 0.6),
                            ),
                            side: BorderSide(color: Colors.white24),
                          ),
                        ),
                        child: Text(
                          LocaleService.tr('change_food_btn'),
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SquircleButton(
                      label: LocaleService.tr('save_to_meal_btn', args: {'meal': widget.mealTitle}),
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle01, size: 18, color: Colors.black),
                      onPressed: _saveRecognizedFood,
                      height: 48,
                      gradientColors: const [Color(0xFF00F0FF), Color(0xFF00B4D8)],
                      textColor: Colors.black,
                      glowColor: const Color(0xFF00F0FF),
                    ),
                  ),
                ],
              ),
            ] else if (_isLoading) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF22222E),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Color(0xFF00F0FF),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LocaleService.tr('gemini_scanning_food'),
                                style: AppTheme.font(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _statusText.isNotEmpty
                                    ? _statusText
                                    : LocaleService.tr('analyzing_portion_cal'),
                                style: AppTheme.font(
                                  fontSize: 12,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _resetRecognizedFood,
                        child: Text(LocaleService.tr('cancel_text'), style: const TextStyle(color: Colors.white54)),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Modal Title & Subtitle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocaleService.tr('log_meal_sheet_title', args: {'meal': widget.mealTitle}),
                          style: AppTheme.font(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _inputMode == 0
                              ? LocaleService.tr('portion_calc_sub')
                              : LocaleService.tr('log_meal_sheet_sub'),
                          style: AppTheme.font(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const HugeIcon(icon: HugeIcons.strokeRoundedInformationCircle, color: Colors.redAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTheme.font(fontSize: 12, color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Mode Tabs: [ Theo Định Lượng (Gam) | Tự Do / Mic / Ảnh ]
              Container(
                decoration: ShapeDecoration(
                  color: const Color(0xFF22222A),
                  shape: const SmoothRectangleBorder(
                    borderRadius: SmoothBorderRadius.all(
                      SmoothRadius(cornerRadius: 14, cornerSmoothing: 0.6),
                    ),
                    side: BorderSide(color: Colors.white10),
                  ),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: BouncingTap(
                        onTap: () => setState(() {
                          _inputMode = 0;
                          _errorMessage = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: ShapeDecoration(
                            color: _inputMode == 0
                                ? const Color(0xFF00F0FF).withValues(alpha: 0.2)
                                : Colors.transparent,
                            shape: SmoothRectangleBorder(
                              borderRadius: const SmoothBorderRadius.all(
                                SmoothRadius(cornerRadius: 10, cornerSmoothing: 0.6),
                              ),
                              side: _inputMode == 0
                                  ? const BorderSide(color: Color(0xFF00F0FF), width: 1.2)
                                  : BorderSide.none,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedBalanceScale,
                                size: 14,
                                color: _inputMode == 0 ? const Color(0xFF00F0FF) : Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                LocaleService.tr('input_mode_portion'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _inputMode == 0 ? FontWeight.w800 : FontWeight.w500,
                                  color: _inputMode == 0 ? const Color(0xFF00F0FF) : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: BouncingTap(
                        onTap: () => setState(() {
                          _inputMode = 1;
                          _errorMessage = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: ShapeDecoration(
                            color: _inputMode == 1
                                ? const Color(0xFF00F0FF).withValues(alpha: 0.2)
                                : Colors.transparent,
                            shape: SmoothRectangleBorder(
                              borderRadius: const SmoothBorderRadius.all(
                                SmoothRadius(cornerRadius: 10, cornerSmoothing: 0.6),
                              ),
                              side: _inputMode == 1
                                  ? const BorderSide(color: Color(0xFF00F0FF), width: 1.2)
                                  : BorderSide.none,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedMic01,
                                size: 14,
                                color: _inputMode == 1 ? const Color(0xFF00F0FF) : Colors.white60,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                LocaleService.tr('input_mode_freeform'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _inputMode == 1 ? FontWeight.w800 : FontWeight.w500,
                                  color: _inputMode == 1 ? const Color(0xFF00F0FF) : Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_inputMode == 0) ...[
                // --- PORTION-BASED MODE ---
                // 1. Cơm / Tinh bột
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const HugeIcon(icon: HugeIcons.strokeRoundedRiceBowl01, size: 16, color: Color(0xFF00F0FF)),
                        const SizedBox(width: 8),
                        Text(
                          LocaleService.tr('rice_grams_label'),
                          style: AppTheme.font(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 90,
                      height: 38,
                      child: TextField(
                        controller: _riceGramsController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          suffixText: 'g',
                          suffixStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          filled: true,
                          fillColor: const Color(0xFF22222A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _buildQuickGramsChips(_riceGramsController, [0, 100, 150, 200, 250]),
                const SizedBox(height: 14),

                // 2. Thịt / Đạm
                Row(
                  children: [
                    const HugeIcon(icon: HugeIcons.strokeRoundedSteak, size: 16, color: Color(0xFF00F0FF)),
                    const SizedBox(width: 8),
                    Text(
                      LocaleService.tr('meat_type_label'),
                      style: AppTheme.font(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildMeatChips(),
                if (_selectedMeatType != 'none') ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        LocaleService.tr('meat_grams_label'),
                        style: AppTheme.font(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        height: 38,
                        child: TextField(
                          controller: _meatGramsController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            suffixText: 'g',
                            suffixStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            filled: true,
                            fillColor: const Color(0xFF22222A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildQuickGramsChips(_meatGramsController, [50, 100, 150, 200, 250]),
                ],
                const SizedBox(height: 14),

                // 3. Rau xanh
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const HugeIcon(icon: HugeIcons.strokeRoundedCarrot, size: 16, color: Color(0xFF00F0FF)),
                        const SizedBox(width: 8),
                        Text(
                          LocaleService.tr('veg_grams_label'),
                          style: AppTheme.font(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 90,
                      height: 38,
                      child: TextField(
                        controller: _vegGramsController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          suffixText: 'g',
                          suffixStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          filled: true,
                          fillColor: const Color(0xFF22222A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _buildQuickGramsChips(_vegGramsController, [0, 50, 100, 150, 200]),
                const SizedBox(height: 14),

                // 4. Ghi chú thêm
                TextField(
                  controller: _notesController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(12),
                      child: HugeIcon(icon: HugeIcons.strokeRoundedEdit02, color: Colors.white38, size: 18),
                    ),
                    hintText: LocaleService.tr('cooking_notes_label'),
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF22222A),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Total weight summary banner
                Builder(
                  builder: (context) {
                    final r = int.tryParse(_riceGramsController.text) ?? 0;
                    final m = _selectedMeatType == 'none' ? 0 : (int.tryParse(_meatGramsController.text) ?? 0);
                    final v = int.tryParse(_vegGramsController.text) ?? 0;
                    final total = r + m + v;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const HugeIcon(icon: HugeIcons.strokeRoundedBalanceScale, color: Color(0xFF00F0FF), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                LocaleService.tr('total_weight_label', args: {'weight': '$total'}),
                                style: AppTheme.font(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '~${((r * 1.3) + (m * 2.0) + (v * 0.3)).round()} kcal est.',
                            style: AppTheme.font(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF00F0FF),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Primary CTA button
                SquircleButton(
                  label: LocaleService.tr('calculate_ai_macros_btn'),
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedAiSparkles, size: 18, color: Colors.black),
                  onPressed: _analyzePortion,
                  isFullWidth: true,
                  height: 52,
                  gradientColors: const [Color(0xFF00F0FF), Color(0xFF00B4D8)],
                  textColor: Colors.black,
                  glowColor: const Color(0xFF00F0FF),
                ),
              ] else ...[
                // --- FREEFORM / VOICE / PHOTO MODE ---
                // Existing Input Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: LocaleService.tr('food_example_hint'),
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF22222A),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Mic Button
                    BouncingTap(
                      onTap: _toggleSpeech,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: ShapeDecoration(
                          color: _isListening
                              ? Colors.redAccent
                              : const Color(0xFF22222A),
                          shape: SmoothRectangleBorder(
                            borderRadius: const SmoothBorderRadius.all(
                              SmoothRadius(cornerRadius: 14, cornerSmoothing: 0.6),
                            ),
                            side: BorderSide(
                              color: _isListening ? Colors.red : Colors.white12,
                            ),
                          ),
                        ),
                        child: Center(
                          child: HugeIcon(
                            icon: _isListening ? HugeIcons.strokeRoundedMic01 : HugeIcons.strokeRoundedMicOff01,
                            color: _isListening ? Colors.white : const Color(0xFF00F0FF),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action Buttons: AI Camera, Gallery, Analyze
                Row(
                  children: [
                    Expanded(
                      child: BouncingTap(
                        onTap: () => _pickImage(ImageSource.camera),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: ShapeDecoration(
                            color: const Color(0xFF00F0FF).withValues(alpha: 0.08),
                            shape: const SmoothRectangleBorder(
                              borderRadius: SmoothBorderRadius.all(
                                SmoothRadius(cornerRadius: 14, cornerSmoothing: 0.6),
                              ),
                              side: BorderSide(color: Color(0xFF00F0FF)),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const HugeIcon(icon: HugeIcons.strokeRoundedCamera01, size: 18, color: Color(0xFF00F0FF)),
                              const SizedBox(width: 6),
                              Text(
                                LocaleService.tr('camera_ai_btn'),
                                style: const TextStyle(
                                  color: Color(0xFF00F0FF),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: BouncingTap(
                        onTap: () => _pickImage(ImageSource.gallery),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: ShapeDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            shape: const SmoothRectangleBorder(
                              borderRadius: SmoothBorderRadius.all(
                                SmoothRadius(cornerRadius: 14, cornerSmoothing: 0.6),
                              ),
                              side: BorderSide(color: Colors.white24),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const HugeIcon(icon: HugeIcons.strokeRoundedImage01, size: 18, color: Colors.white70),
                              const SizedBox(width: 6),
                              Text(
                                LocaleService.tr('gallery_btn'),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SquircleButton(
                      label: LocaleService.tr('add_btn'),
                      onPressed: _analyzeText,
                      isFullWidth: false,
                      height: 44,
                      gradientColors: const [Color(0xFF00F0FF), Color(0xFF00B4D8)],
                      textColor: Colors.black,
                      glowColor: const Color(0xFF00F0FF),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
