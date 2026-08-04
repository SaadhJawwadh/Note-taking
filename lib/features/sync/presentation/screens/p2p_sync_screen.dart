import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:note_taking_app/core/theme/app_layout.dart';
import 'package:note_taking_app/core/ui/app_card.dart';
import 'package:note_taking_app/core/ui/app_bottom_sheet.dart';
import 'package:note_taking_app/core/ui/app_chip.dart';
import 'package:note_taking_app/core/ui/app_dialog.dart';
import 'package:note_taking_app/core/ui/frosted_sliver_app_bar.dart';
import 'package:note_taking_app/widgets/bouncing_widget.dart';
import 'package:note_taking_app/providers/note_provider.dart';
import 'package:note_taking_app/services/backup_service.dart';
import 'package:note_taking_app/features/sync/providers/p2p_sync_provider.dart';
import 'package:note_taking_app/features/sync/presentation/widgets/qr_scanner_dialog.dart';

class P2pSyncScreen extends StatefulWidget {
  const P2pSyncScreen({super.key});

  @override
  State<P2pSyncScreen> createState() => _P2pSyncScreenState();
}

class _P2pSyncScreenState extends State<P2pSyncScreen> {
  final TextEditingController _pairCodeController = TextEditingController();
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _targetIpController = TextEditingController();

  @override
  void dispose() {
    _pairCodeController.dispose();
    _deviceNameController.dispose();
    _targetIpController.dispose();
    super.dispose();
  }

