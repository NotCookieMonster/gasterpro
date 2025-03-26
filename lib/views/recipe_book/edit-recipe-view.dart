import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../models/ingredient.dart';
import '../../services/hive-service.dart';

class EditRecipeView extends StatefulWidget {
  final String recipeId;

  const EditRecipeView({
    Key? key,
    required this.recipeId,
  }) : super(key: key);

  @override
  State<EditRecipeView> createState() => _EditRecipeViewState();
}

class _EditRecipeViewState extends State<EditRecipeView> {
  final HiveService _hiveService = HiveService();
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _portionsController = TextEditingController();
  final _procedureController = TextEditingController();
  
  Recipe? _recipe;
  List<Ingredient> _ingredients = [];
  String? _imagePath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final recipe = await _hiveService.getRecipe(widget.recipeId);
      if (recipe != null) {
        _recipe = recipe;
        _nameController.text = recipe.name;
        _descriptionController.text = recipe.description;
        _portionsController.text = recipe.portions.toString();
        _procedureController.text = recipe.procedure;
        _imagePath = recipe.imagePath;

        // Cargar ingredientes
        _ingredients = await _hiveService.getIngredientsForRecipe(recipe.id);
      }
    } catch (e) {
      // Manejar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar la receta: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _portionsController.dispose();
    _procedureController.dispose();
    super.dispose();
  }

  Future<void> _saveRecipe() async {
    if (_formKey.currentState!.validate() && _recipe != null) {
      try {
        // Actualizar receta
        final updatedRecipe = Recipe(
          id: _recipe!.id,
          name: _nameController.text,
          description: _descriptionController.text,
          portions: int.parse(_portionsController.text),
          ingredientIds: _recipe!.ingredientIds,
          procedure: _procedureController.text,
          imagePath: _imagePath,
        );

        await _hiveService.updateRecipe(updatedRecipe);
        
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receta actualizada con éxito')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  Future<void> _showIngredientForm(BuildContext context, [Ingredient? ingredient]) async {
    final _ingredientNameController = TextEditingController(text: ingredient?.name ?? '');
    final _quantityController = TextEditingController(
        text: ingredient?.quantity.toString() ?? '');
    String _selectedUnit = ingredient?.unit ?? 'g';
    final settings = await _hiveService.getSettings();
    final List<String> _units = settings.getCurrentUnits();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(ingredient == null ? 'Nuevo Ingrediente' : 'Editar Ingrediente'),
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
                    if (_ingredientNameController.text.isNotEmpty &&
                        _quantityController.text.isNotEmpty) {
                      Navigator.of(context).pop({
                        'name': _ingredientNameController.text,
                        'quantity': double.tryParse(_quantityController.text) ?? 0,
                        'unit': _selectedUnit,
                      });
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

    if (result != null && _recipe != null) {
      if (ingredient == null) {
        // Crear nuevo ingrediente
        final newIngredient = Ingredient(
          id: '', // Se asignará en el servicio
          name: result['name'],
          quantity: result['quantity'],
          unit: result['unit'],
          recipeId: _recipe!.id,
        );
        
        final ingredientId = await _hiveService.addIngredient(newIngredient);
        
        // Actualizar la lista de ingredientes de la receta
        final updatedRecipe = Recipe(
          id: _recipe!.id,
          name: _recipe!.name,
          description: _recipe!.description,
          portions: _recipe!.portions,
          ingredientIds: [..._recipe!.ingredientIds, ingredientId],
          procedure: _recipe!.procedure,
          imagePath: _recipe!.imagePath,
        );
        
        await _hiveService.updateRecipe(updatedRecipe);
      } else {
        // Actualizar ingrediente existente
        final updatedIngredient = Ingredient(
          id: ingredient.id,
          name: result['name'],
          quantity: result['quantity'],
          unit: result['unit'],
          recipeId: _recipe!.id,
          price: ingredient.price,
        );
        
        await _hiveService.updateIngredient(updatedIngredient);
      }
      
      // Recargar ingredientes
      _loadRecipe();
    }
  }

  Future<void> _deleteIngredient(Ingredient ingredient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text('¿Estás seguro de eliminar el ingrediente "${ingredient.name}"?'),
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
      ),
    );

    if (confirmed == true && _recipe != null) {
      // Eliminar el ingrediente
      await _hiveService.deleteIngredient(ingredient.id);
      
      // Actualizar la lista de ingredientes de la receta
      final updatedIngredientIds = _recipe!.ingredientIds
          .where((id) => id != ingredient.id)
          .toList();
      
      final updatedRecipe = Recipe(
        id: _recipe!.id,
        name: _recipe!.name,
        description: _recipe!.description,
        portions: _recipe!.portions,
        ingredientIds: updatedIngredientIds,
        procedure: _recipe!.procedure,
        imagePath: _recipe!.imagePath,
      );
      
      await _hiveService.updateRecipe(updatedRecipe);
      
      // Recargar ingredientes
      _loadRecipe();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Editar Receta'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_recipe == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('No se pudo cargar la receta'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Receta'),
        actions: [
          TextButton(
            onPressed: _saveRecipe,
            child: const Text(
              'Aceptar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Form(
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
                          onPressed: () => _showIngredientForm(context),
                          child: const Text('Nuevo ingrediente'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    // Lista de ingredientes
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _ingredients.length,
                      itemBuilder: (context, index) {
                        final ingredient = _ingredients[index];
                        return ListTile(
                          title: Text('${ingredient.quantity} ${ingredient.unit} de ${ingredient.name}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showIngredientForm(context, ingredient),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteIngredient(ingredient),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
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
                  onPressed: _saveRecipe,
                  child: const Text('Confirmar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}