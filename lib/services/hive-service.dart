import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../models/settings.dart';
import '../models/calculator_ingredient.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  final _uuid = const Uuid();

  factory HiveService() {
    return _instance;
  }

  HiveService._internal();

  // Métodos para Recetas
  Future<List<Recipe>> getAllRecipes() async {
    final box = Hive.box<Recipe>('recipes');
    return box.values.toList();
  }

  Future<Recipe?> getRecipe(String id) async {
    final box = Hive.box<Recipe>('recipes');
    return box.get(id);
  }

  Future<String> addRecipe(Recipe recipe) async {
    final box = Hive.box<Recipe>('recipes');
    final id = _uuid.v4();
    final newRecipe = Recipe(
      id: id,
      name: recipe.name,
      description: recipe.description,
      portions: recipe.portions,
      ingredientIds: recipe.ingredientIds,
      procedure: recipe.procedure,
      imagePath: recipe.imagePath,
    );
    await box.put(id, newRecipe);
    return id;
  }

  Future<void> updateRecipe(Recipe recipe) async {
    final box = Hive.box<Recipe>('recipes');
    await box.put(recipe.id, recipe);
  }

  Future<void> deleteRecipe(String id) async {
    final box = Hive.box<Recipe>('recipes');
    await box.delete(id);

    // También eliminar los ingredientes asociados
    final ingredientsBox = Hive.box<Ingredient>('ingredients');
    final ingredientsToDelete = ingredientsBox.values.where((ing) => ing.recipeId == id).toList();
    for (var ing in ingredientsToDelete) {
      await ingredientsBox.delete(ing.id);
    }
  }

  // Métodos para Ingredientes
  Future<List<Ingredient>> getIngredientsForRecipe(String recipeId) async {
    final box = Hive.box<Ingredient>('ingredients');
    return box.values.where((ing) => ing.recipeId == recipeId).toList();
  }

  Future<Ingredient?> getIngredient(String id) async {
    final box = Hive.box<Ingredient>('ingredients');
    return box.get(id);
  }

  Future<String> addIngredient(Ingredient ingredient) async {
    final box = Hive.box<Ingredient>('ingredients');
    final id = _uuid.v4();
    final newIngredient = Ingredient(
      id: id,
      name: ingredient.name,
      quantity: ingredient.quantity,
      unit: ingredient.unit,
      price: ingredient.price,
      recipeId: ingredient.recipeId,
    );
    await box.put(id, newIngredient);
    return id;
  }

  Future<void> updateIngredient(Ingredient ingredient) async {
    final box = Hive.box<Ingredient>('ingredients');
    await box.put(ingredient.id, ingredient);
  }

  Future<void> deleteIngredient(String id) async {
    final box = Hive.box<Ingredient>('ingredients');
    await box.delete(id);
  }

  // Métodos para Configuraciones
  Future<Settings> getSettings() async {
    final box = Hive.box<Settings>('settings');
    return box.get('settings') ?? 
      Settings(isDarkMode: false, measurementSystem: 'metric');
  }

  Future<void> updateSettings(Settings settings) async {
    final box = Hive.box<Settings>('settings');
    await box.put('settings', settings);
  }

  Future<void> toggleDarkMode() async {
    final settings = await getSettings();
    final newSettings = settings.copyWithDarkMode(!settings.isDarkMode);
    await updateSettings(newSettings);
  }

  Future<void> setMeasurementSystem(String system) async {
    final settings = await getSettings();
    final newSettings = settings.copyWithMeasurementSystem(system);
    await updateSettings(newSettings);
  }

  // Métodos para Ingredientes de la Calculadora
  Future<List<CalculatorIngredient>> getAllCalculatorIngredients() async {
    final box = Hive.box<CalculatorIngredient>('calculator_ingredients');
    return box.values.toList();
  }

  Future<String> addCalculatorIngredient(CalculatorIngredient ingredient) async {
    final box = Hive.box<CalculatorIngredient>('calculator_ingredients');
    final id = _uuid.v4();
    final newIngredient = CalculatorIngredient(
      id: id,
      name: ingredient.name,
      quantity: ingredient.quantity,
      unit: ingredient.unit,
      price: ingredient.price,
    );
    await box.put(id, newIngredient);
    return id;
  }

  Future<void> updateCalculatorIngredient(CalculatorIngredient ingredient) async {
    final box = Hive.box<CalculatorIngredient>('calculator_ingredients');
    await box.put(ingredient.id, ingredient);
  }

  Future<void> deleteCalculatorIngredient(String id) async {
    final box = Hive.box<CalculatorIngredient>('calculator_ingredients');
    await box.delete(id);
  }

  Future<void> clearAllCalculatorIngredients() async {
    final box = Hive.box<CalculatorIngredient>('calculator_ingredients');
    await box.clear();
  }

  // Métodos para guardar el número de miembros del equipo en la calculadora
  Future<void> saveTeamMembers(int members) async {
    final box = Hive.box<int>('calculator_settings');
    await box.put('team_members', members);
  }

  Future<int> getTeamMembers() async {
    final box = Hive.box<int>('calculator_settings');
    return box.get('team_members') ?? 1;
  }
}