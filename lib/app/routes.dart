import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/screens/home_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/patient/screens/patient_home.dart';
import '../features/pharmacy/screens/pharmacy_dashboard.dart';
import '../features/pharmacy/screens/add_medicine.dart';
import '../features/pharmacy/screens/manage_stock.dart';
import '../features/pharmacy/screens/edit_pharmacy_profile_screen.dart';
import '../features/pharmacy/screens/edit_medicine_screen.dart';
import '../features/pharmacy/screens/pharmacy_profile_screen.dart';
import '../features/patient/screens/search_medicine.dart';
import '../features/patient/screens/search_results.dart';
import '../features/patient/screens/pharmacy_details.dart';
import '../features/patient/screens/patient_profile.dart';
import '../features/patient/screens/patient_navigation.dart';
import '../features/patient/screens/order_history.dart';
import '../features/patient/screens/order_details.dart';
import '../features/admin/screens/admin_dashboard.dart';
import '../features/admin/screens/approve_pharmacy.dart';
import '../features/admin/screens/manage_admins.dart';
import '../features/admin/screens/settings_screen.dart';
import '../features/admin/controllers/admin_controller.dart';
import '../features/pharmacy/models/pharmacy.dart'; // <-- Add this
import '../features/patient/screens/edit_patient_profile.dart';

class Routes {
  static const home = '/';
  static const login = '/login';
  static const register = '/register';
  static const patientHome = '/patient-home';
  static const pharmacyDashboard = '/pharmacy-dashboard';
  static const pharmacyProfile = '/pharmacy-profile';
  static const editPharmacyProfile = '/edit-pharmacy-profile';
  static const editMedicine = '/edit-medicine';
  static const addMedicine = '/add-medicine';
  static const manageStock = '/manage-stock';
  static const searchMedicine = '/search-medicine';
  static const searchResults = '/search-results';
  static const pharmacyDetails = '/pharmacy-details';
  static const patientProfile = '/patient-profile';
  static const patientNav = '/patient-nav';
  static const orderHistory = '/order-history';
  static const orderDetails = '/order-details';
  static const adminDashboard = '/admin-dashboard';
  static const approvePharmacy = '/approve-pharmacy';
  static const manageAdmins = '/manage-admins';
  static const settings = '/settings';
  static const editPatientProfile = '/editPatientProfile';
}

// Static routes
final Map<String, WidgetBuilder> appRoutes = {
  Routes.home: (context) => const HomeScreen(),
  Routes.login: (context) => const LoginScreen(),
  Routes.register: (context) => const RegisterScreen(),
  Routes.patientHome: (context) => const PatientHome(),
  Routes.searchMedicine: (context) => const SearchMedicine(),
  Routes.searchResults: (context) => const SearchResults(),
  Routes.pharmacyDetails: (context) => const PharmacyDetails(),
  Routes.patientProfile: (context) => const PatientProfile(),
  Routes.patientNav: (context) => const PatientNavigation(),
  Routes.orderHistory: (context) => const OrderHistoryScreen(),
  Routes.orderDetails: (context) => const OrderDetailsScreen(),
  Routes.pharmacyDashboard: (context) => const PharmacyDashboard(),
  Routes.addMedicine: (context) => const AddMedicineScreen(),
  Routes.editPatientProfile: (context) => const EditPatientProfile(),
  //Routes.manageStock: (context) => const ManageStockScreen(),

  // Admin Screens with Providers
  Routes.adminDashboard: (context) => const AdminDashboard(),

  Routes.approvePharmacy: (context) => ChangeNotifierProvider(
    create: (_) => AdminController(),
    builder: (context, child) => const ApprovePharmacyScreen(),
  ),

  Routes.manageAdmins: (context) => ChangeNotifierProvider(
    create: (_) => AdminController(),
    builder: (context, child) => const ManageAdminsScreen(),
  ),

  Routes.settings: (context) => ChangeNotifierProvider(
    create: (_) => AdminController(),
    builder: (context, child) => const SettingsScreen(), // remove const here
  ),
};

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    // ================= PHARMACY PROFILE =================
    case Routes.pharmacyProfile:
      // No arguments needed anymore
      return MaterialPageRoute(
        builder: (_) => const PharmacyProfileScreen(),
      );

    // ================= EDIT PHARMACY =================
    case Routes.editPharmacyProfile:
      final args = settings.arguments;
      String name = '';
      String address = '';
      String phone = '';

      if (args != null && args is Map<String, dynamic>) {
        name = args['name'] ?? '';
        address = args['address'] ?? '';
        phone = args['phone'] ?? '';
      }

      return MaterialPageRoute(
        builder: (_) => EditPharmacyProfileScreen(
          name: name,
          address: address,
          phone: phone,
        ),
      );

    // ================= EDIT MEDICINE =================
    case Routes.editMedicine:
      final args = settings.arguments;
      String name = '';
      double price = 0.0;
      int quantity = 0;

      if (args != null && args is Map<String, dynamic>) {
        name = args['name'] ?? '';
        price = double.tryParse(args['price'].toString()) ?? 0.0;
        quantity = int.tryParse(args['quantity'].toString()) ?? 0;
      }

      return MaterialPageRoute(
        builder: (_) =>
            EditMedicineScreen(name: name, price: price, quantity: quantity),
      );

    // ================= ADMIN =================
    case Routes.adminDashboard:
      return MaterialPageRoute(builder: (_) => const AdminDashboard());

    case Routes.approvePharmacy:
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => AdminController(),
          child: const ApprovePharmacyScreen(),
        ),
      );

    case Routes.manageAdmins:
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => AdminController(),
          child: const ManageAdminsScreen(),
        ),
      );

    case Routes.settings:
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => AdminController(),
          child: const SettingsScreen(),
        ),
      );

    // ================= MANAGE STOCK =================
    case Routes.manageStock:
      final args = settings.arguments;

      if (args != null && args is Pharmacy) {
        return MaterialPageRoute(
          builder: (_) => ManageStockScreen(pharmacy: args),
        );
      }

      return MaterialPageRoute(
        builder: (_) =>
            const Scaffold(body: Center(child: Text('No pharmacy selected'))),
      );

    // ================= FALLBACK =================
    default:
      return MaterialPageRoute(
        builder: (_) =>
            const Scaffold(body: Center(child: Text('Route not found'))),
      );
  }
}
