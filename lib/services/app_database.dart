import 'dart:async';
import 'dart:io';

import 'package:installed_apps/app_info.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/app_cache.dart';

class AppDatabase {
  static final _instance = AppDatabase._();
  static Database? _database;
  static Directory? _iconsDir;

  factory AppDatabase() => _instance;
  AppDatabase._();

  static const _tableName = 'apps';
  static const _dbName = 'app_cache.db';
  static const _dbVersion = 4;

  static Directory get iconsDir => _iconsDir!;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final appDocDir = await getApplicationDocumentsDirectory();
    final dbDir = Directory(join(appDocDir.path, 'databases'));
    _iconsDir = Directory(join(appDocDir.path, 'icons'));

    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    if (!await _iconsDir!.exists()) {
      await _iconsDir!.create(recursive: true);
    }

    return await openDatabase(
      join(dbDir.path, _dbName),
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE $_tableName ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 3) {
      // Drop the icon column as we now store icons in files
      await db.execute('ALTER TABLE $_tableName DROP COLUMN icon');
    }
    if (oldVersion < 4) {
      await db.execute(
          'ALTER TABLE $_tableName ADD COLUMN last_opened_at INTEGER NOT NULL DEFAULT 0');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        package_name TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        is_system_app INTEGER NOT NULL DEFAULT 0,
        version_name TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        last_opened_at INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_package_name ON $_tableName(package_name)
    ''');
  }

  Future<List<AppCache>> getApps() async {
    final db = await database;
    // Exclude icon column since icons are now stored in files
    final maps = await db.query(
      _tableName,
      columns: [
        'package_name',
        'name',
        'is_system_app',
        'version_name',
        'is_favorite',
        'last_opened_at'
      ],
    );
    return maps.map((map) => AppCache.fromMap(map)).toList();
  }

  Future<void> saveApps(List<AppInfo> apps) async {
    final db = await database;
    return db.transaction((txn) async {
      final currentData = await txn.query(
        _tableName,
        columns: ['package_name', 'is_favorite', 'last_opened_at'],
      );
      final favoriteMap = {
        for (final row in currentData)
          row['package_name'] as String: row['is_favorite'] as int
      };
      final lastOpenedMap = {
        for (final row in currentData)
          row['package_name'] as String: row['last_opened_at'] as int
      };

      await txn.delete(_tableName);

      for (final app in apps) {
        // Save icon to file only if it doesn't exist
        if (app.icon != null) {
          final iconFile =
              File(join(_iconsDir!.path, '${app.packageName}.png'));
          if (!await iconFile.exists()) {
            await iconFile.writeAsBytes(app.icon!);
          }
        }

        final cache = AppCache(
          name: app.name,
          packageName: app.packageName,
          icon: app.icon,
          isSystemApp: app.isSystemApp,
          versionName: app.versionName,
          isFavorite: favoriteMap[app.packageName] == 1,
          lastOpenedAt: lastOpenedMap[app.packageName] ?? 0,
        );

        // toMap() now excludes icon since we store it in files
        final map = cache.toMap();
        map.remove('icon');

        await txn.insert(
          _tableName,
          map,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> updateLastOpened(String packageName) async {
    final db = await database;
    await db.update(
      _tableName,
      {'last_opened_at': DateTime.now().millisecondsSinceEpoch},
      where: 'package_name = ?',
      whereArgs: [packageName],
    );
  }

  Future<void> toggleFavorite(String packageName, bool isFavorite) async {
    final db = await database;
    await db.update(
      _tableName,
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'package_name = ?',
      whereArgs: [packageName],
    );
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
