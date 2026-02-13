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
  static const _dbVersion = 2;

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
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE $_tableName ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        package_name TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        icon BLOB,
        is_system_app INTEGER NOT NULL DEFAULT 0,
        version_name TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_package_name ON $_tableName(package_name)
    ''');
  }

  Future<List<AppCache>> getApps() async {
    final db = await database;
    final maps = await db.query(_tableName);
    return maps.map((map) => AppCache.fromMap(map)).toList();
  }

  Future<void> saveApps(List<AppInfo> apps) async {
    final db = await database;
    return db.transaction((txn) async {
      final currentFavorites = await txn.query(
        _tableName,
        columns: ['package_name'],
        where: 'is_favorite = 1',
      );
      final favoritePackageNames =
          currentFavorites.map((map) => map['package_name'] as String).toSet();

      await txn.delete(_tableName);

      for (final app in apps) {
        final cache = AppCache(
          name: app.name,
          packageName: app.packageName,
          icon: app.icon,
          isSystemApp: app.isSystemApp,
          versionName: app.versionName,
          isFavorite: favoritePackageNames.contains(app.packageName),
        );

        await txn.insert(
          _tableName,
          cache.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
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
