import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../models/recipe.dart';
import '../../models/ingredient.dart';
import '../../models/settings.dart';
import '../../services/hive-service.dart';
import '../../services/image-service.dart';

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
              // This is handled inside the form
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

class NewRecipeForm extends StatefulWidget {
  const NewRecipeForm({Key? key}) : super(key: key);

  @override
  State<NewRecipeForm> createState() => _NewRecipeFormState();
}

class _NewRecipeFormState extends State<NewRecipeForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _portionsController = TextEditingController(text: "1");
  final _procedureController = TextEditingController();
  final HiveService _hiveService = HiveService();
  final _uuid = const Uuid();
  
  List<Ingredient> _currentIngredients = [];
  String? _imagePath;
  bool _isSaving = false;

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

        final imageService = ImageService();
        final processedImage = await imageService.processPickedImage(pickedFile);
        setState(() {
          _imagePath = processedImage;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  void _showIngredientForm(BuildContext context) {
    final _ingredientNameController = TextEditingController();
    final _quantityController = TextEditingController();
    String _selectedUnit = 'g';
    
    // Get available units from settings
    _hiveService.getSettings().then((settings) {
    _selectedUnit = settings.measurementSystem == 'metric' ? 'g' : 'oz';
    });
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nuevo Ingrediente'),
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
                          child: FutureBuilder<Settings>(
                            future: _hiveService.getSettings(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              }
                              
                              final settings = snapshot.data ?? Settings(isDarkMode: false, measurementSystem: 'metric');
                              final units = settings.getCurrentUnits();
                              
                              return DropdownButtonFormField<String>(
                                value: _selectedUnit,
                                decoration: const InputDecoration(
                                  labelText: 'Unidad',
                                  border: OutlineInputBorder(),
                                ),
                                items: units.map((unit) {
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
                              );
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
                      
                      final newIngredient = Ingredient(
                        id: _uuid.v4(),
                        name: _ingredientNameController.text,
                        quantity: double.tryParse(_quantityController.text) ?? 0,
                        unit: _selectedUnit,
                        recipeId: '', // Will be assigned when recipe is saved
                      );
                      
                      this.setState(() {
                        _currentIngredients.add(newIngredient);
                      });
                      
                      Navigator.of(context).pop();
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
  }

  Future<void> _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      if (_currentIngredients.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe agregar al menos un ingrediente')),
        );
        return;
      }
      
      setState(() {
        _isSaving = true;
      });
      
      try {
        // Create recipe ID
        final recipeId = _uuid.v4();
        
        // Save ingredients first
        List<String> ingredientIds = [];
        for (var ingredient in _currentIngredients) {
          // Update the recipe ID reference
          final newIngredient = Ingredient(
            id: ingredient.id,
            name: ingredient.name,
            quantity: ingredient.quantity,
            unit: ingredient.unit,
            recipeId: recipeId,
          );
          
          final ingredientID = await _hiveService.addIngredient(newIngredient);
          ingredientIds.add(ingredientID);
        }
        
        // Create and save the recipe
        final newRecipe = Recipe(
          id: recipeId,
          name: _nameController.text,
          description: _descriptionController.text.isEmpty ? _nameController.text : _descriptionController.text,
          portions: int.parse(_portionsController.text),
          ingredientIds: ingredientIds,
          procedure: _procedureController.text,
          imagePath: _imagePath,
        );
        
        await _hiveService.addRecipe(newRecipe);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receta guardada exitosamente')),
        );
        
        if (!mounted) return;
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar la receta: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Recipe name
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
          const SizedBox(height: 24.0),

          // Description (optional)
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Descripción breve (opcional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24.0),

          // Portions section
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
          const SizedBox(height: 24.0),

          // Recipe image section - Separated and cleaner
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Center(
                    child: _imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ImageService().displayImage(
                              _imagePath, 
                              width: 200, 
                              height: 200,
                              fit: BoxFit.cover
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
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Tomar foto'),
                      ),
                      const SizedBox(width: 16.0),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
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
          const SizedBox(height: 24.0),

          // Ingredients section - With visual separation
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        onPressed: () => _showIngredientForm(context),
                        child: const Text('Nuevo ingrediente'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  // List of ingredients with bullet points
                  if (_currentIngredients.isEmpty)
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
                      itemCount: _currentIngredients.length,
                      itemBuilder: (context, index) {
                        final ingredient = _currentIngredients[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const Text('• '),
                              Expanded(
                                child: Text(
                                  '${ingredient.quantity} ${ingredient.unit} de ${ingredient.name}',
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    _currentIngredients.remove(ingredient);
                                  });
                                },
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
          const SizedBox(height: 24.0),

          // Procedure section
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16.0),
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

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                onPressed: _isSaving ? null : _saveRecipe,
                child: _isSaving 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirmar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}