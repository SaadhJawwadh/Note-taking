import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'package:gal/gal.dart';
import '../services/ffmpeg_service.dart';
import '../data/settings_provider.dart';

class FileConverterScreen extends StatefulWidget {
  final List<String>? initialFilePaths;
  const FileConverterScreen({super.key, this.initialFilePaths});

  @override
  State<FileConverterScreen> createState() => _FileConverterScreenState();
}

class _FileConverterScreenState extends State<FileConverterScreen> {
  bool _isProcessing = false;
  double _progress = 0.0;
  List<ConversionResult> _results = [];
  List<String> _selectedFilePaths = [];
  int _currentIndex = 0;
  String _statusMessage = 'Share or pick media files to compress';

  @override
  void initState() {
    super.initState();
    if (widget.initialFilePaths != null && widget.initialFilePaths!.isNotEmpty) {
      _selectedFilePaths = widget.initialFilePaths!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPresetSheet();
      });
    }
  }

  void _pickAndConvertFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );

    if (result != null && result.paths.isNotEmpty) {
      setState(() {
        _selectedFilePaths = result.paths.whereType<String>().toList();
        _results = [];
      });
      _showPresetSheet();
    }
  }

  void _showPresetSheet() {
    if (_selectedFilePaths.isEmpty) return;
    
    final service = FfmpegService.instance;
    // For multiple files, we'll use a common preset or show the first one's presets
    final firstPath = _selectedFilePaths.first;
    final presets = service.presetsForFile(firstPath);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFilePaths.length > 1
                            ? 'Batch Compress & Share'
                            : 'Compress & Share',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedFilePaths.length > 1
                            ? '${_selectedFilePaths.length} files selected'
                            : '${p.basename(firstPath)}  •  ${ConversionResult.formatBytes(File(firstPath).lengthSync())}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...presets.map((preset) {
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 24.0),
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Text(preset.icon),
                    ),
                    title: Text(preset.label),
                    subtitle: Text(
                      preset.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _executeBatchConversion(preset);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _executeBatchConversion(ConversionPreset preset) async {
    setState(() {
      _isProcessing = true;
      _results = [];
      _currentIndex = 0;
      _statusMessage = 'Starting batch conversion…';
    });

    final settings = Provider.of<SettingsProvider>(context, listen: false);

    for (int i = 0; i < _selectedFilePaths.length; i++) {
      if (!mounted || !_isProcessing) break;

      final inputPath = _selectedFilePaths[i];
      setState(() {
        _currentIndex = i;
        _progress = 0.0;
        _statusMessage = 'Compressing ${i + 1}/${_selectedFilePaths.length}…';
      });

      final result = await FfmpegService.instance.convertFile(
        inputPath: inputPath,
        preset: preset,
        settings: settings,
        onProgress: settings.isConverterLite ? null : (p) {
          if (mounted) {
            setState(() => _progress = p.clamp(0.0, 1.0));
          }
        },
      );

      if (result != null) {
        setState(() {
          _results.add(result);
        });
      }
    }

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _statusMessage = _results.isNotEmpty 
          ? 'Done! ${_results.length} files ready.' 
          : 'Conversion failed.';
    });

    if (_results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Batch compression failed.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _shareResults() {
    if (_results.isEmpty) return;
    // ignore: deprecated_member_use
    Share.shareXFiles(_results.map((r) => XFile(r.outputPath)).toList());
  }

  void _cancelConversion() {
    FfmpegService.instance.cancelAll();
    setState(() {
      _isProcessing = false;
      _statusMessage = 'Cancelled.';
    });
  }

  Future<void> _saveToGallery(String path) async {
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gallery access denied')),
            );
          }
          return;
        }
      }

      final ext = p.extension(path).toLowerCase();
      final isImage = ['.jpg', '.jpeg', '.png', '.webp', '.bmp'].contains(ext);
      final isVideo = ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.flv'].contains(ext);
      final isGif = ext == '.gif';

      if (isImage || isGif) {
        await Gal.putImage(path);
      } else if (isVideo) {
        await Gal.putVideo(path);
      } else {
        // Fallback or generic error if not image/video
        throw 'Unsupported media type for gallery saving';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to Gallery!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save to gallery: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Converter'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // ── Hero Icon ──
              Container(
                padding: const EdgeInsets.all(28.0),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  settings.isConverterLite ? Icons.bolt_rounded : Icons.compress_rounded,
                  size: 56,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                settings.isConverterLite ? 'Lite Compressor' : 'FFmpeg Engine',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _statusMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // ── Progress / Action ──
              if (_isProcessing) ...[
                Text(
                  'Processing ${_currentIndex + 1} of ${_selectedFilePaths.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    minHeight: 8,
                    backgroundColor: cs.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _progress > 0
                      ? '${(_progress * 100).toInt()}%'
                      : 'Working…',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _cancelConversion,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Stop All'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.error,
                    side: BorderSide(color: cs.error),
                  ),
                ),
              ] else ...[
                FilledButton.icon(
                  onPressed: _pickAndConvertFiles,
                  icon: const Icon(Icons.add_to_photos_rounded),
                  label: const Text('Pick Files'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                ),
                if (_selectedFilePaths.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _showPresetSheet,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Restart with Different Preset'),
                  ),
                ],
              ],

              // ── Result Section ──
              if (_results.isNotEmpty) ...[
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Results (${_results.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_results.length > 1)
                      FilledButton.icon(
                        onPressed: _shareResults,
                        icon: const Icon(Icons.reply_all_rounded),
                        label: const Text('Share All'),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                ..._results.map((res) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _ResultCard(
                    result: res,
                    // ignore: deprecated_member_use
                    onShare: () => Share.shareXFiles([XFile(res.outputPath)]),
                    onSave: () => _saveToGallery(res.outputPath),
                  ),
                )),
              ],

              const SizedBox(height: 32),

              // ── Info Chip ──
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 20, color: cs.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Share any video, image, or audio directly from your Gallery — Note Book will appear in the share sheet.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────
//  Result Card Widget
// ─────────────────────────────────────
class _ResultCard extends StatelessWidget {
  final ConversionResult result;
  final VoidCallback onShare;
  final VoidCallback onSave;

  const _ResultCard({
    required this.result,
    required this.onShare,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSmaller = result.compressedSizeBytes < result.originalSizeBytes;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: isSmaller ? Colors.green : cs.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isSmaller
                        ? 'Compressed ${result.reductionPercent.toStringAsFixed(1)}% smaller'
                        : 'Conversion Complete',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _SizeChip(
                  label: 'Original',
                  size: result.originalSizeFormatted,
                  color: cs.secondaryContainer,
                  textColor: cs.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 16, color: cs.outline),
                const SizedBox(width: 8),
                _SizeChip(
                  label: 'Compressed',
                  size: result.compressedSizeFormatted,
                  color: isSmaller
                      ? Colors.green.withValues(alpha: 0.15)
                      : cs.tertiaryContainer,
                  textColor: isSmaller ? Colors.green : cs.onTertiaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Save'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  final String label;
  final String size;
  final Color color;
  final Color textColor;

  const _SizeChip({
    required this.label,
    required this.size,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: textColor.withValues(alpha: 0.7),
                  ),
            ),
            Text(
              size,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
