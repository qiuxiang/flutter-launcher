import 'dart:io';

import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'models/app_cache.dart';
import 'services/app_database.dart';

class Apps extends StatelessWidget {
  final Iterable<AppCache> apps;
  final Function(AppCache)? onFavoriteToggle;

  const Apps(this.apps, {this.onFavoriteToggle, super.key});

  @override
  build(context) {
    final iconsDir = AppDatabase.iconsDir;

    return ListView.builder(
      itemCount: apps.length,
      itemBuilder: (context, i) {
        final item = apps.elementAt(i);
        final iconFile = File('${iconsDir.path}/${item.packageName}.png');
        final hasIcon = iconFile.existsSync();

        return Dismissible(
          key: ValueKey('${item.packageName}_${item.isFavorite}'),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.amber,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Icon(
              item.isFavorite ? Icons.star_border : Icons.star,
              color: Colors.white,
            ),
          ),
          confirmDismiss: (direction) async {
            onFavoriteToggle?.call(item);
            return false;
          },
          child: ListTile(
            leading: hasIcon
                ? Image.file(iconFile, width: 40)
                : const SizedBox(width: 40, height: 40),
            title: Text(item.name),
            subtitle: Text(item.packageName),
            trailing: item.isFavorite
                ? const Icon(Icons.star, color: Colors.amber, size: 20)
                : null,
            onTap: () => InstalledApps.startApp(item.packageName),
          ),
        );
      },
    );
  }
}
