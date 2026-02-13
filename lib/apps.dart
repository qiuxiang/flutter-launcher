import 'dart:io';

import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'model.dart';
import 'database.dart';

class Apps extends StatelessWidget {
  final Iterable<AppCache> apps;
  final Function(AppCache)? onOpen;

  const Apps(this.apps, {this.onOpen, super.key});

  @override
  build(context) {
    final iconsDir = AppDatabase.iconsDir;

    return ListView.builder(
      itemCount: apps.length,
      itemBuilder: (context, i) {
        final item = apps.elementAt(i);
        final iconFile = File('${iconsDir.path}/${item.packageName}.png');
        final hasIcon = iconFile.existsSync();

        return ListTile(
          leading: hasIcon
              ? Image.file(iconFile, width: 40)
              : const SizedBox(width: 40, height: 40),
          title: Text(item.name),
          subtitle: Text(item.packageName),
          onTap: () {
            onOpen?.call(item);
            InstalledApps.startApp(item.packageName);
          },
        );
      },
    );
  }
}
