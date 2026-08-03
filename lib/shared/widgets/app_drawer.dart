import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(child: Text('InvoSys')),
          ListTile(
            leading: Icon(Icons.star, color: Colors.amber),
            title: Text('Home'),
            subtitle: Text('Dashboard Screen'),
            trailing: Icon(Icons.chevron_right),
            selectedTileColor: Colors.grey.shade200,
            onTap: () {},
            selected: true,
          ),
        ],
      ),
    );
  }
}
