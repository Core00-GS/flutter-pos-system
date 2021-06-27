import 'package:flutter/material.dart';
import 'package:possystem/components/radio_text.dart';
import 'package:possystem/components/style/single_row_warp.dart';
import 'package:possystem/models/menu/product_ingredient_model.dart';
import 'package:possystem/models/order/order_ingredient_model.dart';
import 'package:possystem/models/order/order_product_model.dart';
import 'package:possystem/models/repository/cart_model.dart';

class OrderIngredientList extends StatefulWidget {
  final bool isPortrait;

  const OrderIngredientList({
    Key? key,
    required this.isPortrait,
  }) : super(key: key);

  @override
  _OrderIngredientListState createState() => _OrderIngredientListState();
}

class _OrderIngredientListState extends State<OrderIngredientList> {
  static const QUANTITY_GROUP = 'order.quantities';
  static const INGREDIENT_GROUP = 'order.ingredients';

  ProductIngredientModel? selectedIngredient;

  String? selectedQuantityId;

  @override
  Widget build(BuildContext context) {
    if (CartModel.instance.isEmpty) {
      return _emptyWidget(context, '請選擇產品來設定其成份');
    }
    if (!CartModel.instance.isSameProducts) {
      return _emptyWidget(context, '請選擇相同的產品來設定其成份');
    }

    final product = CartModel.instance.products.first.product;
    final ingredients = product.ingredientsWithQuantity;
    if (ingredients.isEmpty) {
      return _emptyWidget(context, '該產品無可設定的成份');
    }

    selectedIngredient ??= ingredients.first;
    selectedQuantityId =
        CartModel.instance.getSelectedQuantityId(selectedIngredient!);

    return _build([
      _ingredientsRow(ingredients),
      _quantitiesRow(),
    ]);
  }

  @override
  void dispose() {
    OrderProductModel.removeListener(
      _listener,
      OrderProductListenerTypes.selection,
    );
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    OrderProductModel.addListener(
      _listener,
      OrderProductListenerTypes.selection,
    );
  }

  Widget _build(List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _emptyWidget(BuildContext context, String ingredientMessage) {
    selectedIngredient = null;

    return _build([
      SingleRowWrap(
        children: <Widget>[RadioText.empty(ingredientMessage)],
      ),
      SingleRowWrap(
        children: <Widget>[RadioText.empty('請選擇成份來設定份量')],
      ),
    ]);
  }

  Widget _ingredientsRow(Iterable<ProductIngredientModel> ingredients) {
    return SingleRowWrap(children: <Widget>[
      for (var ingredient in ingredients)
        RadioText(
          onSelected: () {
            setState(() => selectedIngredient = ingredient);
          },
          groupId: INGREDIENT_GROUP,
          value: ingredient.id,
          child: Text(ingredient.name),
        ),
    ]);
  }

  void _listener() => setState(() {});

  Widget _quantitiesRow() {
    RadioText.clearSelected(QUANTITY_GROUP);

    return SingleRowWrap(children: <Widget>[
      _quantityDefaultOption(),
      for (final quantity in selectedIngredient!.items)
        RadioText(
          onSelected: () {
            final ingredient = OrderIngredientModel(
              ingredient: selectedIngredient!,
              quantity: quantity,
            );
            CartModel.instance.updateSelectedIngredient(ingredient);
          },
          groupId: QUANTITY_GROUP,
          value: quantity.id,
          isSelected: quantity.id == selectedQuantityId,
          child: Text('${quantity.name}（${quantity.amount}）'),
        ),
    ]);
  }

  Widget _quantityDefaultOption() {
    return RadioText(
      onSelected: () {
        CartModel.instance.removeSelectedIngredient(selectedIngredient!.id);
      },
      groupId: QUANTITY_GROUP,
      value: CartModel.DEFAULT_QUANTITY_ID,
      isSelected: selectedQuantityId == CartModel.DEFAULT_QUANTITY_ID,
      child: Text('預設值（${selectedIngredient!.amount}）'),
    );
  }
}