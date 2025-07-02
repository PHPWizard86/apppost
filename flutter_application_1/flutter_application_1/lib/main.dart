import 'package:flutter/material.dart';
import 'user.dart';
import 'login_page.dart';
import 'user_panel.dart';
import 'admin_panel.dart';

User? currentUser;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: AuthWrapper());
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return LoginPage(
        onLogin: (user) {
          setState(() {
            currentUser = user;
          });
        },
      );
    } else if (currentUser!.role == 'admin') {
      return AdminPanel(
        currentUser: currentUser!,
        onLogout: () {
          setState(() {
            currentUser = null;
          });
        },
      );
    } else {
      return UserPanel(
        currentUser: currentUser!,
        onLogout: () {
          setState(() {
            currentUser = null;
          });
        },
      );
    }
  }
}
