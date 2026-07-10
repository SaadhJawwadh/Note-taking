import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'package:gal/gal.dart';
import '../services/ffmpeg_service.dart';
import '../services/ffmpeg_install_service.dart';
import '../data/settings_provider.dart';
import 'app_lock_screen.dart';
import 'package:flutter/services.dart';

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

  void _showFormatPickerLocal({
    required BuildContext context,
    required String title,
    required List<String> options,
    required String currentValue,
    required Function(String) onSelected,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        title: Text('Select $title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) => RadioListTile<String>(
            title: Text(option.toUpperCase()),
            value: option,
            // ignore: deprecated_member_use
            groupValue: currentValue,
            // ignore: deprecated_member_use
            onChanged: (v) {
              onSelected(v!);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      builder: (context) {
        final installService = FfmpegInstallService.instance;
        return Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            final theme = Theme.of(context);
            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 8,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'File Converter Settings',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      SwitchListTile(
                        title: const Text('Converter Lite Mode'),
                        subtitle: const Text('Use native tools instead of FFmpeg (Fast, limited formats)'),
                        value: settings.isConverterLite,
                        onChanged: (val) => settings.setIsConverterLite(val),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Keep Metadata'),
                        subtitle: const Text('Maintain EXIF and device info in compressed files'),
                        value: settings.keepMetadata,
                        onChanged: (val) => settings.setKeepMetadata(val),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.video_collection_outlined),
                        title: const Text('Preferred Video Format'),
                        subtitle: Text(settings.preferredVideoFormat.toUpperCase()),
                        onTap: () => _showFormatPickerLocal(
                          context: context,
                          title: 'Video Format',
                          options: ['mp4', 'mkv', 'gif'],
                          currentValue: settings.preferredVideoFormat,
                          onSelected: settings.setPreferredVideoFormat,
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.image_outlined),
                        title: const Text('Preferred Image Format'),
                        subtitle: Text(settings.preferredImageFormat.toUpperCase()),
                        onTap: () => _showFormatPickerLocal(
                          context: context,
                          title: 'Image Format',
                          options: ['jpg', 'png', 'webp'],
                          currentValue: settings.preferredImageFormat,
                          onSelected: settings.setPreferredImageFormat,
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.photo_size_select_large_outlined),
                        title: const Text('Video Resolution Limit'),
                        subtitle: Text(settings.videoResolutionLimit),
                        onTap: () => _showFormatPickerLocal(
                          context: context,
                          title: 'Resolution Limit',
                          options: ['Original', '1080p', '720p', '480p'],
                          currentValue: settings.videoResolutionLimit,
                          onSelected: settings.setVideoResolutionLimit,
                        ),
                      ),
                      if (!settings.isConverterLite) ...[
                        const Divider(),
                        ListenableBuilder(
                          listenable: installService,
                          builder: (context, _) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.download_for_offline_outlined),
                              title: Text(settings.isFfmpegInstalled ? 'Engine Installed' : 'Install FFmpeg Engine'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(settings.isFfmpegInstalled 
                                    ? 'Engine binaries are ready (approx. 45MB)' 
                                    : 'Download engine for high-quality compression (approx. 45MB)'),
                                  if (installService.isDownloading) ...[
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(value: installService.downloadProgress),
                                  ],
                                ],
                              ),
                              trailing: installService.isDownloading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                : IconButton(
                                    icon: Icon(settings.isFfmpegInstalled ? Icons.delete_outline : Icons.download_rounded),
                                    onPressed: () async {
                                      if (settings.isFfmpegInstalled) {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Uninstall Engine?'),
                                            content: const Text('This will remove the FFmpeg binaries from your device to save space.'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Uninstall')),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await installService.uninstallEngine(settings);
                                        }
                                      } else {
                                        await installService.installEngine(settings);
                                      }
                                    },
                                  ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialFilePaths != null && widget.initialFilePaths!.isNotEmpty) {
      _selectedFilePaths = widget.initialFilePaths!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        if (settings.isFfmpegInstalled) {
          _showPresetSheet(context);
        }
      });
    }
  }

  @override
  void dispose() {
    FfmpegService.instance.cancelAll();
    super.dispose();
  }

  void _pickAndConvertFiles() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    await HapticFeedback.lightImpact();
    if (!settings.isConverterLite && !settings.isFfmpegInstalled) {
       _showSetupDialog();
       return;
    }

    // Unlock session so we don't get locked out after returning from file picker
    AppLockScreen.unlockSession();
    AppLockScreen.ignoreNextResumeLock();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );

    if (!mounted) return;

    if (result != null && result.paths.isNotEmpty) {
      setState(() {
        _selectedFilePaths = result.paths.whereType<String>().toList();
        _results = [];
      });
      _showPresetSheet(context);
    }
  }

  void _showSetupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final installService = FfmpegInstallService.instance;
        return Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return AlertDialog(
              title: const Text('FFmpeg Engine Required'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('High-performance compression requires the FFmpeg engine (approx. 45MB).'),
                  if (installService.isDownloading) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: installService.downloadProgress),
                    const SizedBox(height: 8),
                    const Text('Downloading…'),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                if (!installService.isDownloading)
                  FilledButton(
                    onPressed: () async {
                      await installService.installEngine(settings);
                      if (settings.isFfmpegInstalled && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Install Engine'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPresetSheet(BuildContext context) {
    if (_selectedFilePaths.isEmpty) return;
    
    final service = FfmpegService.instance;
    // For multiple files, we'll use a common preset or show the first one's presets
    final firstPath = _selectedFilePaths.first;
    final presets = service.presetsForFile(firstPath);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
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
        onProgress: (p) {
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

  void _shareResults() async {
    if (_results.isEmpty) return;
    await HapticFeedback.lightImpact();
    await SharePlus.instance.share(ShareParams(files: _results.map((r) => XFile(r.outputPath)).toList()));
  }

  void _cancelConversion() async {
    await HapticFeedback.mediumImpact();
    FfmpegService.instance.cancelAll();
    setState(() {
      _isProcessing = false;
      _statusMessage = 'Cancelled.';
    });
  }

  Future<void> _saveToGallery(String path) async {
    try {
      // Unlock session to avoid locking after permission dialog/intent return
      AppLockScreen.unlockSession();

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
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            floating: true,
            snap: true,
            toolbarHeight: 84,
            titleSpacing: 16,
            automaticallyImplyLeading: false,
            title: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: EdgeInsets.symmetric(horizontal: canPop ? 4 : 8),
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  if (canPop) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                  ] else ...[
                    const SizedBox(width: 16),
                  ],
                  Text(
                    'File Converter',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: 'Settings',
                      onPressed: () => _showSettingsSheet(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
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
                      Icons.compress_rounded,
                      size: 56,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'FFmpeg Engine',
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
                        onPressed: () => _showPresetSheet(context),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Restart with Different Preset'),
                      ),
                    ],
                  ],

                  // ── Result Section ──
                  if (_results.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    _SavingsDashboard(results: _results),
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
                            onShare: () async {
                              await HapticFeedback.lightImpact();
                              await SharePlus.instance.share(ShareParams(files: [XFile(res.outputPath)]));
                            },
                            onSave: () async {
                              await HapticFeedback.lightImpact();
                              await _saveToGallery(res.outputPath);
                            },
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
                            'Share any video, image, or audio directly from your Gallery — Everything App will appear in the share sheet.',
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
        ],
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

  void _showComparisonDialog(BuildContext context, ConversionResult result) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => _ImageComparisonDialog(result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSmaller = result.compressedSizeBytes < result.originalSizeBytes;
    
    final ext = p.extension(result.outputPath).toLowerCase();
    final isImage = ['.jpg', '.jpeg', '.png', '.webp', '.bmp'].contains(ext);

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
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
            if (isImage) ...[
              OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showComparisonDialog(context, result);
                },
                icon: const Icon(Icons.compare_rounded),
                label: const Text('Compare Quality'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
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

// ─────────────────────────────────────
//  Savings Dashboard Widget
// ─────────────────────────────────────
class _SavingsDashboard extends StatelessWidget {
  final List<ConversionResult> results;
  const _SavingsDashboard({required this.results});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    int totalOriginal = results.fold(0, (sum, r) => sum + r.originalSizeBytes);
    int totalCompressed = results.fold(0, (sum, r) => sum + r.compressedSizeBytes);
    int totalSaved = totalOriginal - totalCompressed;
    if (totalSaved < 0) totalSaved = 0;
    double savedPercent = totalOriginal > 0 ? (totalSaved / totalOriginal) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primaryContainer.withValues(alpha: 0.25),
            cs.secondaryContainer.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: cs.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Space Savings Dashboard',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Space Saved',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ConversionResult.formatBytes(totalSaved),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.primary,
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${savedPercent.toStringAsFixed(1)}% Saved',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: totalOriginal > 0 ? totalCompressed / totalOriginal : 0.0,
              minHeight: 10,
              backgroundColor: cs.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Original: ${ConversionResult.formatBytes(totalOriginal)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              Text(
                'Compressed: ${ConversionResult.formatBytes(totalCompressed)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────
//  Visual Image Comparison Dialog
// ─────────────────────────────────────
class _ImageComparisonDialog extends StatefulWidget {
  final ConversionResult result;
  const _ImageComparisonDialog({required this.result});

  @override
  State<_ImageComparisonDialog> createState() => _ImageComparisonDialogState();
}

class _ImageComparisonDialogState extends State<_ImageComparisonDialog> {
  double _sliderValue = 0.5;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Visual Comparison'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(
                  'Original (Left)  |  Compressed (Right)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final originalFile = File(widget.result.originalPath);
                        final compressedFile = File(widget.result.outputPath);
                        
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Compressed image (background)
                            Image.file(
                              compressedFile,
                              fit: BoxFit.contain,
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                            ),
                            // Original image (foreground, clipped)
                            ClipRect(
                              clipper: _SideBySideClipper(_sliderValue),
                              child: Image.file(
                                originalFile,
                                fit: BoxFit.contain,
                                width: constraints.maxWidth,
                                height: constraints.maxHeight,
                              ),
                            ),
                            // Sliding divider handle line
                            Positioned.fill(
                              child: FractionalTranslation(
                                translation: const Offset(-0.5, 0),
                                child: Align(
                                  alignment: Alignment(2.0 * _sliderValue - 1.0, 0.0),
                                  child: Container(
                                    width: 2,
                                    color: cs.primary,
                                    height: constraints.maxHeight,
                                  ),
                                ),
                              ),
                            ),
                            // Sliding divider handle drag circle
                            Positioned.fill(
                              child: FractionalTranslation(
                                translation: const Offset(-0.5, 0),
                                child: Align(
                                  alignment: Alignment(2.0 * _sliderValue - 1.0, 0.0),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onHorizontalDragUpdate: (details) {
                                      setState(() {
                                        _sliderValue = (_sliderValue + details.delta.dx / constraints.maxWidth).clamp(0.0, 1.0);
                                      });
                                    },
                                    child: CircleAvatar(
                                      backgroundColor: cs.primary,
                                      radius: 20,
                                      child: const Icon(Icons.unfold_more_rounded, color: Colors.white, size: 24),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              Container(
                color: cs.surfaceContainerLowest,
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Original: ${widget.result.originalSizeFormatted}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Compressed: ${widget.result.compressedSizeFormatted}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _sliderValue,
                      activeColor: cs.primary,
                      inactiveColor: cs.outlineVariant,
                      onChanged: (v) => setState(() => _sliderValue = v),
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

class _SideBySideClipper extends CustomClipper<Rect> {
  final double clipRatio;
  _SideBySideClipper(this.clipRatio);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * clipRatio, size.height);
  }

  @override
  bool shouldReclip(_SideBySideClipper oldClipper) => oldClipper.clipRatio != clipRatio;
}
