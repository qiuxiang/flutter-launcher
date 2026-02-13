import 'package:flutter/material.dart';

import 'apps.dart';
import 'model.dart';

class Search extends SearchDelegate {
  final List<AppCache> apps;
  final Function(AppCache)? onOpen;

  Search(this.apps, {this.onOpen});

  @override
  buildActions(context) =>
      [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  buildLeading(context) => null;

  @override
  buildResults(context) => buildSuggestions(context);

  @override
  buildSuggestions(context) {
    where(it) =>
        it.name.toLowerCase().contains(query.toLowerCase()) ||
        it.packageName.toLowerCase().contains(query.toLowerCase());
    return Apps(apps.where(where), onOpen: onOpen);
  }

  @override
  appBarTheme(context) => Theme.of(context);
}
