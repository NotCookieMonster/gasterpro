import 'package:flutter/material.dart';
import 'recipe_book/recipe-list-view.dart';
import 'calculator/calculator-view.dart';
import 'settings/settings-view.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const RecipeListView(),
    const CalculatorView(),
    const SettingsView(),
  ];

  final List<String> _titles = [
    'Recetario',
    'Calculadora',
    'Configuración',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        elevation: 0,
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: () {
                _showSortOptions(context);
              },
              tooltip: 'Ordenar recetas',
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.book),
              label: 'Recetario',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calculate),
              label: 'Calculadora',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Configuración',
            ),
          ],
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
        ),
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Ordenar por'),
                subtitle: const Text('Elija una opción para ordenar sus recetas'),
                leading: const Icon(Icons.sort),
                tileColor: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
              ListTile(
                title: const Text('Nombre (A-Z)'),
                leading: const Icon(Icons.sort_by_alpha),
                onTap: () {
                  // Implement sorting logic
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Más recientes primero'),
                leading: const Icon(Icons.access_time),
                onTap: () {
                  // Implement sorting logic
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Más antiguas primero'),
                leading: const Icon(Icons.history),
                onTap: () {
                  // Implement sorting logic
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}