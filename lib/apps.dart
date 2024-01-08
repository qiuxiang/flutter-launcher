import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';

class Apps extends StatelessWidget {
  final Iterable<Application> apps;

  const Apps(this.apps, {super.key});

  @override
  build(context) {
    return ListView.builder(
      itemCount: apps.length,
      itemBuilder: (context, i) {
        final item = apps.elementAt(i);
        Image? icon;
        if (item is ApplicationWithIcon) {
          icon = Image.memory(item.icon, width: 40);
        }
        return ListTile(
          leading: icon,
          title: Text(item.appName),
          subtitle: Text(item.packageName),
          onTap: () => DeviceApps.openApp(item.packageName),
        );
      },
    );
  }
}
