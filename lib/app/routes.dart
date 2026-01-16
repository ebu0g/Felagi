import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/screens/home_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
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
import '../features/pharmacy/screens/pharmacy_navigation.dart';
import '../features/patient/screens/order_history.dart';
import '../features/pharmacy/models/pharmacy.dart'; // <-- Add this
import '../features/patient/screens/edit_patient_profile.dart';
import '../features/admin/screens/admin_navigation.dart';
import '../features/admin/screens/admin_dashboard.dart';
import '../features/admin/screens/approve_pharmacy.dart';
//import '../features/admin/screens/manage_admins.dart';
import '../features/admin/screens/settings_screen.dart';
import '../features/admin/screens/manage_pharmacies.dart';
import '../features/admin/controllers/admin_controller.dart';
import '../features/admin/screens/edit_admin_profile_screen.dart';

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
  static const pharmacyNav = '/pharmacy-nav';
  static const searchHistory = '/search-history';
  static const editPatientProfile = '/editPatientProfile';
  static const editAdminProfile = '/edit-admin-profile';
  static const forgotPassword = '/forgot-password';
  static const adminNav = '/admin-nav';
  static const adminDashboard = '/admin-dashboard';
  static const approvePharmacy = '/approve-pharmacy';
  static const manageAdmins = '/manage-admins';
  static const managePharmacies = '/manage-pharmacies';
  static const settings = '/settings';
}

// Static routes
final Map<String, WidgetBuilder> appRoutes = {
  Routes.home: (context) => const HomeScreen(),
  Routes.login: (context) => const LoginScreen(),
  Routes.register: (context) => const RegisterScreen(),
  Routes.forgotPassword: (context) => const ForgotPasswordScreen(),
  Routes.patientHome: (context) => const PatientHome(),
  Routes.searchMedicine: (context) => const SearchMedicine(),
  Routes.searchResults: (context) => const SearchResults(),
  Routes.pharmacyDetails: (context) => const PharmacyDetails(),
  Routes.patientProfile: (context) => const PatientProfile(),
  Routes.patientNav: (context) => const PatientNavigation(),
  Routes.pharmacyNav: (context) => PharmacyNavigation(),
  Routes.searchHistory: (context) => const SearchHistoryScreen(),
  Routes.pharmacyDashboard: (context) => const PharmacyDashboard(),
  Routes.addMedicine: (context) => const AddMedicineScreen(),
  Routes.editPatientProfile: (context) => const EditPatientProfile(),
  Routes.adminNav: (context) => const AdminNavigation(),
  Routes.adminDashboard: (context) => const AdminDashboard(),
  Routes.approvePharmacy: (context) => const ApprovePharmacyScreen(),
  // Routes.manageAdmins: (context) => const ManageAdminsScreen(),
  Routes.managePharmacies: (context) => ChangeNotifierProvider(
        create: (_) => AdminController(),
        child: const ManagePharmaciesScreen(),
      ),
  Routes.settings: (context) => const SettingsScreen(),
  //Routes.manageStock: (context) => const ManageStockScreen(),
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
      String email = '';
      String address = '';
      String phone = '';

      if (args != null && args is Map<String, dynamic>) {
        name = args['name'] ?? '';
        email = args['email'] ?? '';
        address = args['address'] ?? '';
        phone = args['phone'] ?? '';
      }

      return MaterialPageRoute(
        builder: (_) => EditPharmacyProfileScreen(
          name: name,
          email: email,
          address: address,
          phone: phone,
        ),
      );

    // ================= EDIT ADMIN =================
    case Routes.editAdminProfile:
      final args = settings.arguments;
      String name = '';
      String email = '';
      String address = '';
      String phone = '';

      if (args != null && args is Map<String, dynamic>) {
        name = args['name'] ?? '';
        email = args['email'] ?? '';
        address = args['address'] ?? '';
        phone = args['phone'] ?? '';
      }

      return MaterialPageRoute(
        builder: (_) => EditAdminProfileScreen(
          name: name,
          email: email,
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
      String category = 'Other';

      if (args != null && args is Map<String, dynamic>) {
        name = args['name'] ?? '';
        price = double.tryParse(args['price'].toString()) ?? 0.0;
        quantity = int.tryParse(args['quantity'].toString()) ?? 0;
        category = (args['category'] ?? 'Other').toString();
      }

      return MaterialPageRoute(
        builder: (_) => EditMedicineScreen(
          name: name,
          price: price,
          quantity: quantity,
          category: category,
        ),
      );

    // ================= MANAGE STOCK =================
    case Routes.manageStock:
      final args = settings.arguments;
      if (args is Pharmacy) {
        return MaterialPageRoute(
          builder: (_) => ManageStockScreen(pharmacy: args),
        );
      }
      if (args is Map<String, dynamic>) {
        final pharmacyArg = args['pharmacy'];
        final initialId = args['medicineId'] as String?;
        if (pharmacyArg is Pharmacy) {
          return MaterialPageRoute(
            builder: (_) => ManageStockScreen(
              pharmacy: pharmacyArg,
              initialMedicineId: initialId,
            ),
          );
        }
      }
      return MaterialPageRoute(
        builder: (_) =>
            const Scaffold(body: Center(child: Text('No pharmacy selected'))),
      );

    // ================= FORGOT PASSWORD =================
    case Routes.forgotPassword:
      return MaterialPageRoute(
        builder: (_) => const ForgotPasswordScreen(),
      );

    // ================= FALLBACK =================
    default:
      return MaterialPageRoute(
        builder: (_) =>
            const Scaffold(body: Center(child: Text('Route not found'))),
      );
  }
}
