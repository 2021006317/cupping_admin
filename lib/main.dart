import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'alarm_screen.dart';
import 'firebase_options.dart';
import 'home_screen.dart';

// ...

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    final routes = {
      HomeScreen.routeName: (context) => const HomeScreen(),
      AlarmScreen.routeName: (context) => const AlarmScreen(),
    };

    return MaterialApp(
      title: 'cupping_admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      routes: routes,
      home: const HomeScreen()
    );
  }
}