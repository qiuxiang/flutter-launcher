import 'dart:typed_data';

class AppCache {
  final String name;
  final String packageName;
  final Uint8List? icon;
  final bool isSystemApp;
  final String? versionName;
  final int lastOpenedAt;

  AppCache({
    required this.name,
    required this.packageName,
    this.icon,
    required this.isSystemApp,
    this.versionName,
    this.lastOpenedAt = 0,
  });

  factory AppCache.fromMap(Map<String, dynamic> map) {
    return AppCache(
      name: map['name'] as String,
      packageName: map['package_name'] as String,
      icon: map['icon'] as Uint8List?,
      isSystemApp: (map['is_system_app'] as int) == 1,
      versionName: map['version_name'] as String?,
      lastOpenedAt: map['last_opened_at'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'package_name': packageName,
      'name': name,
      'icon': icon,
      'is_system_app': isSystemApp ? 1 : 0,
      'version_name': versionName,
      'last_opened_at': lastOpenedAt,
    };
  }
}
