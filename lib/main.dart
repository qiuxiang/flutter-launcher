import 'package:flutter/material.dart';
import 'package:installed_apps/app_category.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/platform_type.dart';

import 'apps.dart';
import 'models/app_cache.dart';
import 'search.dart';
import 'services/app_database.dart';

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
  var _apps = <AppInfo>[];
  var _includeSystemApps = true;
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
        _apps = _convertCacheToAppInfo(cachedApps);
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

      if (mounted) {
        setState(() {
          _apps = apps..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && _apps.isEmpty) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<AppInfo> _convertCacheToAppInfo(List<AppCache> caches) {
    return caches.map((cache) => AppInfo(
      name: cache.name,
      packageName: cache.packageName,
      icon: cache.icon,
      isSystemApp: cache.isSystemApp,
      versionName: cache.versionName ?? '1.0.0',
      versionCode: 1,
      platformType: PlatformType.nativeOrOthers,
      installedTimestamp: 0,
      isLaunchableApp: true,
      category: AppCategory.undefined,
    )).toList();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Launcher'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showSearch(
              context: context,
              delegate: Search(apps),
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
            : Apps(apps),
    );
  }
}
