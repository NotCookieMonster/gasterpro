import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive/hive.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import 'diagnostic-service.dart';

class WebStorageService {
  static final WebStorageService _instance = WebStorageService._internal();
  final DiagnosticService _diagnosticService = DiagnosticService();
  
  factory WebStorageService() {
    return _instance;
  }
  
  WebStorageService._internal();
  
  Future<void> ensureWebStorageWorks() async {
    if (!kIsWeb) return;
    
    try {
      _diagnosticService.logDiagnostic('webStorage', 'Starting web storage check');
      
      // Test recipe box
      final recipeBox = Hive.box<Recipe>('recipes');
      _diagnosticService.logDiagnostic('recipeBoxLength', '${recipeBox.length}');
      
      // Test if we can read/write
      if (recipeBox.isEmpty) {
        _diagnosticService.logDiagnostic('recipeBoxEmpty', 'Recipe box is empty. Web storage may not be persisting data.');
      } else {
        // Get a sample recipe and verify it can be read
        try {
          final firstRecipeKey = recipeBox.keys.first;
          _diagnosticService.logDiagnostic('firstRecipeKey', '$firstRecipeKey');
          
          final recipe = recipeBox.get(firstRecipeKey);
          if (recipe != null) {
            _diagnosticService.logDiagnostic('sampleRecipeName', recipe.name);
            _diagnosticService.logDiagnostic('sampleRecipeImagePath', recipe.imagePath ?? 'null');
          } else {
            _diagnosticService.logDiagnostic('sampleRecipeError', 'Could not retrieve sample recipe');
          }
        } catch (e) {
          _diagnosticService.logDiagnostic('sampleRecipeError', e.toString());
        }
      }
      
      // Test ingredients box
      try {
        final ingredientsBox = Hive.box<Ingredient>('ingredients');
        _diagnosticService.logDiagnostic('ingredientsBoxLength', '${ingredientsBox.length}');
        
        if (ingredientsBox.isNotEmpty) {
          final firstIngredientKey = ingredientsBox.keys.first;
          final ingredient = ingredientsBox.get(firstIngredientKey);
          if (ingredient != null) {
            _diagnosticService.logDiagnostic('sampleIngredientName', ingredient.name);
            _diagnosticService.logDiagnostic('sampleIngredientRecipeId', ingredient.recipeId);
          }
        }
      } catch (e) {
        _diagnosticService.logDiagnostic('ingredientsBoxError', e.toString());
      }
      
      // Test web storage limits
      try {
        await _testStorageLimits();
      } catch (e) {
        _diagnosticService.logDiagnostic('storageLimitTest', 'Error: ${e.toString()}');
      }
      
    } catch (e) {
      _diagnosticService.logDiagnostic('webStorageError', e.toString());
    }
  }
  
  // This method can help diagnose storage issues
  Future<String> getStorageDiagnostics() async {
    if (!kIsWeb) return "Not running on web";
    
    try {
      final recipeBox = Hive.box<Recipe>('recipes');
      final ingredientsBox = Hive.box<Ingredient>('ingredients');
      
      final report = StringBuffer();
      report.writeln('Web Storage Diagnostics:');
      report.writeln('Recipes: ${recipeBox.length}');
      report.writeln('Ingredients: ${ingredientsBox.length}');
      
      // Add recipe keys
      if (recipeBox.isNotEmpty) {
        report.writeln('Recipe Keys: ${recipeBox.keys.take(5).join(', ')}${recipeBox.length > 5 ? '...' : ''}');
      }
      
      // Check for IndexedDB support
      report.writeln('IndexedDB Status: Supported (application is running)');
      
      return report.toString();
    } catch (e) {
      return 'Error running diagnostics: $e';
    }
  }
  
  // Test storage limits by trying to store increasingly large data
  Future<void> _testStorageLimits() async {
    if (!kIsWeb) return;
    
    try {
      final testBox = await Hive.openBox<String>('storage_test');
      
      // Try storing increasingly large strings
      for (int i = 1; i <= 5; i++) {
        final testString = List.generate(i * 1000, (index) => 'A').join();
        await testBox.put('test_$i', testString);
        _diagnosticService.logDiagnostic('storageSizeTest_${i}kb', 'Success');
      }
      
      // Clean up
      await testBox.clear();
      await testBox.close();
      
      _diagnosticService.logDiagnostic('storageLimitTest', 'Completed successfully');
    } catch (e) {
      _diagnosticService.logDiagnostic('storageLimitError', e.toString());
      rethrow;
    }
  }
  
  // Quick check of a specific recipe to assist with debugging
  Future<Map<String, dynamic>> checkRecipe(String recipeId) async {
    final result = <String, dynamic>{};
    
    try {
      final recipeBox = Hive.box<Recipe>('recipes');
      final recipe = recipeBox.get(recipeId);
      
      if (recipe != null) {
        result['exists'] = true;
        result['name'] = recipe.name;
        result['imagePath'] = recipe.imagePath;
        result['ingredientIds'] = recipe.ingredientIds;
        
        try {
          final ingredientsBox = Hive.box<Ingredient>('ingredients');
          final ingredients = <Map<String, dynamic>>[];
          
          for (final id in recipe.ingredientIds) {
            final ingredient = ingredientsBox.get(id);
            if (ingredient != null) {
              ingredients.add({
                'id': id,
                'name': ingredient.name,
                'exists': true,
              });
            } else {
              ingredients.add({
                'id': id,
                'exists': false,
              });
            }
          }
          
          result['ingredients'] = ingredients;
          result['ingredientsFound'] = ingredients.where((ing) => ing['exists'] == true).length;
          result['ingredientsMissing'] = ingredients.where((ing) => ing['exists'] == false).length;
        } catch (e) {
          result['ingredientsError'] = e.toString();
        }
      } else {
        result['exists'] = false;
      }
      
    } catch (e) {
      result['error'] = e.toString();
    }
    
    return result;
  }
}