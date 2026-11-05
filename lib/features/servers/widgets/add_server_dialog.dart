import 'package:flutter/material.dart';

import '../../../l10n/app_localizations_context.dart';
import '../models/emby_server.dart';
import '../services/emby_server_service.dart';
import 'emby_credentials_dialog.dart';

class AddServerDialog extends StatefulWidget {
  const AddServerDialog({super.key, required this.serverService});

  final EmbyServerService serverService;

  @override
  State<AddServerDialog> createState() => _AddServerDialogState();
}

class _AddServerDialogState extends State<AddServerDialog> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isCheckingConnection = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.addServer),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('server-name-field'),
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: context.l10n.serverName,
                hintText: context.l10n.serverNameHint,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('server-address-field'),
              controller: _addressController,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: context.l10n.serverAddress,
                hintText: context.l10n.serverAddressHint,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.l10n.serverAddressRequired;
                }
                final uri = Uri.tryParse(value.trim());
                if (uri == null ||
                    !{'http', 'https'}.contains(uri.scheme) ||
                    uri.host.isEmpty) {
                  return context.l10n.serverAddressInvalid;
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_errorMessage case final message?) ...[
              const SizedBox(height: 12),
              Text(
                message,
                key: const Key('server-connection-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCheckingConnection
              ? null
              : () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          key: const Key('confirm-add-server'),
          onPressed: _isCheckingConnection ? null : _submit,
          child: _isCheckingConnection
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.l10n.add),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final serverAddress = _addressController.text.trim();
    setState(() {
      _isCheckingConnection = true;
      _errorMessage = null;
    });

    try {
      await widget.serverService.checkConnection(serverAddress);
      if (!mounted) return;
      setState(() => _isCheckingConnection = false);

      final authentication = await showDialog<EmbyAuthenticationResult>(
        context: context,
        builder: (context) => EmbyCredentialsDialog(
          serverAddress: serverAddress,
          serverService: widget.serverService,
        ),
      );
      if (authentication == null || !mounted) return;

      final name = _nameController.text.trim();
      Navigator.pop(
        context,
        EmbyServer(
          name: name.isEmpty ? context.l10n.defaultServerName : name,
          address: serverAddress,
          username: authentication.username,
          password: authentication.password,
          accessToken: authentication.accessToken,
          serverId: authentication.serverId,
        ),
      );
    } on EmbyConnectionException {
      if (!mounted) return;
      _showError(context.l10n.embyConnectionFailed);
    } catch (_) {
      if (!mounted) return;
      _showError(context.l10n.embyConnectionFailed);
    } finally {
      if (mounted) setState(() => _isCheckingConnection = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
  }
}
