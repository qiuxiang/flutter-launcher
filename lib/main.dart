import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';

import 'apps.dart';
import 'model.dart';
import 'search.dart';
import 'database.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  build(context) {
    return MaterialApp(
      title: 'Launcher',
      darkTheme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  createState() => _HomePageState();
}

enum PopupMenu {
  systemApps,
}

class _HomePageState extends State<HomePage> {
  var _apps = <AppCache>[];
  var _includeSystemApps = false;
  var _isLoading = true;
  final _db = AppDatabase();

  @override
  initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final cachedApps = await _db.getApps();
    if (cachedApps.isNotEmpty) {
      setState(() {
        _apps = cachedApps;
        _isLoading = false;
      });
    }

    await _refreshApps();
  }

  Future<void> _refreshApps() async {
    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: false,
        withIcon: true,
      );

      await _db.saveApps(apps);
      final updatedApps = await _db.getApps();

      if (mounted) {
        setState(() {
          _apps = updatedApps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSelected(PopupMenu value) {
    switch (value) {
      case PopupMenu.systemApps:
        setState(() => _includeSystemApps = !_includeSystemApps);
    }
  }

  @override
  build(context) {
    var apps = _apps;
    if (!_includeSystemApps) {
      apps = apps.where((it) => !it.isSystemApp).toList();
    }

    // Sort: by name ascending only
    final sortedApps = apps.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Launcher'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showSearch(
              context: context,
              delegate: Search(sortedApps),
            ),
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
                      setState(() => _includeSystemApps = value!);
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
      body: _isLoading && _apps.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Apps(
              sortedApps,
            ),
    );
  }
}
