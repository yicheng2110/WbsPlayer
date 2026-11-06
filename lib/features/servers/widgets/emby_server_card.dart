import 'package:flutter/material.dart';

import '../../../l10n/app_localizations_context.dart';
import '../../../ui/core/app_colors.dart';
import '../models/emby_server.dart';

class EmbyServerCard extends StatelessWidget {
  const EmbyServerCard({
    super.key,
    required this.server,
    this.tokenValid,
    this.onTap,
  });

  final EmbyServer server;
  final bool? tokenValid;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: AppColors.navy.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.dns_outlined, color: AppColors.navy),
        ),
        title: Text(
          server.name,
          key: ValueKey('server-name-${server.localId ?? server.address}'),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: tokenValid == false ? AppColors.serverUnavailable : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            server.address,
            key: ValueKey('server-address-${server.localId ?? server.address}'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: tokenValid == false ? AppColors.serverUnavailable : null,
            ),
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
