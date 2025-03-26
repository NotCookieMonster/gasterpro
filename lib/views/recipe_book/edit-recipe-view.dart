import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _isSaving = false;

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
        final ingredients = await _hiveService.getIngredientsForRecipe(recipe.id);
        setState(() {
          _ingredients = ingredients;
        });
      }
    } catch (e) {
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imagePath = pickedFile.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  Future<void> _saveRecipe() async {
    if (_formKey.currentState!.validate() && _recipe != null) {
      if (_ingredients.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe haber al menos un ingrediente')),
        );
        return;
      }
      
      setState(() {
        _isSaving = true;
      });
      
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receta actualizada con éxito')),
        );
        
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  Future<void> _showIngredientForm(BuildContext context, [Ingredient? ingredient]) async {
    final _ingredientNameController = TextEditingController(text: ingredient?.name ?? '');
    final _quantityController = TextEditingController(
        text: ingredient?.quantity.toString() ?? '');
    
    final settings = await _hiveService.getSettings();
    String _selectedUnit = ingredient?.unit ?? (settings.measurementSystem == 'metric' ? 'g' : 'oz');
    final List<String> _units = settings.getCurrentUnits();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(ingredient == null ? 'Nuevo Ingrediente' : 'Editar Ingrediente'),
              content: SingleChildScrollView(
                child: Column(
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
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor complete todos los campos'),
                        ),
                      );
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
            onPressed: _isSaving ? null : _saveRecipe,
            child: _isSaving
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,)
                  )
                : const Text(
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
                errorStyle: TextStyle(color: Colors.red),
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
                      errorStyle: TextStyle(color: Colors.red),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
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
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_imagePath!),
                                height: 200,
                                width: 200,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              height: 200,
                              width: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
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
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Tomar foto'),
                        ),
                        const SizedBox(width: 8.0),
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
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
                    
                    if (_ingredients.isEmpty)
                      if (_ingredients.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'No hay ingredientes agregados',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        )
                      else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _ingredients.length,
                        itemBuilder: (context, index) {
                          final ingredient = _ingredients[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Text('•'),
                            title: Text('${ingredient.quantity} ${ingredient.unit} de ${ingredient.name}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteIngredient(ingredient),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
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
                        errorStyle: TextStyle(color: Colors.red),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32, 
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveRecipe,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32, 
                      vertical: 12,
                    ),
                  ),
                  child: _isSaving 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Confirmar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}