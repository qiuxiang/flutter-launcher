import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';

import 'apps.dart';

class Search extends SearchDelegate {
  final List<AppInfo> apps;

  Search(this.apps);

  @override
  buildActions(context) =>
      [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  buildLeading(context) => null;

  @override
  buildResults(context) => buildSuggestions(context);

  @override
  buildSuggestions(context) {
    where(it) => it.name.contains(query) || it.packageName.contains(query);
    return Apps(apps.where(where));
  }

  @override
  appBarTheme(context) => Theme.of(context);
}
