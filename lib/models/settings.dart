import 'package:hive/hive.dart';

part 'settings.g.dart';

@HiveType(typeId: 2)
class Settings extends HiveObject {
  @HiveField(0)
  bool isDarkMode;

  @HiveField(1)
  String measurementSystem; // 'metric' o 'imperial'

  Settings({
    required this.isDarkMode,
    required this.measurementSystem,
  });

  // Método para actualizar el modo oscuro
  Settings copyWithDarkMode(bool isDark) {
    return Settings(
      isDarkMode: isDark,
      measurementSystem: measurementSystem,
    );
  }

  // Método para actualizar el sistema de medición
  Settings copyWithMeasurementSystem(String system) {
    return Settings(
      isDarkMode: isDarkMode,
      measurementSystem: system,
    );
  }

  // Lista de unidades disponibles en el sistema métrico
  static List<String> getMetricUnits() {
    return ['g', 'kg', 'ml', 'l', 'cdta', 'cda', 'taza', 'pizca', 'unidad'];
  }

  // Lista de unidades disponibles en el sistema imperial
  static List<String> getImperialUnits() {
    return ['oz', 'lb', 'fl oz', 'gal', 'cup', 'tbsp', 'tsp', 'pinch', 'unit'];
  }

  // Obtener las unidades según el sistema de medición actual
  List<String> getCurrentUnits() {
    return measurementSystem == 'metric'
        ? getMetricUnits()
        : getImperialUnits();
  }
}