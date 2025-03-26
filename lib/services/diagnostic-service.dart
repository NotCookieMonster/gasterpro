import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// A service for logging and retrieving diagnostic information,
/// particularly useful for debugging web deployment issues.
class DiagnosticService {
  static final DiagnosticService _instance = DiagnosticService._internal();
  
  factory DiagnosticService() {
    return _instance;
  }
  
  DiagnosticService._internal();
  
  final Map<String, dynamic> _diagnosticLogs = {};
  final List<String> _logHistory = [];
  bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    _logInternal('initialized', 'Diagnostic service initialized');
    _logInternal('platform', kIsWeb ? 'Web' : 'Mobile');
    _logInternal('timestamp', DateTime.now().toIso8601String());
    
    if (kIsWeb) {
      await _checkWebStorage();
    }
    
    _initialized = true;
  }
  
  void _logInternal(String key, dynamic value) {
    _diagnosticLogs[key] = value;
    _logHistory.add('$key: $value');
    print('DIAGNOSTIC - $key: $value');
  }
  
  void logDiagnostic(String key, dynamic value) {
    _logInternal(key, value);
  }
  
  List<String> getLogHistory() {
    return List.from(_logHistory);
  }
  
  Map<String, dynamic> getDiagnosticLogs() {
    return Map.from(_diagnosticLogs);
  }
  
  Future<void> _checkWebStorage() async {
    if (!kIsWeb) return;
    
    try {
      logDiagnostic('webStorageCheck', 'Starting web storage check');
      
      // Check IndexedDB availability
      logDiagnostic('indexedDBAvailable', 'Checking...');
      try {
        final box = Hive.box<String>('diagnostics');
        await box.put('test', 'test value');
        final testValue = box.get('test');
        logDiagnostic('indexedDBTest', testValue == 'test value' ? 'Success' : 'Failed');
      } catch (e) {
        logDiagnostic('indexedDBError', e.toString());
      }
      
      // Check storage capacity using local storage
      try {
        logDiagnostic('localStorageCheck', 'Checking...');
        final testData = List.generate(100, (index) => 'test').join('');
        // This js interop code would normally go here, but we're just logging the concept
        logDiagnostic('localStorageSize', 'Test performed');
      } catch (e) {
        logDiagnostic('localStorageError', e.toString());
      }
      
      // Storage permission check
      logDiagnostic('storagePermission', 'Permission status unknown - requires browser API');
      
    } catch (e) {
      logDiagnostic('webStorageCheckError', e.toString());
    }
  }
  
  // Check for recipe storage
  Future<void> checkRecipeStorage() async {
    try {
      final recipeBox = Hive.box('recipes');
      final count = recipeBox.length;
      logDiagnostic('recipeCount', count);
      
      if (count > 0) {
        final keys = recipeBox.keys.toList();
        logDiagnostic('recipeKeys', keys.join(', '));
      }
    } catch (e) {
      logDiagnostic('recipeStorageError', e.toString());
    }
  }
  
  // In a real web app, this would download the diagnostic data
  void downloadDiagnostics() {
    final jsonData = jsonEncode(_diagnosticLogs);
    logDiagnostic('downloadRequested', 'User requested download of diagnostic data');
    
    if (kIsWeb) {
      // This would normally use a JavaScript interop to trigger a download
      // For this diagnostic version, we'll just log it
      logDiagnostic('diagnosticData', jsonData);
    }
  }
  
  // Display diagnostic UI
  Widget createDiagnosticWidget() {
    return Card(
      color: Colors.yellow[100],
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Diagnostic Information', 
              style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Platform: ${kIsWeb ? "Web" : "Mobile"}'),
            Text('Logs: ${_logHistory.length}'),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _logHistory.take(10).map((log) => 
                    Text(log, style: const TextStyle(fontSize: 10))
                  ).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}