import 'package:hive/hive.dart';

part 'recipe.g.dart';

@HiveType(typeId: 0)
class Recipe extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  int portions;

  @HiveField(4)
  List<String> ingredientIds;

  @HiveField(5)
  String procedure;

  @HiveField(6)
  String? imagePath;

  Recipe({
    required this.id,
    required this.name,
    this.description = '',
    required this.portions,
    required this.ingredientIds,
    required this.procedure,
    this.imagePath,
  });

  // Método para crear una copia de la receta con porciones ajustadas
  Recipe copyWithAdjustedPortions(int newPortions) {
    return Recipe(
      id: id,
      name: name,
      description: description,
      portions: newPortions,
      ingredientIds: ingredientIds,
      procedure: procedure,
      imagePath: imagePath,
    );
  }
}