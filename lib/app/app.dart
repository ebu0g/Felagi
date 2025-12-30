import 'package:flutter/material.dart';
import 'routes.dart';

class FelagiApp extends StatelessWidget {
  const FelagiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // ✅ STATIC ROUTES
      routes: appRoutes,

      // ✅ DYNAMIC ROUTES (arguments)
      onGenerateRoute: onGenerateRoute,

      // ✅ START SCREEN
      initialRoute: Routes.home,
    );
  }
}
