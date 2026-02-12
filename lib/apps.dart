import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

class Apps extends StatelessWidget {
  final Iterable<AppInfo> apps;

  const Apps(this.apps, {super.key});

  @override
  build(context) {
    return ListView.builder(
      itemCount: apps.length,
      itemBuilder: (context, i) {
        final item = apps.elementAt(i);
        return ListTile(
          leading: item.icon != null
              ? Image.memory(item.icon!, width: 40)
              : const SizedBox(width: 40, height: 40),
          title: Text(item.name),
          subtitle: Text(item.packageName),
          onTap: () => InstalledApps.startApp(item.packageName),
        );
      },
    );
  }
}
