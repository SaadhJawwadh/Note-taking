import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_layout.dart';
import '../../../../core/ui/expressive_sliver_app_bar.dart';
import '../../../../screens/app_lock_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    AppLockScreen.ignoreNextResumeLock();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_hasScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? rawValue = barcode.rawValue;
                if (rawValue != null && rawValue.isNotEmpty) {
                  _hasScanned = true;
                  Navigator.pop(context, rawValue);
                  break;
                }
              }
            },
          ),
          const CustomScrollView(
            slivers: [
              ExpressiveSliverAppBar(
                titleText: 'Scan Pair QR Code',
                showBackButton: true,
              ),
            ],
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(AppLayout.radiusL),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
