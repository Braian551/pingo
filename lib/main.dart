import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:viax/src/routes/app_router.dart';
import 'package:viax/src/providers/database_provider.dart';
import 'package:viax/src/features/conductor/providers/conductor_provider.dart';
import 'package:viax/src/features/conductor/providers/conductor_profile_provider.dart';
import 'package:viax/src/features/conductor/providers/conductor_trips_provider.dart';
import 'package:viax/src/features/conductor/providers/conductor_earnings_provider.dart';
import 'package:viax/src/core/di/service_locator.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);

  // Inicializar Service Locator (InyecciÃ³n de Dependencias)
  // Esto configura todos los datasources, repositories y use cases
  final serviceLocator = ServiceLocator();
  await serviceLocator.init();

  runApp(
    MultiProvider(
      providers: [
        // Database Provider (legacy)
        ChangeNotifierProvider(create: (_) => DatabaseProvider()),
        
        
        // User Microservice Provider
        ChangeNotifierProvider(
          create: (_) => serviceLocator.createUserProvider(),
        ),
        
        // Conductor Microservice Provider
        ChangeNotifierProvider(
          create: (_) => serviceLocator.createConductorProfileProvider(),
        ),

        // Trip Microservice Provider
        ChangeNotifierProvider(
          create: (_) => serviceLocator.createTripProvider(),
        ),

        // Map Microservice Provider
        ChangeNotifierProvider(
          create: (_) => serviceLocator.createMapProvider(),
        ),

        // Admin Microservice Provider
        ChangeNotifierProvider(
          create: (_) => serviceLocator.createAdminProvider(),
        ),

        // ========== LEGACY PROVIDERS (por deprecar gradualmente) ==========
        
        // Conductor Providers (legacy - funcionalidad migrada a Conductor Microservice)
        ChangeNotifierProvider(create: (_) => ConductorProvider()),
        ChangeNotifierProvider(create: (_) => ConductorProfileProvider()),
        ChangeNotifierProvider(create: (_) => ConductorTripsProvider()),
        ChangeNotifierProvider(create: (_) => ConductorEarningsProvider()),
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
  title: 'Viax',
      debugShowCheckedModeBanner: false,
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
