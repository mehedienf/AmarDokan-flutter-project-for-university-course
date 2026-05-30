import 'package:flutter/material.dart';
import 'package:amar_dokan/models/product_model.dart';
import 'package:amar_dokan/providers/product_provider.dart';
import 'package:provider/provider.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  // snackbar
  void _showSnackBar(BuildContext context, String message, Color? color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
        backgroundColor: color,
      ),
    );
  }

  // Delete Alert Dialog
  void _showDeleteAlertDialog(BuildContext context,String title,String content, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Expanded(
          child: AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // used to dismiss the dialog
                },
                child: Text('No'),
              ),
              TextButton(
                onPressed: () {
                  Provider.of<ProductProvider>(
                    context,
                    listen: false,
                  ).removeProduct(index);
                  Navigator.of(context).pop();
                  _showSnackBar(context, 'Product deleted successfully!', Colors.green);
                },
                child: Text('Yes'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Add Product Dialog
  void _showAddProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Expanded(
          child: AlertDialog(
            title: Text('Add Product'),
            content: Padding(
              padding: EdgeInsetsGeometry.all(10),
              child: Column(
                mainAxisSize: .min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: 'Product Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 5),
                  TextField(
                    controller: priceController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: 'Unit Price',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 5),
                  TextField(
                    controller: quantityController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      // hintText: 'Quantity',
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: .spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.lightGreen,
                        ),
                        onPressed: () {
                          final name = nameController.text.trim();
                          final priceText = priceController.text.trim();
                          final price = double.tryParse(priceText);
                          final quantityText = quantityController.text.trim();
                          final quantity = int.tryParse(quantityText);

                          if (name != '' && price != null && quantity != null) {
                            Provider.of<ProductProvider>(
                              context,
                              listen: false,
                            ).addProduct(
                              Product(
                                name: name,
                                price: price,
                                quantity: quantity,
                              ),
                            );
                            Navigator.of(context).pop();
                            _showSnackBar(context, 'Product added successfully!', Colors.green);
                          }
                          else
                          {
                            _showSnackBar(context, 'Fill the correct informations', Colors.red);
                          }
                        },
                        child: Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: .center,
      children: [
        ElevatedButton(
          onPressed: () {
            _showAddProductDialog(context);
          },
          child: Text('Add Product'),
        ),
        SizedBox(height: 2),
        Expanded(
          child: Column(
            children: [
              // Text('Inventory List'),
              Consumer<ProductProvider>(
                builder: (context, provider, child) {
                  return Expanded(
                    child: ListView.builder(
                      itemCount: provider.products.length,
                      itemBuilder: (context, index) {
                        final product = provider.products[index];
                        return GestureDetector(
                          onTap: () => _showDeleteAlertDialog(
                            context,
                            'Delete',
                            'Are you sure?',
                            index,
                          ), // net to configure this to show a confirmation dialog before deletion
                          child: ListTile(
                            title: Text(product.name),
                            subtitle: Text(
                              'Price: \$${product.price}, Quantity: ${product.quantity}',
                            ),
                            trailing: IconButton(
                              onPressed: () {
                                _showDeleteAlertDialog(
                                  context,
                                  'Delete',
                                  'Are you sure?',
                                  index,
                                );
                              },
                              icon: Icon(Icons.delete, color: Colors.red),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
