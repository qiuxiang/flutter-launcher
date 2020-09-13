import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';

import 'apps.dart';

class Search extends SearchDelegate {
  final List<Application> apps;

  Search(this.apps);

  buildActions(context) =>
      [IconButton(icon: Icon(Icons.clear), onPressed: () => query = '')];

  buildLeading(context) => null;

  buildResults(context) => buildSuggestions(context);

  buildSuggestions(context) {
    final where =
        (it) => it.appName.contains(query) || it.packageName.contains(query);
    return Apps(this.apps.where(where));
  }

  appBarTheme(context) => Theme.of(context);
}
