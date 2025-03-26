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
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // Implementar búsqueda de recetas
              },
            ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
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
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewRecipeView(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// Vista para crear una nueva receta
class NewRecipeView extends StatelessWidget {
  const NewRecipeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Receta'),
        actions: [
          TextButton(
            onPressed: () {
              // Guardar la receta
              Navigator.pop(context);
            },
            child: const Text(
              'Aceptar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: const NewRecipeForm(),
    );
  }
}

// Formulario para crear/editar recetas
class NewRecipeForm extends StatefulWidget {
  const NewRecipeForm({Key? key}) : super(key: key);

  @override
  State<NewRecipeForm> createState() => _NewRecipeFormState();
}

class _NewRecipeFormState extends State<NewRecipeForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _portionsController = TextEditingController(text: '1');
  final _procedureController = TextEditingController();
  List<String> _ingredientIds = [];
  String? _imagePath;

  @override
  void dispose() {
    _nameController.dispose();
    _portionsController.dispose();
    _procedureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Nombre de la receta
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la receta',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese un nombre';
              }
              return null;
            },
          ),
          const SizedBox(height: 16.0),

          // Porciones
          Row(
            children: [
              const Text('Porciones que satisface:'),
              const SizedBox(width: 16.0),
              Expanded(
                child: TextFormField(
                  controller: _portionsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese un número';
                    }
                    if (int.tryParse(value) == null || int.parse(value) < 1) {
                      return 'Debe ser un número válido mayor a 0';
                    }
                    return null;
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  int currentValue = int.tryParse(_portionsController.text) ?? 1;
                  if (currentValue > 1) {
                    setState(() {
                      _portionsController.text = (currentValue - 1).toString();
                    });
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  int currentValue = int.tryParse(_portionsController.text) ?? 1;
                  setState(() {
                    _portionsController.text = (currentValue + 1).toString();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Imagen de receta
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Imagen de receta:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  Center(
                    child: _imagePath != null
                        ? Image.network(
                            _imagePath!,
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            height: 150,
                            width: 150,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.add_photo_alternate,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          // Implementar tomar foto
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Tomar foto'),
                      ),
                      const SizedBox(width: 8.0),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Implementar seleccionar de galería
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Desde Galería'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          // Ingredientes
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ingredientes:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Mostrar formulario para agregar ingrediente
                          _showIngredientForm(context);
                        },
                        child: const Text('Nuevo ingrediente'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  // Lista de ingredientes
                  // Aquí se mostrarían los ingredientes agregados
                  // Implementar FutureBuilder para mostrar los ingredientes
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          // Procedimiento
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Procedimiento:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _procedureController,
                    decoration: const InputDecoration(
                      hintText: 'Escriba el procedimiento paso a paso...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 10,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el procedimiento';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32.0),

          // Botones de acción
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                ),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Guardar la receta
                    // Implementar guardado de receta con HiveService
                    Navigator.pop(context);
                  }
                },
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showIngredientForm(BuildContext context) {
    // Implementar formulario para agregar ingrediente
    // Puede ser un AlertDialog o una nueva pantalla
  }
}