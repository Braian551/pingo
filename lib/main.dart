import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ping_go/src/routes/app_router.dart';
import 'package:ping_go/src/providers/database_provider.dart';
import 'package:ping_go/src/features/map/providers/map_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DatabaseProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()), // Proveer MapProvider
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool enableDatabaseInit;

  const MyApp({super.key, this.enableDatabaseInit = true});

  @override
  Widget build(BuildContext context) {
    final databaseProvider = Provider.of<DatabaseProvider>(
      context,
      listen: false,
    );

    // Inicializar la base de datos cuando se carga la app si está habilitado
    if (enableDatabaseInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        databaseProvider.initializeDatabase();
      });
    }

    return MaterialApp(
      title: 'Ping-Go',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.standard,
        scaffoldBackgroundColor: Colors.black, // Fondo negro para toda la app
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: '/',
      home: Consumer<DatabaseProvider>(
        builder: (context, databaseProvider, child) {
          if (databaseProvider.isConnected) {
            return const RouterScreen();
          } else if (databaseProvider.errorMessage.isNotEmpty) {
            return _buildErrorScreen(
              databaseProvider.errorMessage,
              databaseProvider,
            );
          } else {
            return _buildLoadingScreen();
          }
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF39FF14)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Conectando con la base de datos...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(
    String errorMessage,
    DatabaseProvider databaseProvider,
  ) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 20),
              Text(
                'Error de conexión',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  databaseProvider.initializeDatabase();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF39FF14),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
                child: const Text(
                  'Reintentar conexión',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Asegúrate de que MySQL esté ejecutándose\nen localhost:3306',
                style: TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget para manejar la navegación normal cuando la conexión está establecida
class RouterScreen extends StatelessWidget {
  const RouterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: '/',
    );
  }
}
