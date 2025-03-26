import 'package:hive/hive.dart';

part 'ingredient.g.dart';

@HiveType(typeId: 1)
class Ingredient extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double quantity;

  @HiveField(3)
  String unit;

  @HiveField(4)
  double? price;

  @HiveField(5)
  String recipeId;

  Ingredient({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.price,
    required this.recipeId,
  });

  // Método para calcular la cantidad ajustada según la regla de tres
  // basada en el número de porciones original y el nuevo número de porciones
  double calculateAdjustedQuantity(int originalPortions, int newPortions) {
    return (quantity * newPortions) / originalPortions;
  }

  // Método para crear una copia del ingrediente con cantidad ajustada
  Ingredient copyWithAdjustedQuantity(int originalPortions, int newPortions) {
    return Ingredient(
      id: id,
      name: name,
      quantity: calculateAdjustedQuantity(originalPortions, newPortions),
      unit: unit,
      price: price,
      recipeId: recipeId,
    );
  }

  // Método para convertir unidades entre sistemas métrico e imperial
  double convertUnit(String toSystem) {
    if (unit == 'g' && toSystem == 'imperial') {
      return quantity / 28.35; // Convertir a onzas
    } else if (unit == 'oz' && toSystem == 'metric') {
      return quantity * 28.35; // Convertir a gramos
    } else if (unit == 'kg' && toSystem == 'imperial') {
      return quantity * 2.20462; // Convertir a libras
    } else if (unit == 'lb' && toSystem == 'metric') {
      return quantity / 2.20462; // Convertir a kilogramos
    } else if (unit == 'ml' && toSystem == 'imperial') {
      return quantity / 29.5735; // Convertir a onzas fluidas
    } else if (unit == 'fl oz' && toSystem == 'metric') {
      return quantity * 29.5735; // Convertir a mililitros
    } else if (unit == 'l' && toSystem == 'imperial') {
      return quantity * 0.264172; // Convertir a galones
    } else if (unit == 'gal' && toSystem == 'metric') {
      return quantity / 0.264172; // Convertir a litros
    } else {
      return quantity; // Sin conversión
    }
  }

  // Obtener la unidad de medida correspondiente en el sistema especificado
  String getUnitInSystem(String toSystem) {
    if (unit == 'g' && toSystem == 'imperial') {
      return 'oz';
    } else if (unit == 'oz' && toSystem == 'metric') {
      return 'g';
    } else if (unit == 'kg' && toSystem == 'imperial') {
      return 'lb';
    } else if (unit == 'lb' && toSystem == 'metric') {
      return 'kg';
    } else if (unit == 'ml' && toSystem == 'imperial') {
      return 'fl oz';
    } else if (unit == 'fl oz' && toSystem == 'metric') {
      return 'ml';
    } else if (unit == 'l' && toSystem == 'imperial') {
      return 'gal';
    } else if (unit == 'gal' && toSystem == 'metric') {
      return 'l';
    } else {
      return unit; // Sin cambio
    }
  }
}