import 'package:flutter/widgets.dart';
import 'package:possystem/models/menu/product_ingredient_model.dart';
import 'package:possystem/services/database.dart';

import '../menu/catalog_model.dart';

class MenuModel extends ChangeNotifier {
  MenuModel() {
    loadFromDb();
  }

  Map<String, CatalogModel> catalogs;

  // I/O

  Future<void> loadFromDb() async {
    var snapshot = await Database.service.get(Collections.menu);
    buildFromMap(snapshot.data());

    notifyListeners();
  }

  void buildFromMap(Map<String, dynamic> data) {
    catalogs = {};
    if (data == null) return;

    try {
      data.forEach((key, value) {
        if (value is Map) {
          catalogs[key] = CatalogModel.fromMap({'id': key, ...value});
        }
      });
    } catch (e) {
      print(e);
    }
  }

  Map<String, Map<String, dynamic>> toMap() {
    return {for (var entry in catalogs.entries) entry.key: entry.value.toMap()};
  }

  // MENU STATE

  void updateCatalog(CatalogModel catalog) {
    if (!has(catalog.id)) {
      catalogs[catalog.id] = catalog;

      final updateData = {catalog.id: catalog.toMap()};
      Database.service.update(Collections.menu, updateData);
    }
    notifyListeners();
  }

  void removeCatalog(String id) {
    catalogs.remove(id);
    Database.service.update(Collections.menu, {id: null});
    notifyListeners();
  }

  Future<void> reorderCatalogs(List<CatalogModel> catalogs) async {
    for (var i = 0, n = catalogs.length; i < n; i++) {
      catalogs[i].update(index: i + 1);
    }

    notifyListeners();
  }

  // STOCK STATE

  void removeIngredient(String id) {
    final ingredients = productContainsIngredient(id);
    final updateData = {
      for (var ingredient in ingredients) ingredient.prefix: null
    };
    Database.service.update(Collections.menu, updateData);

    if (updateData.isNotEmpty) {
      ingredients.forEach((ingredient) {
        ingredient.product.ingredients.remove(id);
      });
      notifyListeners();
    }
  }

  void removeQuantity(String id) {
    final ingredients = productContainsQuantity(id);
    final updateData = {
      for (var ingredient in ingredients)
        '${ingredient.prefixQuantities}.$id': null
    };
    Database.service.update(Collections.menu, updateData);

    if (updateData.isNotEmpty) {
      ingredients.forEach((ingredient) => ingredient.quantities.remove(id));
      notifyListeners();
    }
  }

  List<ProductIngredientModel> productContainsIngredient(String id) {
    final result = <ProductIngredientModel>[];

    catalogs.values.forEach((catalog) {
      catalog.products.values.forEach((product) {
        if (product.has(id)) result.add(product[id]);
      });
    });

    return result;
  }

  List<ProductIngredientModel> productContainsQuantity(String id) {
    final result = <ProductIngredientModel>[];

    catalogs.values.forEach((catalog) {
      catalog.products.values.forEach((product) {
        product.ingredients.values.forEach((ingredient) {
          if (ingredient.has(id)) result.add(ingredient);
        });
      });
    });

    return result;
  }

  // HELPER

  bool has(String id) => catalogs.containsKey(id);
  bool hasCatalog(String name) =>
      !catalogs.values.every((catalog) => catalog.name != name);
  bool hasProduct(String name) => !catalogs.values.every((catalog) =>
      catalog.products.values.every((product) => product.name != name));
  CatalogModel operator [](String id) => catalogs[id];

  // GETTER

  List<CatalogModel> get catalogList {
    final catalogList = catalogs.values.toList();
    catalogList.sort((a, b) => a.index.compareTo(b.index));
    return catalogList;
  }

  int get newIndex {
    var maxIndex = -1;
    catalogs.forEach((key, catalog) {
      if (catalog.index > maxIndex) {
        maxIndex = catalog.index;
      }
    });
    return maxIndex + 1;
  }

  bool get isNotReady => catalogs == null;
  bool get isEmpty => catalogs.isEmpty;
}