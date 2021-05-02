import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:possystem/helper/util.dart';
import 'package:possystem/models/maps/menu_map.dart';
import 'package:possystem/services/database.dart';

import 'catalog_model.dart';
import 'product_ingredient_model.dart';

class ProductModel extends ChangeNotifier {
  ProductModel({
    @required this.name,
    this.catalog,
    this.index = 0,
    this.price = 0,
    this.cost = 0,
    String id,
    Map<String, ProductIngredientModel> ingredients,
    DateTime createdAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        ingredients = ingredients ?? {},
        id = id ?? Util.uuidV4();

  String name;
  int index;
  num price;
  num cost;
  CatalogModel catalog;
  final String id;
  final Map<String, ProductIngredientModel> ingredients;
  final DateTime createdAt;

  // I/O

  factory ProductModel.fromMap(ProductMap map) {
    final product = ProductModel(
      id: map.id,
      name: map.name,
      index: map.index,
      price: map.price,
      cost: map.cost,
      createdAt: map.createdAt,
      ingredients: {
        for (var ingredient in map.ingredients)
          ingredient.id: ProductIngredientModel.fromMap(ingredient)
      },
    );

    product.ingredients.values.forEach((e) {
      e.product = product;
    });

    return product;
  }

  ProductMap toMap() {
    return ProductMap(
      id: id,
      name: name,
      index: index,
      price: price,
      cost: cost,
      createdAt: createdAt,
      ingredients: ingredients.values.map((e) => e.toMap()),
    );
  }

  // STATE CHANGE

  void updateIngredient(ProductIngredientModel ingredient) {
    if (!ingredients.containsKey(ingredient.id)) {
      ingredients[ingredient.id] = ingredient;
      final updateData = {ingredient.prefix: ingredient.toMap()};

      Database.instance.update(Collections.menu, updateData);
    }
    ingredientChanged();
  }

  ProductIngredientModel removeIngredient(String id) {
    print('remove product ingredient $id');

    final ingredient = ingredients.remove(id);
    final updateData = {'$prefix.ingredients.$id': null};
    Database.instance.update(Collections.menu, updateData);
    ingredientChanged();

    return ingredient;
  }

  void update({
    String name,
    int index,
    num price,
    num cost,
  }) {
    final updateData = _getUpdateData(
      name: name,
      index: index,
      price: price,
      cost: cost,
    );

    if (updateData.isEmpty) return;

    Database.instance.update(Collections.menu, updateData);

    notifyListeners();
  }

  void ingredientChanged() {
    catalog.productChanged();
    notifyListeners();
  }

  // HELPER

  Map<String, dynamic> _getUpdateData({
    String name,
    int index,
    num price,
    num cost,
  }) {
    final updateData = <String, dynamic>{};
    if (index != null && index != this.index) {
      this.index = index;
      updateData['$prefix.index'] = index;
    }
    if (price != null && price != this.price) {
      this.price = price;
      updateData['$prefix.price'] = price;
    }
    if (cost != null && cost != this.cost) {
      this.cost = cost;
      updateData['$prefix.cost'] = cost;
    }
    if (name != null && name != this.name) {
      this.name = name;
      updateData['$prefix.name'] = name;
    }
    return updateData;
  }

  bool has(String id) => ingredients.containsKey(id);
  ProductIngredientModel operator [](String id) => ingredients[id];

  // GETTER

  Iterable<ProductIngredientModel> get ingredientsWithQuantity {
    return ingredients.values.where((e) => e.quantities.isNotEmpty);
  }

  bool get isReady => name != null;
  String get prefix => '${catalog.id}.products.$id';
}
