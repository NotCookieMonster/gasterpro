import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../models/ingredient.dart';
import '../../services/hive-service.dart';
import 'edit-recipe-view.dart';
import '../../models/settings.dart';
import '../../services/image-service.dart';
import '../../services/diagnostic-service.dart'; // New diagnostic service

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
  final DiagnosticService _diagnosticService = DiagnosticService(); // Diagnostic service
  int _currentPortions = 1;
  int _originalPortions = 1;
  bool _isLoading = true;
  Recipe? _recipe;
  List<Ingredient> _ingredients = [];
  Settings? _currentSettings;
  String? _debugError;
  Map<String, String> _diagnosticInfo = {}; // Collected diagnostic info

  // Tracking load stages for diagnostic purposes
  bool _recipeLoaded = false;
  bool _ingredientsLoaded = false;
  bool _settingsLoaded = false;

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
    try {
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
    } catch (e) {
      _logDiagnostic('convertToImperial', 'Error: $e');
      return ConversionResult(quantity, unit);
    }
  }

  ConversionResult _convertToMetric(double quantity, String unit) {
    try {
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
    } catch (e) {
      _logDiagnostic('convertToMetric', 'Error: $e');
      return ConversionResult(quantity, unit);
    }
  }

  // Helper method for diagnostic logging
  void _logDiagnostic(String key, String value) {
    print('DIAGNOSTIC - $key: $value');
    setState(() {
      _diagnosticInfo[key] = value;
    });
    _diagnosticService.logDiagnostic(key, value);
  }

  @override
  void initState() {
    super.initState();
    _logDiagnostic('initState', 'Starting with recipeId: ${widget.recipeId}');
    _logDiagnostic('platform', kIsWeb ? 'Web' : 'Mobile');
    
    // Initialize diagnostic service
    _diagnosticService.initialize();
    
    _loadRecipeAndSettings();
  }

  // Progressive loading approach - one step at a time
  Future<void> _loadRecipeAndSettings() async {
    _logDiagnostic('loadStart', 'Beginning to load data');
    setState(() {
      _isLoading = true;
      _debugError = null;
    });

    try {
      // Step 1: Load recipe
      _logDiagnostic('recipeLoad', 'Attempting to load recipe: ${widget.recipeId}');
      final recipe = await _hiveService.getRecipe(widget.recipeId);
      _logDiagnostic('recipeResult', recipe != null ? 'Recipe loaded successfully' : 'Recipe is null');
      
      if (recipe != null) {
        setState(() {
          _recipe = recipe;
          _recipeLoaded = true;
          _originalPortions = recipe.portions;
          _currentPortions = recipe.portions;
        });
        
        // Log image path info
        _logDiagnostic('imagePath', recipe.imagePath ?? 'No image path');
        
        // Step 2: Load ingredients
        _logDiagnostic('ingredientsLoad', 'Loading ingredients');
        try {
          final ingredients = await _hiveService.getIngredientsForRecipe(widget.recipeId);
          _logDiagnostic('ingredientsCount', '${ingredients.length} ingredients loaded');
          
          setState(() {
            _ingredients = ingredients;
            _ingredientsLoaded = true;
          });
        } catch (e) {
          _logDiagnostic('ingredientsError', e.toString());
        }
        
        // Step 3: Load settings
        _logDiagnostic('settingsLoad', 'Loading settings');
        try {
          final settings = await _hiveService.getSettings();
          _logDiagnostic('settingsSystem', settings.measurementSystem);
          
          setState(() {
            _currentSettings = settings;
            widget._currentSettings = settings;
            _settingsLoaded = true;
          });
        } catch (e) {
          _logDiagnostic('settingsError', e.toString());
        }
      } else {
        _logDiagnostic('recipeNotFound', 'Recipe not found for ID: ${widget.recipeId}');
        setState(() {
          _debugError = 'Recipe not found';
        });
      }
    } catch (e) {
      _logDiagnostic('loadError', e.toString());
      setState(() {
        _debugError = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _logDiagnostic('loadComplete', 'Loading completed');
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
    // Display loading screen
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

    // Display error screen if recipe is null
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
              // Diagnostic information display
              if (_diagnosticInfo.isNotEmpty) ...[
                const Text('Diagnostic Information:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  width: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _diagnosticInfo.entries.map((entry) => 
                        Text('${entry.key}: ${entry.value}',
                          style: const TextStyle(fontSize: 10),
                        )
                      ).toList(),
                    ),
                  ),
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

    // Add a try-catch block around the entire UI rendering
    try {
      return Scaffold(
        appBar: AppBar(
          title: Text(_recipe!.name),
          actions: [
            // Add a diagnostic button
            if (kIsWeb)
              IconButton(
                icon: const Icon(Icons.bug_report),
                onPressed: () {
                  _showDiagnosticInfo(context);
                },
                tooltip: 'Show Diagnostics',
              ),
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
              // Recipe image with error handling
              _buildImageSection(),
              
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
                    _buildPortionsSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Ingredients with error handling
                    _buildIngredientsSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Procedure
                    _buildProcedureSection(),
                    
                    // Diagnostic panel for web
                    if (kIsWeb) ...[
                      const SizedBox(height: 24),
                      _buildDiagnosticPanel(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      _logDiagnostic('renderError', e.toString());
      
      // Fallback UI in case of rendering error
      return Scaffold(
        appBar: AppBar(
          title: Text(_recipe?.name ?? 'Detalle de Receta'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error al mostrar los detalles de la receta'),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error específico: $e',
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              
              // Diagnostic information
              Container(
                width: 300,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _diagnosticInfo.entries.map((entry) => 
                      Text('${entry.key}: ${entry.value}',
                        style: const TextStyle(fontSize: 10),
                      )
                    ).toList(),
                  ),
                ),
              ),
              
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

  // Modularized UI components with individual error handling
  
  Widget _buildImageSection() {
    try {
      return SizedBox(
        width: double.infinity,
        height: 250,
        child: _recipe!.imagePath != null
          ? ImageService().displayImage(
              _recipe!.imagePath,
              fit: BoxFit.cover,
            )
          : Container(
              color: Colors.grey[300],
              child: const Icon(
                Icons.restaurant,
                size: 80,
                color: Colors.grey,
              ),
            ),
      );
    } catch (e) {
      _logDiagnostic('imageError', e.toString());
      return Container(
        width: double.infinity,
        height: 200,
        color: Colors.grey[300],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 40, color: Colors.red),
            const SizedBox(height: 8),
            Text('Error cargando imagen: ${e.toString().substring(0, min(30, e.toString().length))}...',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPortionsSection() {
    try {
      return Card(
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
      );
    } catch (e) {
      _logDiagnostic('portionsError', e.toString());
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error en sección de porciones: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }

  Widget _buildIngredientsSection() {
    try {
      return Card(
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
                    try {
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
                                _getIngredientText(ingredient),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      );
                    } catch (e) {
                      _logDiagnostic('ingredientRenderError_$index', e.toString());
                      return Text('Error en ingrediente #$index: $e',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      );
                    }
                  },
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      _logDiagnostic('ingredientsSectionError', e.toString());
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error en sección de ingredientes: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }

  String _getIngredientText(Ingredient ingredient) {
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
      _logDiagnostic('ingredientTextError_${ingredient.id}', e.toString());
      return '${ingredient.quantity} ${ingredient.unit} de ${ingredient.name} (Error: $e)';
    }
  }

  Widget _buildProcedureSection() {
    try {
      return Card(
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
      );
    } catch (e) {
      _logDiagnostic('procedureError', e.toString());
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error en sección de procedimiento: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }

  Widget _buildDiagnosticPanel() {
    return Card(
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bug_report, size: 20),
                SizedBox(width: 8),
                Text(
                  'Diagnóstico (Web):',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Receta ID: ${widget.recipeId}'),
            Text('Receta Cargada: ${_recipeLoaded ? 'Sí' : 'No'}'),
            Text('Ingredientes Cargados: ${_ingredientsLoaded ? 'Sí' : 'No'}'),
            Text('Ajustes Cargados: ${_settingsLoaded ? 'Sí' : 'No'}'),
            Text('Sistema de Medición: ${_currentSettings?.measurementSystem ?? "No configurado"}'),
            if (_recipe?.imagePath != null) 
              Text('Imagen: ${_recipe!.imagePath!.substring(0, min(20, _recipe!.imagePath!.length))}...'),
            ElevatedButton(
              onPressed: () {
                _showDiagnosticInfo(context);
              },
              child: const Text('Ver Diagnóstico Completo'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDiagnosticInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información de Diagnóstico'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Plataforma: ${kIsWeb ? "Web" : "Móvil"}', 
                  style: const TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                
                const Text('Información de carga:', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Receta cargada: ${_recipeLoaded ? "Sí" : "No"}'),
                Text('Ingredientes cargados: ${_ingredientsLoaded ? "Sí" : "No"}'),
                Text('Configuración cargada: ${_settingsLoaded ? "Sí" : "No"}'),
                const Divider(),
                
                const Text('Información de receta:', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
                Text('ID: ${_recipe?.id ?? "No disponible"}'),
                Text('Nombre: ${_recipe?.name ?? "No disponible"}'),
                Text('Porciones: ${_recipe?.portions ?? "No disponible"}'),
                Text('Imagen: ${_recipe?.imagePath ?? "No disponible"}'),
                const Divider(),
                
                const Text('Diagnóstico detallado:', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
                
                // All diagnostic info
                ..._diagnosticInfo.entries.map((entry) => 
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('${entry.key}: ${entry.value}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  )
                ).toList(),
                
                const Divider(),
                ElevatedButton(
                  onPressed: () {
                    _diagnosticService.downloadDiagnostics();
                  },
                  child: const Text('Descargar Diagnóstico'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
  
  // Helper function to get min value
  int min(int a, int b) {
    return a < b ? a : b;
  }
}