import 'package:flutter/material.dart';

import '../../../l10n/app_localizations_context.dart';
import '../services/emby_server_service.dart';

class EmbyCredentialsDialog extends StatefulWidget {
  const EmbyCredentialsDialog({
    super.key,
    required this.serverAddress,
    required this.serverService,
  });

  final String serverAddress;
  final EmbyServerService serverService;

  @override
  State<EmbyCredentialsDialog> createState() => _EmbyCredentialsDialogState();
}

class _EmbyCredentialsDialogState extends State<EmbyCredentialsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      key: const Key('emby-credentials-dialog'),
      title: Text(l10n.embySignInTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.serverAddress,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('emby-username-field'),
              controller: _usernameController,
              enabled: !_isSubmitting,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: l10n.embyUsername),
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.embyUsernameRequired
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('emby-password-field'),
              controller: _passwordController,
              enabled: !_isSubmitting,
              obscureText: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(labelText: l10n.embyPassword),
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_errorMessage case final message?) ...[
              const SizedBox(height: 12),
              Text(
                message,
                key: const Key('emby-login-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('emby-sign-in-button'),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.embySignIn),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.serverService.authenticate(
        serverAddress: widget.serverAddress,
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pop(context, result);
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
  }
}