  void _showOverwriteWarningDialog(BuildContext context, VoidCallback onConfirmed) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AppDialog(
        title: 'Master Sync Warning',
        confirmLabel: 'I Understand & Overwrite',
        onConfirm: () {
          Navigator.pop(dialogCtx);
          onConfirmed();
        },
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppLayout.spaceM),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppLayout.radiusM),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error, size: 28),
                  const SizedBox(width: AppLayout.spaceM),
                  Expanded(
                    child: Text(
                      'This will replace 100% of notes, ledgers, and settings on this device with the Primary device\'s master snapshot.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppLayout.spaceM),
            Text(
              '• Primary device remains the master source.\n'
              '• This device will act as a synced Secondary copy.\n'
              '• Any local notes on this device will be replaced.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPairDeviceDialog(BuildContext context, P2pSyncProvider syncProvider) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AppDialog(
          title: 'Pair Primary Device',
          confirmLabel: 'Pull & Sync from Primary',
          onConfirm: () async {
            final code = _pairCodeController.text.trim();
            final name = _deviceNameController.text.trim();
            final ip = _targetIpController.text.trim();
            if (code.length == 6 && ip.isNotEmpty) {
              _showOverwriteWarningDialog(context, () async {
                final noteProvider = Provider.of<NoteProvider>(context, listen: false);
                await syncProvider.pairNewDevice(
                  deviceName: name.isEmpty ? 'Primary Device' : name,
                  pairCode: code,
                  targetIp: ip,
                  role: 'SECONDARY',
                );
                await syncProvider.pullFromPrimary(
                  targetIp: ip,
                  onCompleted: () {
                    noteProvider.refreshNotes();
                  },
                );
                _pairCodeController.clear();
                _deviceNameController.clear();
                _targetIpController.clear();
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              });
            }
          },
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommended: Scan the Primary device QR code to auto-detect Primary IP and pair code in 1 tap.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppLayout.spaceM),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final scanned = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                        );
                        if (scanned != null && scanned.isNotEmpty) {
                          try {
                            final map = json.decode(scanned) as Map<String, dynamic>;
                            setDialogState(() {
                              _pairCodeController.text = map['code']?.toString() ?? scanned;
                              if (map['ip'] != null) _targetIpController.text = map['ip'].toString();
                              if (map['name'] != null) _deviceNameController.text = map['name'].toString();
                            });
                          } catch (_) {
                            setDialogState(() {
                              _pairCodeController.text = scanned;
                            });
                          }
                        }
                      },
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Scan Primary QR Code', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: AppLayout.spaceL),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppLayout.spaceS),
                        child: Text(
                          'OR MANUAL IP & CODE',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: AppLayout.spaceM),
                  TextField(
                    controller: _targetIpController,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: 'Primary IP Address (e.g. 192.168.1.15)',
                      prefixIcon: Icon(Icons.wifi_rounded),
                    ),
                  ),
                  const SizedBox(height: AppLayout.spaceS),
                  TextField(
                    controller: _pairCodeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: '6-Digit Pair Code',
                      prefixIcon: Icon(Icons.key_outlined),
                    ),
                  ),
                  const SizedBox(height: AppLayout.spaceS),
                  TextField(
                    controller: _deviceNameController,
                    decoration: const InputDecoration(
                      labelText: 'Primary Device Name (Optional)',
                      prefixIcon: Icon(Icons.devices_outlined),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showQrCodeModal(BuildContext context, P2pSyncProvider provider) {
    final qrData = json.encode({
      'role': 'PRIMARY',
      'code': provider.currentPairCode,
      'name': 'Primary Notebook Device',
      'ip': provider.localIpAddress ?? '',
    });

    AppBottomSheet.show(
      context: context,
      title: 'Primary Host QR Code',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppLayout.spaceS),
          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 200.0,
            eyeStyle: QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Theme.of(context).colorScheme.primary,
            ),
            dataModuleStyle: QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.circle,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppLayout.spaceM),
          Text(
            'Pair Code: ${provider.currentPairCode}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4.0,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          if (provider.localIpAddress != null) ...[
            const SizedBox(height: 4),
            Text(
              'Primary IP: ${provider.localIpAddress}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
          const SizedBox(height: AppLayout.spaceM),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<P2pSyncProvider>(
      builder: (context, syncProvider, child) {
        final isSyncing = syncProvider.status == SyncStatus.syncing;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              const FrostedGlassSliverAppBar(
                titleText: 'Master P2P Device Sync',
                showBackButton: true,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppLayout.spaceM),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Hero CTA Card for Primary Master Sync
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppLayout.spaceS),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.sync_rounded, color: colorScheme.onPrimaryContainer, size: 28),
                              ),
                              const SizedBox(width: AppLayout.spaceM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Primary Master Sync',
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      syncProvider.lastMessage ?? 'Pull & overwrite data from Primary device',
                                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppLayout.spaceL),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 48,
                                  child: BouncingWidget(
                                    onTap: isSyncing
                                        ? null
                                        : () async {
                                            final noteProvider = Provider.of<NoteProvider>(context, listen: false);
                                            await syncProvider.pullFromPrimary(onCompleted: () {
                                              noteProvider.refreshNotes();
                                            });
                                          },
                                    child: FilledButton.icon(
                                      onPressed: isSyncing
                                          ? null
                                          : () async {
                                              final noteProvider = Provider.of<NoteProvider>(context, listen: false);
                                              await syncProvider.pullFromPrimary(onCompleted: () {
                                                noteProvider.refreshNotes();
                                              });
                                            },
                                      icon: isSyncing
                                          ? SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                                              ),
                                            )
                                          : const Icon(Icons.download_rounded),
                                      label: Text(
                                        isSyncing ? 'Pulling Data...' : 'Pull Sync Now',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppLayout.spaceS),
                              Expanded(
                                flex: 1,
                                child: SizedBox(
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    onPressed: () => syncProvider.sendTestPing(),
                                    icon: const Icon(Icons.network_ping_rounded, size: 18),
                                    label: const Text('Test Ping'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppLayout.spaceL),

                    // Primary Device Info & Local IP Card
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'This Device Network Host Info',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.qr_code_2_rounded),
                                tooltip: 'Show Primary Host QR Code',
                                onPressed: () => _showQrCodeModal(context, syncProvider),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppLayout.spaceS),
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pair Code',
                                    style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(AppLayout.radiusM),
                                    ),
                                    child: Text(
                                      syncProvider.currentPairCode,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 3.0,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: AppLayout.spaceL),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Device Local IP Address',
                                      style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.wifi_rounded,
                                          size: 16,
                                          color: syncProvider.localIpAddress != null ? colorScheme.primary : colorScheme.outline,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            syncProvider.localIpAddress ?? 'Checking Wi-Fi IP...',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppLayout.spaceL),

                    // Paired Devices List Section Header (Single Deduplicated List)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Paired Devices (${syncProvider.pairedDevices.length})',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: () => _showPairDeviceDialog(context, syncProvider),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Pair Device'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppLayout.spaceS),

                    if (syncProvider.pairedDevices.isEmpty)
                      AppCard(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppLayout.spaceL),
                            child: Column(
                              children: [
                                Icon(Icons.devices_other_rounded, size: 48, color: colorScheme.outline),
                                const SizedBox(height: AppLayout.spaceS),
                                Text(
                                  'No devices paired yet',
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap "Pair Device" to scan Primary device QR code.',
                                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ...syncProvider.pairedDevices.map((device) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppLayout.spaceS),
                          child: AppCard(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppLayout.spaceS),
                                  decoration: BoxDecoration(
                                    color: device.role == 'PRIMARY'
                                        ? colorScheme.primaryContainer
                                        : colorScheme.secondaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    device.role == 'PRIMARY' ? Icons.star_rounded : Icons.phone_android_rounded,
                                    color: device.role == 'PRIMARY'
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.onSecondaryContainer,
                                  ),
                                ),
                                const SizedBox(width: AppLayout.spaceM),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        device.deviceName,
                                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        device.lastSyncedAt != null
                                            ? 'Last synced ${DateFormat.jm().format(device.lastSyncedAt!)}'
                                            : 'Not synced yet',
                                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                                AppChip(
                                  label: device.role == 'PRIMARY' ? 'Primary' : 'Secondary',
                                  isSelected: true,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded),
                                  color: colorScheme.error,
                                  tooltip: 'Unpair Device',
                                  onPressed: () => syncProvider.unpairDevice(device.deviceId),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: AppLayout.spaceL),

                    // Offline Backup Export & Import Card
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Offline Backup File Sync',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Share backup file via Bluetooth, Nearby Share, or Drive as an offline fallback.',
                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: AppLayout.spaceM),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => BackupService.exportBackup(context),
                                  icon: const Icon(Icons.share_rounded, size: 18),
                                  label: const Text('Export & Share'),
                                ),
                              ),
                              const SizedBox(width: AppLayout.spaceS),
                              Expanded(
                                child: FilledButton.tonalIcon(
                                  onPressed: () => BackupService.importBackup(context),
                                  icon: const Icon(Icons.file_open_rounded, size: 18),
                                  label: const Text('Import Sync File'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppLayout.spaceL),

                    // Options & Settings
                    AppCard(
                      child: SwitchListTile(
                        value: syncProvider.isAutoSyncEnabled,
                        onChanged: (val) => syncProvider.setAutoSyncEnabled(val),
                        title: const Text('Background Auto-Sync'),
                        subtitle: const Text('Automatically pull data when secondary device connects'),
                        secondary: const Icon(Icons.sync_lock_rounded),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
