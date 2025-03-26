import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive/hive.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';

class WebStorageService {
  static final WebStorageService _instance = WebStorageService._internal();
  
  factory WebStorageService() {
    return _instance;
  }
  
  WebStorageService._internal();
  
  Future<void> ensureWebStorageWorks() async {
    if (!kIsWeb) return;
    
    try {
      // Test recipe box
      final recipeBox = Hive.box<Recipe>('recipes');
      print('Recipe box contains ${recipeBox.length} recipes');
      
      // Test if we can read/write
      if (recipeBox.isEmpty) {
        print('Recipe box is empty. Web storage may not be persisting data.');
      }
      
      // Test ingredients box
      final ingredientsBox = Hive.box<Ingredient>('ingredients');
      print('Ingredients box contains ${ingredientsBox.length} ingredients');
    } catch (e) {
      print('Error checking web storage: $e');
    }
  }
  
  // This method can help diagnose storage issues
  Future<String> getStorageDiagnostics() async {
    if (!kIsWeb) return "Not running on web";
    
    try {
      final recipeBox = Hive.box<Recipe>('recipes');
      final ingredientsBox = Hive.box<Ingredient>('ingredients');
      
      return 'Recipes: ${recipeBox.length}, Ingredients: ${ingredientsBox.length}';
    } catch (e) {
      return 'Error: $e';
    }
  }
}