import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/settings.dart';
import '../../services/hive-service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final HiveService _hiveService = HiveService();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Settings>>(
      valueListenable: Hive.box<Settings>('settings').listenable(),
      builder: (context, box, _) {
        final settings = box.get('settings') ?? 
            Settings(isDarkMode: false, measurementSystem: 'metric');
        
        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Configuración de tema
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Modo Oscuro',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Switch(
                        value: settings.isDarkMode,
                        onChanged: (value) async {
                          final newSettings = settings.copyWithDarkMode(value);
                          await _hiveService.updateSettings(newSettings);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Configuración del sistema de medición
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sistema de Medición',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RadioListTile<String>(
                        title: const Text('Sistema Métrico (g, kg, ml, l)'),
                        value: 'metric',
                        groupValue: settings.measurementSystem,
                        onChanged: (value) async {
                          if (value != null) {
                            final newSettings = settings.copyWithMeasurementSystem(value);
                            await _hiveService.updateSettings(newSettings);
                          }
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Sistema Imperial (oz, lb, fl oz, gal)'),
                        value: 'imperial',
                        groupValue: settings.measurementSystem,
                        onChanged: (value) async {
                          if (value != null) {
                            final newSettings = settings.copyWithMeasurementSystem(value);
                            await _hiveService.updateSettings(newSettings);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Acerca de la aplicación
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Acerca de',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const ListTile(
                        title: Text('Versión'),
                        trailing: Text('1.0.0'),
                      ),
                      ListTile(
                        title: const Text('Desarrollado por'),
                        trailing: Text(
                          '@notmnstr',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Explicación sobre conversión de unidades
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Conversión de Unidades',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Al cambiar el sistema de medición, todas las recetas mostrarán las cantidades de ingredientes en el sistema seleccionado. '
                        'Las conversiones se realizan automáticamente según los siguientes factores:',
                      ),
                      SizedBox(height: 8),
                      Text('• 1 g = 0.035 oz'),
                      Text('• 1 kg = 2.2 lb'),
                      Text('• 1 ml = 0.034 fl oz'),
                      Text('• 1 l = 0.26 gal'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}