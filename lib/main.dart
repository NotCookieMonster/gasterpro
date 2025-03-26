// Modify lib/main.dart to include web-specific Firebase initialization

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

// Importaciones de modelos
import 'models/recipe.dart';
import 'models/ingredient.dart';
import 'models/settings.dart';
import 'models/calculator_ingredient.dart';

// Importaciones de vistas
import 'views/home-view.dart';
import 'views/theme/app-theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Hive de manera diferente según la plataforma
  if (kIsWeb) {
    // Inicialización para web
    await Hive.initFlutter();
    
    // Note: You should also initialize Firebase for web here
    // If you want to add Firebase Storage for more robust image handling
    // This would require adding firebase packages to your pubspec.yaml

    
  } else {
    // Inicialización para móviles/desktop
    final appDocumentDirectory = await path_provider.getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDirectory.path);
  }
  
  // Registrar adaptadores
  Hive.registerAdapter(RecipeAdapter());
  Hive.registerAdapter(IngredientAdapter());
  Hive.registerAdapter(SettingsAdapter());
  Hive.registerAdapter(CalculatorIngredientAdapter());
  
  // Abrir cajas (boxes)
  try{
    await Hive.openBox<Recipe>('recipes');
    await Hive.openBox<Ingredient>('ingredients');
    await Hive.openBox<Settings>('settings');
    await Hive.openBox<CalculatorIngredient>('calculator_ingredients');
    await Hive.openBox<int>('calculator_settings');

    print('Succesfully opened all Hive Boxes');
  } catch (e) {
    print('Error opening Hive boxes: $e');
  }
  
  // Verificar si las configuraciones existen, si no, crear una por defecto
  final settingsBox = Hive.box<Settings>('settings');
  if (settingsBox.isEmpty) {
    settingsBox.put('settings', Settings(isDarkMode: false, measurementSystem: 'metric'));
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Settings>>(
      valueListenable: Hive.box<Settings>('settings').listenable(),
      builder: (context, box, _) {
        final settings = box.get('settings') ?? Settings(isDarkMode: false, measurementSystem: 'metric');
        
        return MaterialApp(
          title: 'Recetario Gastronómico',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const HomeView(),
        );
      },
    );
  }
  
  @override
  void dispose() {
    Hive.close();
    super.dispose();
  }
}