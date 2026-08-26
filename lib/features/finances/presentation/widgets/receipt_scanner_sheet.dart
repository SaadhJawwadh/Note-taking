import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_layout.dart';
import '../../../../core/ui/app_bottom_sheet.dart';
import '../../../../data/settings_provider.dart';
import '../../services/receipt_scanner_service.dart';

class ReceiptScannerSheet extends StatefulWidget {
  const ReceiptScannerSheet({super.key});

  static Future<Map<String, dynamic>?> show(BuildContext context) async {
    return await AppBottomSheet.show<Map<String, dynamic>>(
      context: context,
      title: 'Scan Physical Receipt',
      child: const ReceiptScannerSheet(),
    );
  }

  @override
  State<ReceiptScannerSheet> createState() => _ReceiptScannerSheetState();
}

class _ReceiptScannerSheetState extends State<ReceiptScannerSheet> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  
  String? _imagePath;
  bool _isScanning = false;
  ParsedReceiptResult? _scanResult;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  Future<void> _pickAndScan(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(source: source);
      if (file == null) return;

      if (!mounted) return;
      final settings = Provider.of<SettingsProvider>(context, listen: false);

      setState(() {
        _imagePath = file.path;
        _isScanning = true;
        _errorMessage = null;
      });

      final result = await ReceiptScannerService.instance.processReceiptImage(
        file.path,
        isAiActive: settings.isAiActive,
      );

      if (!mounted) return;

      setState(() {
        _isScanning = false;
        _scanResult = result;
        if (result != null) {
          if (result.merchantTitle != null && result.merchantTitle!.isNotEmpty) {
            _titleController.text = result.merchantTitle!;
          }
          if (result.totalAmount != null && result.totalAmount! > 0) {
            _totalController.text = result.totalAmount!.toStringAsFixed(2).replaceAll('.00', '');
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _errorMessage = 'Could not scan image: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppLayout.spaceM, vertical: AppLayout.spaceS),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_imagePath == null) ...[
            Text(
              'Capture or upload a physical bill receipt to automatically extract the total and store name offline.',
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppLayout.spaceL),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickAndScan(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppLayout.radiusM)),
                    ),
                  ),
                ),
                const SizedBox(width: AppLayout.spaceM),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickAndScan(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppLayout.radiusM)),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            if (_isScanning) ...[
              const SizedBox(height: AppLayout.spaceL),
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: AppLayout.spaceM),
                    Text(
                      'Analyzing receipt offline...',
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppLayout.spaceL),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppLayout.radiusS),
                    child: Image.file(
                      File(_imagePath!),
                      width: 68,
                      height: 84,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 68,
                        height: 84,
                        color: colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.receipt_long_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppLayout.spaceM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Receipt Scanned',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppLayout.spaceXS),
                        Text(
                          _scanResult?.totalAmount != null
                              ? 'Extracted Total: Rs. ${_scanResult!.totalAmount!.toStringAsFixed(2)}'
                              : 'Total not detected automatically. Please verify below.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _scanResult?.totalAmount != null ? Colors.green : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppLayout.spaceXS),
                        InkWell(
                          onTap: () => setState(() => _imagePath = null),
                          child: Text(
                            'Retake Photo',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppLayout.spaceM),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Merchant / Bill Title',
                  prefixIcon: Icon(Icons.store_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppLayout.spaceM),
              TextField(
                controller: _totalController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Total Bill Amount (Rs.)',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppLayout.spaceL),
              FilledButton.icon(
                onPressed: _applyScan,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Apply to Bill'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppLayout.radiusM)),
                ),
              ),
            ],
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: AppLayout.spaceS),
            Text(
              _errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppLayout.spaceS),
        ],
      ),
    );
  }

  void _applyScan() {
    final title = _titleController.text.trim();
    final total = double.tryParse(_totalController.text.trim());

    if (total == null || total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid bill amount.')),
      );
      return;
    }

    HapticFeedback.lightImpact();
    Navigator.of(context).pop({
      'title': title.isNotEmpty ? title : 'Scanned Receipt',
      'total': total,
      'imagePath': _imagePath,
    });
  }
}
