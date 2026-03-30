import 'package:flutter/material.dart';
import 'package:amar_dokan/models/product_model.dart';
import 'package:amar_dokan/providers/product_provider.dart';
import 'package:provider/provider.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  // Custom Delete Alert Dialog
  dynamic myDeleteAlertDialog(context, title, content, index) {
    return showDialog(
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
                },
                child: Text('Yes'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            Provider.of<ProductProvider>(
              context,
              listen: false,
            ).addProduct(Product(name: 'Pen', price: 5));
          },
          child: Text('Add New Item'),
        ),
        SizedBox(height: 2),
        Expanded(
          child: Column(
            children: [
              Text('Inventory List'),
              Consumer<ProductProvider>(
                builder: (context, provider, child) {
                  return Expanded(
                    child: ListView.builder(
                      itemCount: provider.products.length,
                      itemBuilder: (context, index) {
                        final product = provider.products[index];
                        return GestureDetector(
                          onTap: () => myDeleteAlertDialog(context, 'Delete', 'Are you sure?', index), // net to configure this to show a confirmation dialog before deletion
                          child: ListTile(
                            title: Text(product.name),
                            subtitle: Text('Price: \$${product.price}'),
                            trailing: IconButton(
                              onPressed: () {
                                myDeleteAlertDialog(context, 'Delete', 'Are you sure?', index);
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
