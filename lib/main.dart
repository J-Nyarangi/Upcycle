import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'package:provider/provider.dart'; // Provider for state management
import 'screens/signup_page.dart';
import 'screens/login_page.dart';
import 'screens/forgot_password_page.dart';
import 'screens/home_page.dart';
import 'screens/capture_item_page.dart';
import 'screens/marketplace_page.dart';
import 'screens/upload_project_page.dart';
import 'screens/learning_page.dart';
import 'screens/cart_screen.dart'; 
import 'screens/cart_provider.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  await Firebase.initializeApp(); // Initializing Firebase
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()), 
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      theme: ThemeData(
        primarySwatch: Colors.green, 
        scaffoldBackgroundColor: Colors.grey[50], 
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.black12,
          titleTextStyle: TextStyle(
            color: Colors.green[900],
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
          iconTheme: IconThemeData(color: Colors.green[800]),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[800], 
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      routes: {
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignUpPage(),
        '/forgot_password': (context) => ForgotPasswordPage(),
        '/home': (context) => HomePage(),
        '/capture_item': (context) => CaptureItemPage(),
        '/marketplace': (context) => MarketplacePage(),
        '/upload_project': (context) => UploadProjectPage(),
        '/learning': (context) => LearningPage(),
        '/cart': (context) => CartScreen(), 
      },
    );
  }
}