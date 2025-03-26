import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/calculator_ingredient.dart';
import '../../services/hive-service.dart';
import 'package:uuid/uuid.dart';
import '../../models/settings.dart';

class CalculatorView extends StatefulWidget {
  const CalculatorView({Key? key}) : super(key: key);

  @override
  State<CalculatorView> createState() => _CalculatorViewState();
}

class _CalculatorViewState extends State<CalculatorView> {
  final HiveService _hiveService = HiveService();
  int _teamMembers = 1;
  double _totalCost = 0.0;
  bool _isLoading = true;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar el número de miembros del equipo
      _teamMembers = await _hiveService.getTeamMembers();
      
      // Calcular el costo total de los ingredientes
      final ingredients = await _hiveService.getAllCalculatorIngredients();
      _totalCost = ingredients.fold(0, (sum, item) => sum + item.price);
    } catch (e) {
      // Manejar error
      debugPrint('Error al cargar datos: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Actualizar el número de miembros del equipo
  void _updateTeamMembers(int value) async {
    if (value >= 1) {
      setState(() {
        _teamMembers = value;
      });
      
      await _hiveService.saveTeamMembers(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tarjeta de resumen de costos
        Card(
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      '\$${_totalCost.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Per capita:',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '\$${(_teamMembers > 0 ? _totalCost / _teamMembers : 0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'MIEMBROS DEL EQUIPO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Material(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: _teamMembers > 1
                                ? () => _updateTeamMembers(_teamMembers - 1)
                                : null,
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.remove),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '$_teamMembers',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Material(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _updateTeamMembers(_teamMembers + 1),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.add),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Título de la lista
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lista de ingredientes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Limpiar'),
                onPressed: () {
                  _showClearConfirmation(context);
                },
              ),
            ],
          ),
        ),
        
        // Lista de ingredientes
        Expanded(
          child: ValueListenableBuilder<Box<CalculatorIngredient>>(
            valueListenable: Hive.box<CalculatorIngredient>('calculator_ingredients').listenable(),
            builder: (context, box, _) {
              final ingredients = box.values.toList();
              
              if (ingredients.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shopping_cart,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay ingredientes agregados',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          _showIngredientForm(context);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar ingrediente'),
                      ),
                    ],
                  ),
                );
              }
              
              // Actualizar el costo total cada vez que cambia la lista
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final newTotal = ingredients.fold(0.0, (sum, item) => sum + item.price);
                if (newTotal != _totalCost) {
                  setState(() {
                    _totalCost = newTotal;
                  });
                }
              });
              
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: ingredients.length,
                itemBuilder: (context, index) {
                  final ingredient = ingredients[index];
                  return Dismissible(
                    key: Key(ingredient.id),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) async {
                      await _hiveService.deleteCalculatorIngredient(ingredient.id);
                      
                      // Actualizar el costo total
                      setState(() {
                        _totalCost -= ingredient.price;
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${ingredient.name} eliminado'),
                          action: SnackBarAction(
                            label: 'Deshacer',
                            onPressed: () async {
                              // Volver a agregar el ingrediente
                              await _hiveService.addCalculatorIngredient(ingredient);
                              
                              // Actualizar el costo total
                              setState(() {
                                _totalCost += ingredient.price;
                              });
                            },
                          ),
                        ),
                      );
                    },
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirmar'),
                            content: Text('¿Eliminar "${ingredient.name}" de la lista?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          );
                        },
                      ) ?? false;
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          child: Icon(
                            Icons.restaurant,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        title: Text(
                          ingredient.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${ingredient.quantity} ${ingredient.unit}',
                        ),
                        trailing: Text(
                          '\$${ingredient.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        onTap: () {
                          _showIngredientForm(context, ingredient);
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
      
      // Floating action button for adding ingredients
      
    );
  }

  void _showIngredientForm(BuildContext context, [CalculatorIngredient? existingIngredient]) {
    final isEditing = existingIngredient != null;
    
    final _nameController = TextEditingController(text: existingIngredient?.name ?? '');
    final _quantityController = TextEditingController(text: existingIngredient?.quantity.toString() ?? '');
    final _priceController = TextEditingController(text: existingIngredient?.price.toString() ?? '');
    String _selectedUnit = existingIngredient?.unit ?? 'g';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<Settings>(
          future: _hiveService.getSettings(),
          builder: (context, snapshot) {
            final units = snapshot.data?.getCurrentUnits() ?? ['g', 'kg', 'ml', 'l', 'cdta', 'cda', 'taza', 'pizca', 'unidad'];

            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Text(isEditing ? 'Editar Ingrediente' : 'Nuevo Ingrediente'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del ingrediente',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _quantityController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Cantidad',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              flex: 1,
                              child: DropdownButtonFormField<String>(
                                value: _selectedUnit,
                                decoration: const InputDecoration(
                                  labelText: 'Unidad',
                                  border: OutlineInputBorder(),
                                ),
                                items: units.map((unit) {
                                  return DropdownMenuItem<String>(
                                    value: unit,
                                    child: Text(unit),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedUnit = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Precio por unidad',
                            prefixText: '\$',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (_nameController.text.isNotEmpty &&
                            _quantityController.text.isNotEmpty &&
                            _priceController.text.isNotEmpty) {
                          final name = _nameController.text;
                          final quantity = double.tryParse(_quantityController.text) ?? 0;
                          final price = double.tryParse(_priceController.text) ?? 0;

                          if (isEditing) {
                            // Actualizar ingrediente existente
                            final oldPrice = existingIngredient.price;
                            
                            final updatedIngredient = CalculatorIngredient(
                              id: existingIngredient.id,
                              name: name,
                              quantity: quantity,
                              unit: _selectedUnit,
                              price: price,
                            );
                            
                            await _hiveService.updateCalculatorIngredient(updatedIngredient);
                            
                            // Actualizar el costo total
                            setState(() {
                              _totalCost = _totalCost - oldPrice + price;
                            });
                          } else {
                            // Crear nuevo ingrediente
                            final newIngredient = CalculatorIngredient(
                              id: _uuid.v4(),
                              name: name,
                              quantity: quantity,
                              unit: _selectedUnit,
                              price: price,
                            );
                            
                            await _hiveService.addCalculatorIngredient(newIngredient);
                            
                            // Actualizar el costo total
                            setState(() {
                              _totalCost += price;
                            });
                          }
                          
                          Navigator.of(context).pop();
                        } else {
                          // Mostrar mensaje de error
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Por favor complete todos los campos'),
                            ),
                          );
                        }
                      },
                      child: const Text('Aceptar'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
  
  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Limpiar lista'),
          content: const Text('¿Estás seguro de que deseas eliminar todos los ingredientes de la calculadora?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                await _hiveService.clearAllCalculatorIngredients();
                setState(() {
                  _totalCost = 0;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Limpiar'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }
}