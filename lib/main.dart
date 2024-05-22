import 'package:flutter/material.dart';

void main() {
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

  void showLoginScreen() {
    setState(() {
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
          ? LoginScreen()
          : ChoiceScreen(onChoiceSelected: showLoginScreen),
    );
  }
}

class ChoiceScreen extends StatelessWidget {
  final VoidCallback onChoiceSelected;

  ChoiceScreen({required this.onChoiceSelected});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: onChoiceSelected,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              backgroundColor: Color.fromARGB(255, 29, 238, 133),
              textStyle: TextStyle(fontSize: 20),
            ),
            child: Text('Patient'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: onChoiceSelected,
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

class LoginScreen extends StatelessWidget {
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
              decoration: InputDecoration(
                labelText: 'Email or Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Handle login logic here
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                backgroundColor: Color.fromARGB(255, 126, 195, 252),
                textStyle: TextStyle(fontSize: 20),
              ),
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
