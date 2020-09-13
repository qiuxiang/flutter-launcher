import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';

class Apps extends StatelessWidget {
  final Iterable<Application> apps;

  const Apps(this.apps);

  build(context) {
    return ListView.builder(
      itemCount: apps.length,
      itemBuilder: (context, i) {
        final item = apps.elementAt(i);
        return ListTile(
          title: Text(item.appName),
          subtitle: Text(item.packageName),
          onTap: () => DeviceApps.openApp(item.packageName),
        );
      },
    );
  }
}
