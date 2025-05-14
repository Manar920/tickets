import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/ticket_provider.dart';
import 'screens/login_screen.dart';
import 'screens/client/client_home_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'services/role_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return authProvider.isAuthenticated
              ? ChangeNotifierProvider<TicketProvider>(
                  // Create a new TicketProvider when user is authenticated
                  create: (_) => TicketProvider(authProvider.user?.uid),
                  child: MaterialApp(
                    title: 'DEVMOB SUPPORTCLIENT',
                    debugShowCheckedModeBanner: false,
                    theme: ThemeData(
                      primarySwatch: Colors.blue,
                      primaryColor: const Color(0xFF3F51B5),
                      scaffoldBackgroundColor: Colors.grey.shade50,
                      colorScheme: ColorScheme.fromSwatch(
                        primarySwatch: Colors.blue,
                        accentColor: const Color(0xFFFF5722),
                        brightness: Brightness.light,
                      ),
                      fontFamily: 'Poppins', // Change to a cleaner font
                      appBarTheme: const AppBarTheme(
                        backgroundColor: Color(0xFF3F51B5),
                        elevation: 0,
                        centerTitle: false,
                        titleTextStyle: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                        iconTheme: IconThemeData(color: Colors.white),
                      ),
                      elevatedButtonTheme: ElevatedButtonThemeData(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF3F51B5),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 1,
                        ),
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF3F51B5),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        ),
                      ),
                      cardTheme: CardTheme(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        color: Colors.white,
                        shadowColor: Colors.black.withOpacity(0.1),
                      ),
                    ),
                    home: _buildHomeScreen(authProvider),
                    routes: {
                      '/login': (context) => const LoginScreen(),
                      '/client_home': (context) => const ClientHomeScreen(),
                      '/admin_home': (context) => const AdminHomeScreen(),
                    },
                  ),
                )
              : MaterialApp(
                  title: 'DEVMOB SUPPORTCLIENT',
                  debugShowCheckedModeBanner: false,
                  theme: ThemeData(
                    primarySwatch: Colors.blue,
                    primaryColor: const Color(0xFF3F51B5),
                    scaffoldBackgroundColor: Colors.grey.shade50,
                    colorScheme: ColorScheme.fromSwatch(
                      primarySwatch: Colors.blue,
                      accentColor: const Color(0xFFFF5722),
                      brightness: Brightness.light,
                    ),
                    fontFamily: 'Poppins', // Change to a cleaner font
                    appBarTheme: const AppBarTheme(
                      backgroundColor: Color(0xFF3F51B5),
                      elevation: 0,
                      centerTitle: false,
                      titleTextStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      iconTheme: IconThemeData(color: Colors.white),
                    ),
                    elevatedButtonTheme: ElevatedButtonThemeData(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF3F51B5),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 1,
                      ),
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF3F51B5),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      ),
                    ),
                    cardTheme: CardTheme(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      color: Colors.white,
                      shadowColor: Colors.black.withOpacity(0.1),
                    ),
                  ),
                  home: const LoginScreen(),
                  routes: {
                    '/login': (context) => const LoginScreen(),
                    '/client_home': (context) => const ClientHomeScreen(),
                    '/admin_home': (context) => const AdminHomeScreen(),
                  },
                );
        },
      ),
    );
  }
  
  Widget _buildHomeScreen(AuthProvider authProvider) {
    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }
    
    // Use a FutureBuilder to determine the user's role
    return FutureBuilder<String>(
      future: RoleService().getUserRole(authProvider.user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasData) {
          final userRole = snapshot.data!;
          if (userRole == 'admin') {
            return const AdminHomeScreen();
          } else {
            return const ClientHomeScreen();
          }
        }
        
        // If role can't be determined, log out and return to login
        authProvider.signOut();
        return const LoginScreen();
      },
    );
  }
}
