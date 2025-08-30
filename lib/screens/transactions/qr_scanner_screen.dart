import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final ValueNotifier<bool> _isTorchOn = ValueNotifier(false);
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    _isTorchOn.dispose();
    super.dispose();
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_isProcessing || !mounted) return;

    final barcode = capture.barcodes.firstOrNull;
    final code = barcode?.rawValue;

    if (code != null && code.isNotEmpty) {
      setState(() {
        _isProcessing = true;
      });
      HapticFeedback.lightImpact();

      _scannerController.stop().then((_) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop(code);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(Offset.zero),
      width: 250,
      height: 250,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('РќР°РІРµРґС–С‚СЊ РЅР° QR-РєРѕРґ'),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _isTorchOn,
            builder: (context, isTorchOn, child) {
              return IconButton(
                icon: Icon(isTorchOn ? Icons.flash_on : Icons.flash_off),
                tooltip: 'Р›С–С…С‚Р°СЂРёРє',
                onPressed: () async {
                  await _scannerController.toggleTorch();
                  _isTorchOn.value = !_isTorchOn.value;
                },
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _scannerController,
            scanWindow: scanWindow,
            onDetect: _handleDetection,
          ),
          CustomPaint(
            painter: ScannerOverlayPainter(scanWindow),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  ScannerOverlayPainter(this.scanWindow);
  final Rect scanWindow;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(scanWindow, const Radius.circular(12)),
      );
    final backgroundPaint = Paint()..color = Colors.black.withAlpha(128);

    final backgroundPathWithoutCutout = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );
    canvas.drawPath(backgroundPathWithoutCutout, backgroundPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanWindow, const Radius.circular(12)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
