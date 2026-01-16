import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'routes.dart';
// import '../features/auth/screens/login_screen.dart';
// import '../features/patient/screens/patient_navigation.dart';

class FelagiApp extends StatelessWidget {
  const FelagiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: appRoutes,
      onGenerateRoute: onGenerateRoute,
      // Always start at the home screen (login/register) so users see
      // the entry UI instead of being automatically routed into a role.
      initialRoute: Routes.home,
    );
  }
}
