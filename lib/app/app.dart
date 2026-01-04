import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'routes.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/patient/screens/patient_navigation.dart';

class FelagiApp extends StatelessWidget {
  const FelagiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: appRoutes,
      onGenerateRoute: onGenerateRoute,
      initialRoute: FirebaseAuth.instance.currentUser == null
          ? Routes.home
          : Routes.patientNav,
    );
  }
}
