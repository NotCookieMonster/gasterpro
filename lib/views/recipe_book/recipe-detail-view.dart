import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../models/ingredient.dart';
import '../../services/hive-service.dart';
import 'edit-recipe-view.dart';
import '../../models/settings.dart';
import '../../services/image-service.dart';

class ConversionResult {
  final double quantity;
  final String unit;
  
  ConversionResult(this.quantity, this.unit);
}

class RecipeDetailView extends StatefulWidget {
  final String recipeId;
  Settings? _currentSettings;

  RecipeDetailView({
    Key? key,
    required this.recipeId,
  }) : super(key: key);

  @override
  State<RecipeDetailView> createState() => _RecipeDetailViewState();
}

class _RecipeDetailViewState extends State<RecipeDetailView> {
  final HiveService _hiveService = HiveService();
  int _currentPortions = 1;
  int _originalPortions = 1;
  bool _isLoading = true;
  Recipe? _recipe;
  List<Ingredient> _ingredients = [];
  Settings? _currentSettings;
  String? _debugError; // Added for debugging

  bool _isConvertibleUnit(String unit) {
    return _isMetricUnit(unit) || _isImperialUnit(unit);
  }

  bool _isMetricUnit(String unit) {
    return ['g', 'kg', 'ml', 'l'].contains(unit.toLowerCase());
  }

  bool _isImperialUnit(String unit) {
    return ['oz', 'lb', 'fl oz', 'gal'].contains(unit.toLowerCase());
  }

  ConversionResult _convertToImperial(double quantity, String unit) {
    switch (unit.toLowerCase()) {
      case 'g':
        return ConversionResult(quantity / 28.35, 'oz');
      case 'kg':
        return ConversionResult(quantity * 2.20462, 'lb');
      case 'ml':
        return ConversionResult(quantity / 29.5735, 'fl oz');
      case 'l':
        return ConversionResult(quantity * 0.264172, 'gal');
      default:
        return ConversionResult(quantity, unit);
    }
  }

  ConversionResult _convertToMetric(double quantity, String unit) {
    switch (unit.toLowerCase()) {
      case 'oz':
        return ConversionResult(quantity * 28.35, 'g');
      case 'lb':
        return ConversionResult(quantity / 2.20462, 'kg');
      case 'fl oz':
        return ConversionResult(quantity * 29.5735, 'ml');
      case 'gal':
        return ConversionResult(quantity / 0.264172, 'l');
      default:
        return ConversionResult(quantity, unit);
    }
  }

  @override
  void initState() {
    super.initState();
    print('RecipeDetailView - initState called for recipe ID: ${widget.recipeId}');
    _loadRecipeAndSettings();
  }

  Future<void> _loadRecipeAndSettings() async {
    print('RecipeDetailView - _loadRecipeAndSettings started');
    setState(() {
      _isLoading = true;
      _debugError = null;
    });

    try {
      print('Fetching recipe with ID: ${widget.recipeId}');
      final recipe = await _hiveService.getRecipe(widget.recipeId);
      print('Recipe fetched: ${recipe?.name ?? "null"}');
      
      if (recipe != null) {
        print('Fetching ingredients for recipe ID: ${widget.recipeId}');
        final ingredients = await _hiveService.getIngredientsForRecipe(widget.recipeId);
        print('Fetched ${ingredients.length} ingredients');

        print('Fetching settings');
        final settings = await _hiveService.getSettings();
        print('Settings fetched, measurement system: ${settings.measurementSystem}');
        
        widget._currentSettings = settings;
        
        setState(() {
          _recipe = recipe;
          _ingredients = ingredients;
          _originalPortions = recipe.portions;
          _currentPortions = recipe.portions;
          _currentSettings = settings;
        });
      } else {
        print('Recipe not found for ID: ${widget.recipeId}');
        setState(() {
          _debugError = 'Recipe not found';
        });
      }
    } catch (e) {
      print('Error in _loadRecipeAndSettings: $e');
      setState(() {
        _debugError = e.toString();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar la receta: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updatePortions(int value) {
    if (value >= 1) {
      setState(() {
        _currentPortions = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cargando...'),
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No se pudo cargar la receta'),
              if (_debugError != null) ...[
                const SizedBox(height: 8),
                Text('Error: $_debugError', 
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    try {
      return Scaffold(
        appBar: AppBar(
          title: Text(_recipe!.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditRecipeView(recipeId: _recipe!.id),
                  ),
                ).then((_) => _loadRecipeAndSettings());
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipe image - FIXED TO BE CROSS-PLATFORM COMPATIBLE
              if (_recipe!.imagePath != null)
                SizedBox(
                  width: double.infinity,
                  height: 250,
                  child: ImageService().displayImage(
                    _recipe!.imagePath,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.restaurant,
                    size: 80,
                    color: Colors.grey,
                  ),
                ),

              // Recipe Info Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and description
                    Text(
                      _recipe!.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    if (_recipe!.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _recipe!.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Portions adjustment
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
                              'Ajustar porciones:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  color: Theme.of(context).primaryColor,
                                  iconSize: 36,
                                  onPressed: _currentPortions > 1
                                      ? () => _updatePortions(_currentPortions - 1)
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$_currentPortions',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  color: Theme.of(context).primaryColor,
                                  iconSize: 36,
                                  onPressed: () => _updatePortions(_currentPortions + 1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Ingredients
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.restaurant, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Ingredientes:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            if (_ingredients.isEmpty)
                              const Text(
                                'No hay ingredientes disponibles',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _ingredients.length,
                                itemBuilder: (context, index) {
                                  final ingredient = _ingredients[index];
                                 
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '•',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            () {
                                              try {
                                                // Calculate adjusted quantity
                                                double quantity = ingredient.calculateAdjustedQuantity(
                                                  _originalPortions,
                                                  _currentPortions,
                                                );
                                                
                                                String unit = ingredient.unit;
                                                
                                                // Perform unit conversion if needed
                                                if (_currentSettings != null) {
                                                  if (_isConvertibleUnit(ingredient.unit)) {
                                                    if (_currentSettings!.measurementSystem == 'imperial' && _isMetricUnit(ingredient.unit)) {
                                                      // Convert from metric to imperial
                                                      final convertedResult = _convertToImperial(quantity, ingredient.unit);
                                                      unit = convertedResult.unit;
                                                      quantity = convertedResult.quantity;
                                                    } else if (_currentSettings!.measurementSystem == 'metric' && _isImperialUnit(ingredient.unit)) {
                                                      // Convert from imperial to metric
                                                      final convertedResult = _convertToMetric(quantity, ingredient.unit);
                                                      unit = convertedResult.unit;
                                                      quantity = convertedResult.quantity;
                                                    }
                                                  }
                                                }
                                                
                                                // Return formatted string
                                                return '${quantity.toStringAsFixed(1)} $unit de ${ingredient.name}';
                                              } catch (e) {
                                                print("Error calculating ingredient: $e");
                                                return '${ingredient.quantity} ${ingredient.unit} de ${ingredient.name}';
                                              }
                                            }(),
                                            style: const TextStyle(fontSize: 16),
                                          ),
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
                    
                    const SizedBox(height: 24),
                    
                    // Procedure
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.menu_book, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Procedimiento:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            Text(
                              _recipe!.procedure,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error rendering RecipeDetailView: $e');
      return Scaffold(
        appBar: AppBar(
          title: Text(_recipe?.name ?? 'Detalle de Receta'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error al mostrar los detalles de la receta'),
              if (kIsWeb) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error específico: $e',
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Volver al listado'),
              ),
            ],
          ),
        ),
      );
    }
  }
}