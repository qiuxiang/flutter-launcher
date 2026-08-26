import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Launcher',
        darkTheme: ThemeData.dark(),
        home: const HomePage(),
      );
}

const _iconChannel = MethodChannel('launcher');
final _iconCache = <String, Future<Uint8List?>>{};
final _iconInFlight = <String, Future<Uint8List?>>{};

Future<Uint8List?> getIcon(String packageName) {
  final cached = _iconCache[packageName];
  if (cached != null) return cached;

  final existing = _iconInFlight[packageName];
  if (existing != null) return existing;

  final future = _iconChannel
      .invokeMethod<Uint8List>('get_icon', {'package_name': packageName})
      .then((bytes) {
    _iconInFlight.remove(packageName);
    _iconCache[packageName] = Future.value(bytes);
    return bytes;
  }).catchError((_) {
    _iconInFlight.remove(packageName);
    _iconCache[packageName] = Future.value(null);
    return null;
  });
  _iconInFlight[packageName] = future;
  return future;
}

class _AppIcon extends StatelessWidget {
  final AppInfo app;
  const _AppIcon(this.app);

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
        future: getIcon(app.packageName),
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          if (bytes != null) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(bytes, width: 48, height: 48),
            );
          }
          return const SizedBox(width: 48, height: 48);
        },
      );
}

class _AppsGrid extends StatelessWidget {
  final List<AppInfo> apps;
  const _AppsGrid(this.apps);

  @override
  Widget build(BuildContext context) => GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 80,
          mainAxisExtent: 80,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: apps.length,
        itemBuilder: (context, i) {
          final item = apps[i];
          return InkWell(
            key: ValueKey(item.packageName),
            onTap: () => InstalledApps.startApp(item.packageName),
            borderRadius: BorderRadius.circular(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AppIcon(item),
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

class _AppSearch extends SearchDelegate {
  final List<AppInfo> apps;
  _AppSearch(this.apps);

  @override
  List<Widget> buildActions(BuildContext context) =>
      [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget? buildLeading(BuildContext context) => null;

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    final q = query.toLowerCase();
    final filtered = apps
        .where((it) =>
            it.name.toLowerCase().contains(q) ||
            it.packageName.toLowerCase().contains(q))
        .toList();
    return _AppsGrid(filtered);
  }
}

const _selfPackageName = 'qiuxiang.launcher';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _apps = <AppInfo>[];
  var _includeSystemApps = false;
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: false,
        withIcon: false,
      );
      if (mounted) {
        setState(() {
          _apps = apps;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('_loadApps failed: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var apps = _apps;
    if (!_includeSystemApps) {
      apps = apps.where((it) => !it.isSystemApp).toList();
    }
    final sortedApps = List<AppInfo>.of(apps)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()))
      ..removeWhere((it) => it.packageName == _selfPackageName);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Launcher'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showSearch(
              context: context,
              delegate: _AppSearch(sortedApps),
            ),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: () {
                  if (mounted) setState(() => _includeSystemApps = !_includeSystemApps);
                },
                child: Row(
                  children: [
                    Checkbox(value: _includeSystemApps, onChanged: null),
                    const Text('System Apps'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading && _apps.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _AppsGrid(sortedApps),
    );
  }
}
