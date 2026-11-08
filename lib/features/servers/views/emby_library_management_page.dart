import 'package:flutter/material.dart';

import '../../../l10n/app_localizations_context.dart';
import '../../../ui/core/app_colors.dart';
import '../models/emby_media.dart';
import '../models/emby_library_preferences.dart';

class EmbyLibraryManagementPage extends StatefulWidget {
  const EmbyLibraryManagementPage({
    super.key,
    required this.libraries,
    required this.initialPreferences,
    required this.onPreferencesChanged,
  });

  final List<EmbyLibrary> libraries;
  final EmbyLibraryPreferences initialPreferences;
  final Future<void> Function(EmbyLibraryPreferences) onPreferencesChanged;

  @override
  State<EmbyLibraryManagementPage> createState() =>
      _EmbyLibraryManagementPageState();
}

class _EmbyLibraryManagementPageState extends State<EmbyLibraryManagementPage> {
  late EmbyLibraryPreferences _preferences;
  Future<void> _saveQueue = Future<void>.value();
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    _preferences = widget.initialPreferences.normalize(
      widget.libraries.map((library) => library.id),
    );
  }

  Future<void> _updatePreferences(EmbyLibraryPreferences preferences) async {
    setState(() => _preferences = preferences);
    _saveQueue = _saveQueue
        .catchError((_) {})
        .then((_) => widget.onPreferencesChanged(preferences));
    try {
      await _saveQueue;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.libraryPreferencesSaveFailed)),
      );
    }
  }

  Future<void> _finish() async {
    if (_isFinishing) return;
    _isFinishing = true;
    await _saveQueue.catchError((_) {});
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final librariesById = {
      for (final library in widget.libraries) library.id: library,
    };
    final libraries = [
      for (final id in _preferences.order)
        if (librariesById[id] case final library?) library,
    ];

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish();
      },
      child: Scaffold(
        backgroundColor: AppColors.mediaBackground,
        appBar: AppBar(
          backgroundColor: AppColors.mediaBackground,
          foregroundColor: AppColors.mediaInk,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: _finish,
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(l10n.libraryManageTitle),
          actions: [
            IconButton(
              key: const Key('library-management-done'),
              tooltip: l10n.done,
              onPressed: _finish,
              icon: const Icon(Icons.check),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: ReorderableListView.builder(
              key: const Key('emby-library-management-list'),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: libraries.length,
              onReorder: (oldIndex, newIndex) =>
                  _updatePreferences(_preferences.reorder(oldIndex, newIndex)),
              itemBuilder: (context, index) {
                final library = libraries[index];
                return ListTile(
                  key: ValueKey('library-management-${library.id}'),
                  leading: const Icon(Icons.video_library_outlined),
                  title: Text(library.name),
                  subtitle: Text(l10n.libraryShowOnHome),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        key: ValueKey('library-home-switch-${library.id}'),
                        value: _preferences.isVisibleOnHome(library.id),
                        onChanged: (visible) => _updatePreferences(
                          _preferences.setVisible(library.id, visible),
                        ),
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: Tooltip(
                          message: l10n.libraryOrderHandle,
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(Icons.drag_handle),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
