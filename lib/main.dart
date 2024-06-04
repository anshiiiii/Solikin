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
      title: 'Solikin',
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

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

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
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/splash1.jpg', 
            fit: BoxFit.cover,
          ),
           const Positioned(
          bottom: 240, // Adjust this value to position the text
          left: 0,
          right: 0,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SOLIKIN',
                  style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Personalized Health care',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
        ),
        ],
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
        title: const Text(
          'Welcome To SOLIKIN',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        leading: showLogin
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: showChoiceScreen,
              )
                      : IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                // Handle menu button press
              },
            ),
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
          const Text(
            'Choose your role',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => onChoiceSelected('Patient'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              backgroundColor: Colors.cyan.shade600,
              textStyle: const TextStyle(fontSize: 20),
            ),
            child: const Text('Patient'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => onChoiceSelected('Kin'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              backgroundColor:  Colors.cyan.shade300,
              textStyle: const TextStyle(fontSize: 20),
            ),
            child: const Text('Kin'),
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
            const SnackBar(content: Text('Invalid credentials or role')));
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No users found')));
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
            const Text('Login', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email or Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              obscureText: true,
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loginUser,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                backgroundColor: const Color.fromARGB(255, 126, 195, 252),
                textStyle: const TextStyle(fontSize: 20),
              ),
              child: const Text('Login'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          RegisterPage(role: widget.role)),
                );
              },
              child: const Text('New User? Register Here'),
            ),
          ],
        ),
      ),
    );
  }
}
