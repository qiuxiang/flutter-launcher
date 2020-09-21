import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';

import 'apps.dart';
import 'search.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  build(context) {
    return MaterialApp(
      title: 'Launcher',
      darkTheme: ThemeData.dark(),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  createState() => _HomePageState();
}

enum PopupMenu {
  systemApps,
}

class _HomePageState extends State<HomePage> {
  List<Application> _apps = [];
  bool _includeSystemApps = true;

  initState() {
    super.initState();

    DeviceApps.getInstalledApplications(includeSystemApps: true)
        .then((apps) => setState(() => _apps = apps));
  }

  _onSelected(PopupMenu value) {
    switch (value) {
      case PopupMenu.systemApps:
        setState(() => _includeSystemApps = !_includeSystemApps);
    }
  }

  build(context) {
    var apps = _apps;
    if (!_includeSystemApps) {
      apps = apps.where((it) => !it.systemApp).toList();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Launcher'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () =>
                showSearch(context: context, delegate: Search(apps)),
          ),
          PopupMenuButton(
            onSelected: _onSelected,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: PopupMenu.systemApps,
                child: Row(children: [
                  Checkbox(
                    value: _includeSystemApps,
                    onChanged: (value) {
                      setState(() => _includeSystemApps = value);
                      Navigator.of(context).pop();
                    },
                  ),
                  const Text('System Apps'),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: Apps(apps),
    );
  }
}
