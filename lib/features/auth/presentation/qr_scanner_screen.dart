import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:oummi3/core/theme/app_theme.dart';
import 'package:oummi3/core/widgets/oumi_widgets.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Scanner View
          MobileScanner(
            controller: MobileScannerController(
              facing: CameraFacing.back,
              torchEnabled: false,
            ),
            onDetect: (capture) {
              if (_isScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                setState(() => _isScanned = true);
                final code = barcodes.first.rawValue ?? '';
                _handleScannedCode(context, code);
              }
            },
          ),

          // Overlay Figma Style
          _buildScannerOverlay(context),

          // Header with Back Button
          Positioned(
            top: 60,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => context.pop(),
            ),
          ),

          // Instruction Text
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Alignez le code QR dans le cadre',
                  style: OumiTypography.label.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth * 0.7;
        return Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border.all(color: OumiColors.blue, width: 3),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                // Corner decorators or scanning line animation could be added here
                if (_isScanned)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleScannedCode(BuildContext context, String code) {
    // Logic to identify if it's a consultation validation or a health card access
    // For now, redirect to a validation summary screen
    context.push('/dashboard/doctor/validate-code', extra: code);
  }
}
