import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ping_go/src/routes/app_router.dart';
import 'package:ping_go/src/providers/database_provider.dart';
import 'package:ping_go/src/features/map/providers/map_provider.dart';
import 'package:ping_go/src/features/conductor/providers/conductor_provider.dart';
import 'package:ping_go/src/features/conductor/providers/conductor_profile_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DatabaseProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(create: (_) => ConductorProvider()),
        ChangeNotifierProvider(create: (_) => ConductorProfileProvider()),
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
