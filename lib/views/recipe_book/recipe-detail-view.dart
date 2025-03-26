import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../models/ingredient.dart';
import '../../services/hive-service.dart';
import 'edit-recipe-view.dart';

class RecipeDetailView extends StatefulWidget {
  final String recipeId;

  const RecipeDetailView({
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Recipe?>(
      future: _hiveService.getRecipe(widget.recipeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Error'),
            ),
            body: Center(
              child: Text('Error: ${snapshot.error ?? 'Receta no encontrada'}'),
            ),
          );
        }

        final recipe = snapshot.data!;
        
        // Actualizar porciones originales
        if (_originalPortions == 1 && recipe.portions > 0) {
          _originalPortions = recipe.portions;
          _currentPortions = recipe.portions;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(recipe.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditRecipeView(recipeId: recipe.id),
                    ),
                  ).then((_) {
                    setState(() {});
                  });
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen de la receta
                if (recipe.imagePath != null)
                  Image.network(
                    recipe.imagePath!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
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

                // Ajuste de porciones
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Ajustar porciones:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: _currentPortions > 1
                                    ? () {
                                        setState(() {
                                          _currentPortions--;
                                        });
                                      }
                                    : null,
                              ),
                              Text(
                                '$_currentPortions',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  setState(() {
                                    _currentPortions++;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Ingredientes
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ingredientes:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          FutureBuilder<List<Ingredient>>(
                            future: _hiveService.getIngredientsForRecipe(recipe.id),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              }

                              final ingredients = snapshot.data ?? [];

                              if (ingredients.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('No hay ingredientes disponibles'),
                                );
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: ingredients.length,
                                itemBuilder: (context, index) {
                                  final ingredient = ingredients[index];
                                  final adjustedQuantity = ingredient.calculateAdjustedQuantity(
                                    _originalPortions,
                                    _currentPortions,
                                  );

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.arrow_right),
                                        Expanded(
                                          child: Text(
                                            '${adjustedQuantity.toStringAsFixed(1)} ${ingredient.unit} de ${ingredient.name}',
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Procedimiento
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Procedimiento:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            recipe.procedure,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}