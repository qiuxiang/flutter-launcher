import 'dart:io';

import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'model.dart';
import 'database.dart';

class Apps extends StatelessWidget {
  final List<AppCache> apps;

  const Apps(this.apps, {super.key});

  @override
  build(context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 80,
        mainAxisExtent: 80,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: apps.length,
      itemBuilder: (context, i) {
        final item = apps.elementAt(i);
        final iconFile =
            File('${AppDatabase.iconsDir.path}/${item.packageName}.png');

        return InkWell(
          onTap: () {
            try {
              InstalledApps.startApp(item.packageName);
            } catch (_) {}
          },
          borderRadius: BorderRadius.circular(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconFile.existsSync()
                  ? Image.file(iconFile, width: 48, height: 48)
                  : const SizedBox(width: 48, height: 48),
              const SizedBox(height: 4),
              Text(
                item.name,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}
