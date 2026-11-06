import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/locale_preference.dart';
import '../../../l10n/app_localizations_context.dart';
import '../../../ui/core/app_colors.dart';
import '../../settings/views/settings_page.dart';
import '../models/emby_server.dart';
import '../repositories/drift_server_repository.dart';
import '../repositories/server_repository.dart';
import '../services/emby_server_service.dart';
import '../widgets/add_server_dialog.dart';
import '../widgets/edit_server_dialog.dart';
import '../widgets/empty_server_state.dart';
import '../widgets/emby_server_card.dart';
import '../widgets/server_navigation_pill.dart';

class ServerHomePage extends StatefulWidget {
  const ServerHomePage({
    super.key,
    this.serverService,
    this.serverRepository,
    required this.onServerSelected,
    required this.localePreference,
    required this.isLocaleLoaded,
    required this.onLocalePreferenceSelected,
    required this.localePreferenceListenable,
    required this.localeLoadedListenable,
  });

  final EmbyServerService? serverService;
  final ServerRepository? serverRepository;
  final ValueChanged<EmbyServer> onServerSelected;
  final LocalePreference localePreference;
  final bool isLocaleLoaded;
  final Future<void> Function(LocalePreference) onLocalePreferenceSelected;
  final ValueListenable<LocalePreference> localePreferenceListenable;
  final ValueListenable<bool> localeLoadedListenable;

  @override
  State<ServerHomePage> createState() => _ServerHomePageState();
}

class _ServerHomePageState extends State<ServerHomePage> {
  final List<EmbyServer> _servers = [];
  final Map<int, bool> _tokenValidity = {};
  late final EmbyServerService _serverService;
  late final ServerRepository _serverRepository;
  late final bool _ownsServerService;
  late final bool _ownsServerRepository;
  bool _isLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _ownsServerService = widget.serverService == null;
    _serverService = widget.serverService ?? EmbyServerService();
    _ownsServerRepository = widget.serverRepository == null;
    _serverRepository = widget.serverRepository ?? DriftServerRepository();
    _loadSavedServers();
  }

  @override
  void dispose() {
    if (_ownsServerService) _serverService.close();
    if (_ownsServerRepository) _serverRepository.close();
    super.dispose();
  }

  Future<void> _addServer() async {
    if (_isLoading) return;
    final server = await showDialog<EmbyServer>(
      context: context,
      builder: (context) => AddServerDialog(serverService: _serverService),
    );
    if (server == null || !mounted) return;
    try {
      final savedServer = await _serverRepository.saveServer(server);
      if (!mounted) return;
      setState(() {
        _servers.add(savedServer);
        if (savedServer.localId case final id?) _tokenValidity[id] = true;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.serverSaveFailed)));
    }
  }

  Future<void> _editServer(EmbyServer server) async {
    if (_isLoading) return;
    final updatedServer = await showDialog<EmbyServer>(
      context: context,
      builder: (context) =>
          EditServerDialog(server: server, serverService: _serverService),
    );
    if (updatedServer == null || !mounted) return;
    try {
      await _serverRepository.updateServer(updatedServer);
      if (!mounted) return;
      setState(() {
        final index = _servers.indexWhere(
          (savedServer) => savedServer.localId == updatedServer.localId,
        );
        if (index != -1) _servers[index] = updatedServer;
        if (updatedServer.localId case final id?) _tokenValidity.remove(id);
      });
      final isValid = await _serverService.isAccessTokenValid(
        serverAddress: updatedServer.address,
        accessToken: updatedServer.accessToken,
        serverId: updatedServer.serverId,
      );
      if (!mounted) return;
      if (updatedServer.localId case final id?) {
        setState(() => _tokenValidity[id] = isValid);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.serverEditFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isServerTab = _selectedTab == 0;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        toolbarHeight: 72,
        title: Text(
          isServerTab ? context.l10n.serversTitle : context.l10n.settingsTitle,
          style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w700),
        ),
        actions: [
          PopupMenuButton<_ServerMenuAction>(
            tooltip: context.l10n.moreOptions,
            icon: const Icon(Icons.more_vert, size: 27),
            onSelected: (action) {
              if (action == _ServerMenuAction.addServer) {
                _addServer();
              } else {
                setState(() => _selectedTab = 2);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _ServerMenuAction.addServer,
                child: Text(context.l10n.addServer),
              ),
              PopupMenuItem(
                value: _ServerMenuAction.settings,
                child: Text(context.l10n.settingsTitle),
              ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: isServerTab
          ? _buildServerList()
          : ValueListenableBuilder<LocalePreference>(
              valueListenable: widget.localePreferenceListenable,
              builder: (context, preference, child) =>
                  ValueListenableBuilder<bool>(
                    valueListenable: widget.localeLoadedListenable,
                    builder: (context, isLoaded, child) => SettingsPage(
                      localePreference: preference,
                      isLocaleLoaded: isLoaded,
                      onLocalePreferenceSelected:
                          widget.onLocalePreferenceSelected,
                    ),
                  ),
            ),
      floatingActionButton: isServerTab
          ? SizedBox(
              width: 64,
              height: 64,
              child: FloatingActionButton(
                key: const Key('add-server-button'),
                onPressed: _addServer,
                tooltip: context.l10n.addServer,
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.navy,
                elevation: 7,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.add, size: 34),
              ),
            )
          : null,
      bottomNavigationBar: ServerNavigationPill(
        selectedIndex: _selectedTab == 0 ? 0 : 2,
        onSelected: (index) {
          // 聚合视界暂不实现，只保留与参考图一致的导航入口。
          if (index == 1) return;
          setState(() => _selectedTab = index);
        },
      ),
    );
  }

  Future<void> _loadSavedServers() async {
    try {
      final servers = await _serverRepository.getAllServers();
      if (!mounted) return;
      setState(() {
        _servers
          ..clear()
          ..addAll(servers);
        _isLoading = false;
      });

      final validity = await Future.wait(
        servers.map(
          (server) => _serverService.isAccessTokenValid(
            serverAddress: server.address,
            accessToken: server.accessToken,
            serverId: server.serverId,
          ),
        ),
      );
      if (!mounted) return;
      setState(() {
        for (var index = 0; index < servers.length; index++) {
          final id = servers[index].localId;
          if (id != null) _tokenValidity[id] = validity[index];
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.serverLoadFailed)));
    }
  }

  Widget _buildServerList() {
    if (_isLoading) {
      return Center(child: Text(context.l10n.serverLoading));
    }
    if (_servers.isEmpty) return const EmptyServerState();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          itemCount: _servers.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final server = _servers[index];
            final id = server.localId;
            return EmbyServerCard(
              server: server,
              tokenValid: id == null ? null : _tokenValidity[id],
              onTap: () => widget.onServerSelected(server),
              onEdit: () => _editServer(server),
            );
          },
        ),
      ),
    );
  }
}

enum _ServerMenuAction { addServer, settings }
