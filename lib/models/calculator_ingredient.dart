import 'package:hive/hive.dart';

part 'calculator_ingredient.g.dart';

@HiveType(typeId: 3)
class CalculatorIngredient extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double quantity;

  @HiveField(3)
  String unit;

  @HiveField(4)
  double price;

  CalculatorIngredient({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.price,
  });
}