import 'package:flutter/material.dart';

import '../../../l10n/app_localizations_context.dart';
import '../models/emby_server.dart';
import '../services/emby_server_service.dart';

/// Collects updated server details and verifies the account before saving.
class EditServerDialog extends StatefulWidget {
  const EditServerDialog({
    super.key,
    required this.server,
    required this.serverService,
  });

  final EmbyServer server;
  final EmbyServerService serverService;

  @override
  State<EditServerDialog> createState() => _EditServerDialogState();
}

class _EditServerDialogState extends State<EditServerDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.server.name);
    _addressController = TextEditingController(text: widget.server.address);
    _usernameController = TextEditingController(text: widget.server.username);
    _passwordController = TextEditingController(text: widget.server.password);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      key: const Key('edit-server-dialog'),
      title: Text(l10n.editServer),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('edit-server-name-field'),
                controller: _nameController,
                enabled: !_isSaving,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.serverName,
                  hintText: l10n.serverNameHint,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('edit-server-address-field'),
                controller: _addressController,
                enabled: !_isSaving,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.serverAddress,
                  hintText: l10n.serverAddressHint,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.serverAddressRequired;
                  }
                  final uri = Uri.tryParse(value.trim());
                  if (uri == null ||
                      !{'http', 'https'}.contains(uri.scheme) ||
                      uri.host.isEmpty) {
                    return l10n.serverAddressInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('edit-server-username-field'),
                controller: _usernameController,
                enabled: !_isSaving,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l10n.embyUsername),
                validator: (value) => value == null || value.trim().isEmpty
                    ? l10n.embyUsernameRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('edit-server-password-field'),
                controller: _passwordController,
                enabled: !_isSaving,
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(labelText: l10n.embyPassword),
                onFieldSubmitted: (_) => _submit(),
              ),
              if (_errorMessage case final message?) ...[
                const SizedBox(height: 12),
                Text(
                  message,
                  key: const Key('edit-server-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('confirm-edit-server'),
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final address = _addressController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    try {
      await widget.serverService.checkConnection(address);
      final authentication = await widget.serverService.authenticate(
        serverAddress: address,
        username: username,
        password: password,
      );
      if (!mounted) return;
      Navigator.pop(
        context,
        EmbyServer(
          localId: widget.server.localId,
          name: _nameController.text.trim().isEmpty
              ? context.l10n.defaultServerName
              : _nameController.text.trim(),
          address: address,
          username: authentication.username,
          password: authentication.password,
          accessToken: authentication.accessToken,
          serverId: authentication.serverId,
          userId: authentication.userId,
        ),
      );
    } on EmbyAuthenticationException {
      if (!mounted) return;
      _showError(context.l10n.embyInvalidCredentials);
    } on EmbyConnectionException {
      if (!mounted) return;
      _showError(context.l10n.embyConnectionFailed);
    } on EmbyServerRequestException {
      if (!mounted) return;
      _showError(context.l10n.embyLoginFailed);
    } catch (_) {
      if (!mounted) return;
      _showError(context.l10n.embyLoginFailed);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
  }
}
