// dart
import 'package:flutter/material.dart';
import 'UI/auth/login_view.dart';
import 'UI/navigation/home.dart';
import 'utils/db_helper.dart';
import 'models/user.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<User?> _getUser() async {
    final dbHelper = DbHelper();
    await dbHelper.openDb();
    return await dbHelper.getUser();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FuelTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          onPrimary: Colors.white,
          secondary: Colors.blueGrey,
          onSecondary: Colors.white,
        ),
      ),
      home: FutureBuilder<User?>(
        future: _getUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text('Error iniciando la app')),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return const Home();
          }
          return LoginView();
        },
      ),
    );
  }
}