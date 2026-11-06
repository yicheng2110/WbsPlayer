import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations_context.dart';
import '../services/apk_installer.dart';
import '../services/release_update_service.dart';

class ReleaseUpdateTile extends StatefulWidget {
  const ReleaseUpdateTile({
    super.key,
    this.service,
    this.installApk,
    this.isAndroid,
  });

  final ReleaseUpdateService? service;
  final Future<String> Function(String path)? installApk;
  final bool? isAndroid;

  @override
  State<ReleaseUpdateTile> createState() => _ReleaseUpdateTileState();
}

class _ReleaseUpdateTileState extends State<ReleaseUpdateTile> {
  late final ReleaseUpdateService _service =
      widget.service ?? ReleaseUpdateService();
  late final bool _ownsService = widget.service == null;
  bool _isChecking = false;

  @override
  void dispose() {
    if (_ownsService) _service.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!(widget.isAndroid ??
        defaultTargetPlatform == TargetPlatform.android)) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    return ListTile(
      key: const Key('check-for-updates'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: const Icon(Icons.system_update, size: 28),
      title: Text(l10n.checkForUpdates),
      trailing: _isChecking
          ? const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: _isChecking ? null : _checkForUpdates,
    );
  }

  Future<void> _checkForUpdates() async {
    setState(() => _isChecking = true);
    try {
      final release = await _service.checkForUpdate();
      if (!mounted) return;
      if (release.isLatest) {
        _showMessage(context.l10n.latestVersionInstalled);
        return;
      }

      if (release.apkUri == null) {
        _showMessage(context.l10n.updateDownloadFailed);
        return;
      }
      final download = await showDialog<bool>(
        context: context,
        builder: (context) => _UpdateAvailableDialog(release: release),
      );
      if (download != true || !mounted) return;
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _ApkDownloadDialog(
          service: _service,
          release: release,
          installApk: widget.installApk ?? ApkInstaller.install,
        ),
      );
      if (!mounted) return;
      switch (result) {
        case 'opened':
          _showMessage(context.l10n.updateInstallerStarted);
          break;
        case 'download_failed':
          _showMessage(context.l10n.updateDownloadFailed);
          break;
        case 'permission_denied':
        case 'installer_failed':
          _showMessage(context.l10n.updateInstallerFailed);
          break;
        case null:
          break;
        default:
          _showMessage(context.l10n.updateInstallerFailed);
          break;
      }
    } catch (_) {
      if (mounted) _showMessage(context.l10n.updateCheckFailed);
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _UpdateAvailableDialog extends StatelessWidget {
  const _UpdateAvailableDialog({required this.release});

  final ReleaseUpdate release;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      key: const Key('update-available-dialog'),
      title: Text(l10n.updateAvailableTitle),
      content: Text(
        l10n.updateAvailableMessage(
          release.currentVersion,
          release.latestVersion,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          key: const Key('download-update-button'),
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.download),
          label: Text(l10n.downloadUpdate),
        ),
      ],
    );
  }
}

class _ApkDownloadDialog extends StatefulWidget {
  const _ApkDownloadDialog({
    required this.service,
    required this.release,
    required this.installApk,
  });

  final ReleaseUpdateService service;
  final ReleaseUpdate release;
  final Future<String> Function(String path) installApk;

  @override
  State<_ApkDownloadDialog> createState() => _ApkDownloadDialogState();
}

class _ApkDownloadDialogState extends State<_ApkDownloadDialog> {
  int _receivedBytes = 0;
  int? _totalBytes;
  bool _openingInstaller = false;

  @override
  void initState() {
    super.initState();
    unawaited(_downloadAndOpen());
  }

  Future<void> _downloadAndOpen() async {
    late final File apk;
    try {
      apk = await widget.service.downloadApk(
        widget.release,
        onProgress: (receivedBytes, totalBytes) {
          if (!mounted) return;
          setState(() {
            _receivedBytes = receivedBytes;
            _totalBytes = totalBytes;
          });
        },
      );
    } catch (_) {
      if (mounted) Navigator.pop(context, 'download_failed');
      return;
    }

    if (!mounted) return;
    setState(() => _openingInstaller = true);
    try {
      final result = await widget.installApk(apk.path);
      if (mounted) Navigator.pop(context, result);
    } catch (_) {
      if (mounted) Navigator.pop(context, 'installer_failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final totalBytes = _totalBytes;
    final progress = totalBytes == null || totalBytes == 0
        ? null
        : (_receivedBytes / totalBytes).clamp(0.0, 1.0);
    final message = _openingInstaller
        ? l10n.openingUpdateInstaller
        : l10n.downloadingUpdate;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        key: const Key('apk-download-dialog'),
        title: Text(message),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: progress),
            if (progress != null) ...[
              const SizedBox(height: 12),
              Text(
                l10n.downloadPercent((progress * 100).round()),
                textAlign: TextAlign.end,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
