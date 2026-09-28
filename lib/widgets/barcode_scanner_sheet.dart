import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/open_food_facts_service.dart';
import '../services/storage_service.dart';
import '../services/gemini_service.dart';
import '../theme.dart';

/// Modal bottom sheet quét mã vạch dinh dưỡng bằng Camera hoặc nhập mã thủ công
class BarcodeScannerSheet extends StatefulWidget {
  final Function(FoodInfo food, String mealType)? onFoodLogged;

  const BarcodeScannerSheet({
    super.key,
    this.onFoodLogged,
  });

  static Future<void> show(
    BuildContext context, {
    Function(FoodInfo food, String mealType)? onFoodLogged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BarcodeScannerSheet(onFoodLogged: onFoodLogged),
    );
  }

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet>
    with SingleTickerProviderStateMixin {
  late MobileScannerController _scannerController;
  late AnimationController _animController;
  late Animation<double> _laserAnimation;

  bool _isProcessing = false;
  ScannedFoodProduct? _scannedProduct;
  String _errorMessage = '';
  String _selectedMealType = 'Breakfast';
  double _portionMultiplier = 1.0;

  final TextEditingController _manualCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedMealType = FoodLogEntry.inferMealType(DateTime.now());

    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _animController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeDetected(String rawCode) async {
    if (_isProcessing || _scannedProduct != null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = '';
    });

    try {
      final product =
          await OpenFoodFactsService.instance.fetchProductByBarcode(rawCode);

      if (!mounted) return;

      if (product != null) {
        setState(() {
          _scannedProduct = product;
          _isProcessing = false;
        });
      } else {
        setState(() {
          _isProcessing = false;
          _errorMessage =
              'Không tìm thấy sản phẩm với mã "$rawCode" trên Open Food Facts.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Đã có lỗi xảy ra khi tra cứu: $e';
      });
    }
  }

  Future<void> _saveScannedFood() async {
    if (_scannedProduct == null) return;

    final scaled = _scannedProduct!.scale(_portionMultiplier);
    final foodInfo = FoodInfo(
      name: scaled.name,
      calories: scaled.calories,
      protein: scaled.protein,
      carbs: scaled.carbs,
      fat: scaled.fat,
    );

    await StorageService.logFoodItem(
      foodInfo,
      timestamp: DateTime.now(),
      mealType: _selectedMealType,
      imagePath: scaled.imageUrl,
    );

    if (widget.onFoodLogged != null) {
      widget.onFoodLogged!(foodInfo, _selectedMealType);
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            'Đã thêm "${scaled.name}" (${scaled.calories} kcal) vào $_selectedMealType!',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  void _showManualBarcodeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C24),
        title: const Text(
          'Nhập mã vạch thủ công',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: TextField(
          controller: _manualCodeController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Ví dụ: 8934563138164',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final code = _manualCodeController.text.trim();
              Navigator.of(ctx).pop();
              if (code.isNotEmpty) {
                _handleBarcodeDetected(code);
              }
            },
            child: const Text('Tra cứu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final sheetHeight = mediaQuery.size.height * 0.85;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Color(0xFF101018),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: AppColors.info,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Quét mã vạch thực phẩm',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          Expanded(
            child: _scannedProduct != null
                ? _buildResultView()
                : _buildScannerView(),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Camera View
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final code = barcode.rawValue;
                if (code != null && code.isNotEmpty) {
                  _handleBarcodeDetected(code);
                  break;
                }
              }
            },
          ),
        ),

        // Darkened Mask with Viewfinder Cutout
        LayoutBuilder(
          builder: (context, constraints) {
            final scanAreaSize = constraints.maxWidth * 0.72;
            return Container(
              decoration: ShapeDecoration(
                shape: QrScannerOverlayShape(
                  borderColor: AppColors.info,
                  borderRadius: 16,
                  borderLength: 32,
                  borderWidth: 4,
                  cutOutSize: scanAreaSize,
                ),
              ),
            );
          },
        ),

        // Animated Scanning Laser Line
        AnimatedBuilder(
          animation: _laserAnimation,
          builder: (context, child) {
            return Positioned(
              top: (MediaQuery.of(context).size.height * 0.4) *
                  _laserAnimation.value,
              left: 50,
              right: 50,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.info,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.info.withValues(alpha: 0.8),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Loading Overlay
        if (_isProcessing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.info),
                  SizedBox(height: 16),
                  Text(
                    'Đang tra cứu cơ sở dữ liệu dinh dưỡng...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Top Toolbar (Torch & Camera Switch)
        Positioned(
          top: 16,
          right: 20,
          child: Row(
            children: [
              IconButton.filledTonal(
                onPressed: () => _scannerController.toggleTorch(),
                icon: const Icon(Icons.flash_on_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: () => _scannerController.switchCamera(),
                icon: const Icon(Icons.flip_camera_ios_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Bottom Bar (Instructions & Manual Input)
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: Column(
            children: [
              if (_errorMessage.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E2C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Colors.white12),
                  ),
                ),
                onPressed: _showManualBarcodeDialog,
                icon: const Icon(Icons.keyboard_alt_outlined, size: 18),
                label: const Text('Nhập mã vạch bằng tay'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    final product = _scannedProduct!;
    final scaled = product.scale(_portionMultiplier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A26),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.imageUrl != null &&
                    product.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _fallbackImage(),
                    ),
                  )
                else
                  _fallbackImage(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (product.brand != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          product.brand!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        'Mã vạch: ${product.barcode}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.info,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Portion / Serving Multiplier Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Khẩu phần tiêu thụ:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              Row(
                children: [0.5, 1.0, 1.5, 2.0].map((val) {
                  final selected = _portionMultiplier == val;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text('${val}x'),
                      selected: selected,
                      selectedColor: AppColors.info,
                      backgroundColor: const Color(0xFF1E1E28),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: selected ? Colors.black : Colors.white70,
                      ),
                      onSelected: (_) {
                        setState(() => _portionMultiplier = val);
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Nutrition Grid
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF14141E),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Năng lượng tổng:',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      '${scaled.calories} kcal',
                      style: const TextStyle(
                        color: AppColors.info,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _macroChip('Đạm', '${scaled.protein}g', AppColors.protein),
                    const SizedBox(width: 8),
                    _macroChip('Carbs', '${scaled.carbs}g', AppColors.carbs),
                    const SizedBox(width: 8),
                    _macroChip('Chất béo', '${scaled.fat}g', AppColors.fat),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Meal Type Selector
          const Text(
            'Chọn bữa ăn:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((type) {
                final selected = _selectedMealType == type;
                String display;
                switch (type) {
                  case 'Breakfast':
                    display = 'Bữa Sáng';
                    break;
                  case 'Lunch':
                    display = 'Bữa Trưa';
                    break;
                  case 'Dinner':
                    display = 'Bữa Tối';
                    break;
                  case 'Snack':
                  default:
                    display = 'Bữa Phụ';
                    break;
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(display),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    backgroundColor: const Color(0xFF1E1E28),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.white60,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedMealType = type);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _scannedProduct = null;
                      _errorMessage = '';
                      _portionMultiplier = 1.0;
                    });
                  },
                  child: const Text(
                    'Quét lại',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _saveScannedFood,
                  icon: const Icon(Icons.add_task_rounded, color: Colors.white),
                  label: const Text(
                    'Thêm vào nhật ký',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.fastfood_rounded,
        color: Colors.white38,
        size: 36,
      ),
    );
  }

  Widget _macroChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom shape overlay for the camera viewfinder
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.cyan,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final top = (height - cutOutSize) / 2;
    final left = (width - cutOutSize) / 2;

    final paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    // Draw dark background mask around cutout
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(left, top, cutOutSize, cutOutSize),
              Radius.circular(borderRadius),
            ),
          ),
      ),
      paint,
    );

    // Draw borders/corners
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + borderLength)
        ..lineTo(left, top + borderRadius)
        ..quadraticBezierTo(left, top, left + borderRadius, top)
        ..lineTo(left + borderLength, top),
      borderPaint,
    );

    // Top Right
    final right = left + cutOutSize;
    canvas.drawPath(
      Path()
        ..moveTo(right - borderLength, top)
        ..lineTo(right - borderRadius, top)
        ..quadraticBezierTo(right, top, right, top + borderRadius)
        ..lineTo(right, top + borderLength),
      borderPaint,
    );

    // Bottom Left
    final bottom = top + cutOutSize;
    canvas.drawPath(
      Path()
        ..moveTo(left, bottom - borderLength)
        ..lineTo(left, bottom - borderRadius)
        ..quadraticBezierTo(left, bottom, left + borderRadius, bottom)
        ..lineTo(left + borderLength, bottom),
      borderPaint,
    );

    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(right - borderLength, bottom)
        ..lineTo(right - borderRadius, bottom)
        ..quadraticBezierTo(right, bottom, right, bottom - borderRadius)
        ..lineTo(right, bottom - borderLength),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) => QrScannerOverlayShape(
        borderColor: borderColor,
        borderWidth: borderWidth,
        overlayColor: overlayColor,
      );
}
