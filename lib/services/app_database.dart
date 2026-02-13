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

  factory AppDatabase() => _instance;
  AppDatabase._();

  static const _tableName = 'apps';
  static const _dbName = 'app_cache.db';
  static const _dbVersion = 1;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final appDocDir = await getApplicationDocumentsDirectory();
    final dbDir = Directory(join(appDocDir.path, 'databases'));

    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }

    return await openDatabase(
      join(dbDir.path, _dbName),
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        package_name TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        icon BLOB,
        is_system_app INTEGER NOT NULL DEFAULT 0,
        version_name TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_package_name ON $_tableName(package_name)
    ''');
  }

  Future<List<AppCache>> getApps() async {
    final db = await database;
    final maps = await db.query(_tableName, orderBy: 'name COLLATE NOCASE ASC');

    return maps.map((map) => AppCache.fromMap(map)).toList();
  }

  Future<void> saveApps(List<AppInfo> apps) async {
    return (await database).transaction((txn) async {
      await txn.delete(_tableName);

      for (final app in apps) {
        final cache = AppCache(
          name: app.name,
          packageName: app.packageName,
          icon: app.icon,
          isSystemApp: app.isSystemApp,
          versionName: app.versionName,
        );

        await txn.insert(
          _tableName,
          cache.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
