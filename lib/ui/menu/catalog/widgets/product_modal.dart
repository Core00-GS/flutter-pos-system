import 'package:flutter/material.dart';
import 'package:possystem/components/circular_loading.dart';
import 'package:possystem/constants/constant.dart';
import 'package:possystem/constants/icons.dart';
import 'package:possystem/helper/validator.dart';
import 'package:possystem/models/menu/catalog_model.dart';
import 'package:possystem/models/objects/menu_object.dart';
import 'package:possystem/models/repository/menu_model.dart';
import 'package:possystem/models/menu/product_model.dart';
import 'package:possystem/ui/menu/menu_routes.dart';
import 'package:provider/provider.dart';

class ProductModal extends StatefulWidget {
  ProductModal({Key key, @required this.product}) : super(key: key);

  final ProductModel product;
  bool get isNew => product == null;

  @override
  _ProductModalState createState() => _ProductModalState();
}

class _ProductModalState extends State<ProductModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();

  bool isSaving = false;
  String errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(KIcons.back),
        ),
        actions: [_trailingAction()],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(kPadding),
          child: Center(child: _form()),
        ),
      ),
    );
  }

  void _onSubmit() {
    if (isSaving || !_formKey.currentState.validate()) return;

    final name = _nameController.text;

    if (widget.product?.name != name && MenuModel.instance.hasProduct(name)) {
      return setState(() => errorMessage = '產品名稱重複');
    }

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    final product = _updateProduct();

    widget.isNew
        ? Navigator.of(context).popAndPushNamed(
            MenuRoutes.product,
            arguments: product,
          )
        : Navigator.of(context).pop();
  }

  ProductModel _updateProduct() {
    final object = ProductObject(
      name: _nameController.text,
      price: num.tryParse(_priceController.text),
      cost: num.tryParse(_costController.text),
    );
    widget.product?.update(object);

    final catalog = widget.product?.catalog ?? context.read<CatalogModel>();
    final product = widget.product ??
        ProductModel(
          catalog: catalog,
          index: catalog.newIndex,
          name: object.name,
          price: object.price,
          cost: object.cost,
        );

    catalog.updateProduct(product);

    return product;
  }

  Widget _trailingAction() {
    return isSaving
        ? CircularLoading()
        : TextButton(
            onPressed: () => _onSubmit(),
            child: Text('儲存'),
          );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _nameField(),
          SizedBox(height: kMargin),
          _priceField(),
          SizedBox(height: kMargin),
          _costField(),
        ],
      ),
    );
  }

  Widget _nameField() {
    return TextFormField(
      controller: _nameController,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      autofocus: true,
      decoration: InputDecoration(
        labelText: '產品名稱，起司漢堡',
        errorText: errorMessage,
        filled: false,
      ),
      maxLength: 30,
      validator: Validator.textLimit('產品名稱', 30),
    );
  }

  Widget _priceField() {
    return TextFormField(
      controller: _priceController,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: '產品價格，給客人看的價錢',
        filled: false,
      ),
      validator: Validator.positiveNumber('產品價格'),
    );
  }

  Widget _costField() {
    return TextFormField(
      controller: _costController,
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: '產品成本，幫助你算出利潤',
        filled: false,
      ),
      onFieldSubmitted: (_) => _onSubmit(),
      validator: Validator.positiveNumber('產品成本'),
    );
  }

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.product?.name;
    _priceController.text = widget.product?.price?.toString();
    _costController.text = widget.product?.cost?.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _costController.dispose();
    super.dispose();
  }
}
