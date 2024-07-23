import 'dart:convert';
import 'dart:io';

import 'package:android_intent/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:path_provider/path_provider.dart';
import 'package:solikin/register_page.dart';
import 'dashboard_patient.dart';
import 'alarm_provider.dart';
import 'dashboard_kin.dart'; // Import the kin dashboard page
import 'package:timezone/data/latest.dart' as tz;


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  initializeNotifications();
  runApp(MyApp());
}

void initializeNotifications() async {
  var androidInitialize = const AndroidInitializationSettings('@mipmap/ic_launcher');
  var iOSinitialize = const DarwinInitializationSettings();
  var initializationSettings = InitializationSettings(android: androidInitialize, iOS: iOSinitialize);
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.initialize(initializationSettings, onDidReceiveNotificationResponse: (response) {
    // Handle notification response
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AlarmProvider(),
      child: MaterialApp(
        title: 'Solikin',
        theme: ThemeData(
          primarySwatch: Colors.cyan,
        ),
        home: SplashScreen(),
      ),
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

    final alarmProvider = Provider.of<AlarmProvider>(context, listen: false);
    alarmProvider.initialize(context);

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
            bottom: 260, // Adjust this value to position the text
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
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  
     Set<Permission> _requestedPermissions = {};


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Welcome To SOLIKIN',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(38, 198, 218, 1),
          ),
        ),
      ),
      body: _buildChoiceScreen(context),
    );
  }


Future<void> checkPermission(Permission permission, BuildContext context) async {
  
  if (_requestedPermissions.contains(permission)) {
      return;
    }

  _requestedPermissions.add(permission);
  if (permission == Permission.manageExternalStorage) {
    if(await Permission.manageExternalStorage.isDenied)
    {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Storage Permission'),
        content: Text('Please allow storage permission to store your details.'),
        actions: [
          ElevatedButton(
            child: Text('OK'),
            onPressed: () async {
              Navigator.of(context).pop();
              if (await _requestStoragePermission()) {
                setState(() {});
                _requestNextPermission(context);
              } 
              else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Storage permissions are required to save your data in your device.'),
                ));
              }
            },
          ),
        ],
      ),
    );
    }
  }
  else if (permission == Permission.systemAlertWindow) {
    if(await Permission.systemAlertWindow.isDenied)
    {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Display Over Other Apps Permission'),
        content: Text('Please grant the Display Over Other Apps permission for getting your remainders, please follow these steps:\n\n1. Tap "OK"\n2. You will be directed to"Display Over Other Apps"\n3. Select "Solikin"\n4. Tap "Allow" or Press the toggle button'),
        actions: [
          ElevatedButton(
            child: Text('OK'),
            onPressed: () async {
              Navigator.of(context).pop();
              final intent = AndroidIntent(
                action: 'android.settings.action.MANAGE_OVERLAY_PERMISSION',
              );
              await intent.launch();
              if (await _requestSystemAlertWindowPermission()) {
                _requestNextPermission(context);
              } 
              else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Display Over Other Apps permission is required to use this app'),
                ));
              }
            },
          ),
        ],
      ),
    );
    }
  }
  else {
    final status = await permission.request();
    if (status.isGranted) {
      _requestNextPermission(context);
    } 
    else if (status.isDenied || status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permission for $permission is required to use this app')),
      );
    }
  }
}

void _requestNextPermission(BuildContext context) async {
  final permissions = [
    Permission.camera,
    Permission.notification,
    Permission.photos,
    Permission.manageExternalStorage,
    Permission.systemAlertWindow,
    Permission.scheduleExactAlarm,
  ];
  for (var permission in permissions) {
    if (_requestedPermissions.contains(permission)) {
      continue;
    }
    final status = await permission.status;
    if (status != PermissionStatus.granted) {
      _requestedPermissions.add(permission);
      await _requestPermission(permission, context);
      break;
    }
  }
}

Future<void> _requestPermissions(BuildContext context) async {
  final permissions = [
    Permission.camera,
    Permission.notification,
    Permission.photos,
    Permission.manageExternalStorage,
    Permission.systemAlertWindow,
    Permission.scheduleExactAlarm,
  ];

  for (var permission in permissions) {
    await checkPermission(permission, context);
  }
}

Future<void> _requestPermission(Permission permission, BuildContext context) async {
  if (await permission.isGranted) {
    return;
  }
  await checkPermission(permission, context);
}

Future<bool> _requestStoragePermission() async {
  AndroidDeviceInfo build = await DeviceInfoPlugin().androidInfo;
  if (build.version.sdkInt >= 30) {
    var re = await Permission.manageExternalStorage.request();
    return re.isGranted;
  } else {
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    } else {
      var result = await Permission.manageExternalStorage.request();
      return result.isGranted;
    }
  }
}

Future<bool> _requestSystemAlertWindowPermission() async {
  AndroidDeviceInfo build = await DeviceInfoPlugin().androidInfo;
  if (build.version.sdkInt >= 23) {
    var re = await Permission.systemAlertWindow.request();
    return re.isGranted;
  } 
  else {
    if (await Permission.systemAlertWindow.isGranted) {
      return true;
    } 
    else {
      var result = await Permission.systemAlertWindow.request();
      return result.isGranted;
    }
  }
}

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _requestPermissions(context).then((_) {
      final alarmProvider = Provider.of<AlarmProvider>(context, listen: false);
      alarmProvider.initialize(context);
    });
  });
}

  Widget _buildChoiceScreen(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Choose your role',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color.fromRGBO(38, 198, 218, 1)),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _navigateToLoginScreen(context, 'Patient'),
              style: ElevatedButton.styleFrom(
                elevation: 5,
                padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 30),
                backgroundColor: Colors.cyan.shade400,
              ),
              child: const DefaultTextStyle(
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                child: Text('PATIENT'),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _navigateToLoginScreen(context, 'Kin'),
              style: ElevatedButton.styleFrom(
                elevation: 5,
                padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 30),
                backgroundColor: Colors.cyan.shade400,
              ),
              child: const DefaultTextStyle(
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                child: Text('KIN'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToLoginScreen(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen(role: role)),
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
        Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
        builder: (context) => widget.role == 'Patient'
          ? DashboardPage(patientId: user['id'])
          : DashboardKinPage(kinId: user['id']),
        ),
        (Route<dynamic> route) => false,
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
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Login as ${widget.role}', style: const TextStyle(fontWeight: FontWeight.bold,color: Color.fromRGBO(38, 198, 218, 1))), // Set the title based on the role
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                  backgroundColor: Colors.cyan.shade400,
                ),
                child: const DefaultTextStyle(
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                child: const Text('Login'),
              ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => RegisterPage(role: widget.role)),
                  );
                },
                child: const Text('New User? Register Here', style: TextStyle(fontSize:20,fontWeight: FontWeight.bold, color: Color.fromRGBO(38, 198, 218, 1))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
