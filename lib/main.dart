import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:solikin/register_page.dart';
import 'package:solikin/services/notifications_service.dart';
import 'dashboard_patient.dart';
import 'dashboard_kin.dart'; // Import the kin dashboard page
import 'package:timezone/data/latest.dart' as tz;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationsService().initNotification();
  tz.initializeTimeZones();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Page',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: const Color.fromARGB(255, 28, 133, 219),
      end: Color.fromARGB(255, 100, 218, 224),
    ).animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    _controller.forward().whenComplete(() {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorAnimation.value,
      body: Center(
        child: Text(
          'Welcome to SOLIKIN',
          style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 10, 6, 6)),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool showLogin = false;
  String selectedRole = '';

  void showLoginScreen(String role) {
    setState(() {
      selectedRole = role;
      showLogin = true;
    });
  }

  void showChoiceScreen() {
    setState(() {
      showLogin = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome To SOLIKIN'),
        leading: showLogin
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: showChoiceScreen,
              )
            : null,
      ),
      body: showLogin
          ? LoginScreen(role: selectedRole)
          : ChoiceScreen(onChoiceSelected: showLoginScreen),
    );
  }
}

class ChoiceScreen extends StatelessWidget {
  final Function(String) onChoiceSelected;

  ChoiceScreen({required this.onChoiceSelected});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () => onChoiceSelected('Patient'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              backgroundColor: Color.fromARGB(255, 29, 238, 133),
              textStyle: TextStyle(fontSize: 20),
            ),
            child: Text('Patient'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => onChoiceSelected('Kin'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              backgroundColor: Color.fromARGB(255, 191, 219, 32),
              textStyle: TextStyle(fontSize: 20),
            ),
            child: Text('Kin'),
          ),
        ],
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final String role;

  LoginScreen({required this.role});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _loginUser() async {
    final directory = await getExternalStorageDirectory();
    final file = File('${directory!.path}/${widget.role.toLowerCase()}_data.json');
    if (await file.exists()) {
      final existingData = await file.readAsString();
      final List<dynamic> users = jsonDecode(existingData);
      final user = users.firstWhere(
        (user) =>
            user['email'] == _emailController.text &&
            user['password'] == _passwordController.text &&
            user['role'] == widget.role,
        orElse: () => null,
      );

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => widget.role == 'Patient'
                  ? DashboardPage(patientId: user['id']) // Pass patient ID
                  : DashboardKinPage(kinId: user['id'],)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid credentials or role')));
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No users found')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Login', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email or Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              obscureText: true,
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loginUser,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                backgroundColor: Color.fromARGB(255, 126, 195, 252),
                textStyle: TextStyle(fontSize: 20),
              ),
              child: Text('Login'),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          RegisterPage(role: widget.role)),
                );
              },
              child: Text('New User? Register Here'),
            ),
          ],
        ),
      ),
    );
  }
}
