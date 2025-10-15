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

    // Inicializar la base de datos en background cuando se carga la app
    if (enableDatabaseInit) {
      // No bloqueamos la UI: inicializamos en background y dejamos que el RouterScreen se muestre.
      Future.microtask(() => databaseProvider.initializeDatabase());
    }

    return MaterialApp(
      title: 'Ping-Go',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        visualDensity: VisualDensity.standard,
        scaffoldBackgroundColor: Colors.black, // Fondo negro para toda la app
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
      ),
  onGenerateRoute: AppRouter.generateRoute,
  navigatorObservers: [RouteLogger()],
      initialRoute: '/',
      // Mostrar la navegación inmediatamente; la conexión a la DB sucede en segundo plano.
      home: const RouterScreen(),
    );
  }

  // Note: Database connection UI is now shown as a small banner overlay in RouterScreen.
}

// Widget para manejar la navegación normal cuando la conexión está establecida
class RouterScreen extends StatelessWidget {
  const RouterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mostrar navegación normalmente. Si la DB aún no está lista, mostrar un pequeño banner.
    final dbProv = Provider.of<DatabaseProvider>(context);
    return Stack(
      children: [
        Navigator(
          onGenerateRoute: AppRouter.generateRoute,
          initialRoute: '/',
        ),
        if (!dbProv.isConnected)
          Positioned(
            left: 12,
            right: 12,
            top: 40,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: dbProv.errorMessage.isNotEmpty ? Colors.redAccent : Colors.orangeAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(dbProv.errorMessage.isNotEmpty ? Icons.error : Icons.info_outline, color: Colors.black),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        dbProv.errorMessage.isNotEmpty
                            ? 'Error de conexión a DB'
                            : 'Conectando a base de datos en segundo plano',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                    if (dbProv.errorMessage.isNotEmpty)
                      TextButton(
                        onPressed: () => dbProv.initializeDatabase(),
                        child: const Text('Reintentar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Simple NavigatorObserver para loggear cambios de ruta en debug
class RouteLogger extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    try {
      print('Route pushed: ${route.settings.name} <- from ${previousRoute?.settings.name}');
    } catch (_) {}
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    try {
      print('Route popped: ${route.settings.name} -> back to ${previousRoute?.settings.name}');
    } catch (_) {}
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    try {
      print('Route replaced: ${oldRoute?.settings.name} -> ${newRoute?.settings.name}');
    } catch (_) {}
  }
}
