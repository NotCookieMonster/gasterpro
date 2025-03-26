import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/recipe.dart';
import '../../services/hive-service.dart';
import 'recipe-detail-view.dart';

class RecipeListView extends StatefulWidget {
  const RecipeListView({Key? key}) : super(key: key);

  @override
  State<RecipeListView> createState() => _RecipeListViewState();
}

class _RecipeListViewState extends State<RecipeListView> {
  final HiveService _hiveService = HiveService();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Recipe>>(
      valueListenable: Hive.box<Recipe>('recipes').listenable(),
      builder: (context, box, _) {
        final recipes = box.values.toList();

        if (recipes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.book,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No hay recetas disponibles',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NewRecipeView(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Crear nueva receta'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return Dismissible(
              key: Key(recipe.id),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Confirmar'),
                      content: Text(
                          '¿Estás seguro de que quieres eliminar "${recipe.name}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    );
                  },
                );
              },
              onDismissed: (direction) async {
                final deletedRecipe = recipe;
                final deletedRecipeIngredients = 
                    await _hiveService.getIngredientsForRecipe(recipe.id);
                
                await _hiveService.deleteRecipe(recipe.id);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${recipe.name} eliminada'),
                    action: SnackBarAction(
                      label: 'Deshacer',
                      onPressed: () async {
                        // Restaurar la receta
                        await _hiveService.updateRecipe(deletedRecipe);
                        
                        // Restaurar ingredientes
                        for (var ingredient in deletedRecipeIngredients) {
                          await _hiveService.updateIngredient(ingredient);
                        }
                      },
                    ),
                  ),
                );
              },
              child: RecipeCard(
                recipe: recipe,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecipeDetailView(recipeId: recipe.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const RecipeCard({
    Key? key,
    required this.recipe,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: recipe.imagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  recipe.imagePath!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.restaurant,
                  color: Colors.grey,
                ),
              ),
        title: Text(
          recipe.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              recipe.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Porciones: ${recipe.portions}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        onTap: onTap,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
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
  final _descriptionController = TextEditingController();
  final _portionsController = TextEditingController(text: '1');
  final _procedureController = TextEditingController();
  List<String> _ingredientIds = [];
  String? _imagePath;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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

          // Descripción
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Descripción breve',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
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
    final _ingredientNameController = TextEditingController();
    final _quantityController = TextEditingController();
    String _selectedUnit = 'g';
    final List<String> _units = [
      'g', 'kg', 'ml', 'l', 'cdta', 'cda', 'taza', 'pizca', 'unidad'
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nuevo Ingrediente'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _ingredientNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del ingrediente',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Cantidad',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          decoration: const InputDecoration(
                            labelText: 'Unidad',
                            border: OutlineInputBorder(),
                          ),
                          items: _units.map((unit) {
                            return DropdownMenuItem<String>(
                              value: unit,
                              child: Text(unit),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedUnit = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    // Validar y agregar ingrediente
                    if (_ingredientNameController.text.isNotEmpty &&
                        _quantityController.text.isNotEmpty) {
                      // Implementar lógica para agregar ingrediente
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}