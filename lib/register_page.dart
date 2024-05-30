import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class RegisterPage extends StatefulWidget {
  final String role;

  RegisterPage({required this.role});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _registerUser() async {
    final directory = await getExternalStorageDirectory();
    final file = File('${directory!.path}/${widget.role.toLowerCase()}_data.json');
    final String userId = DateTime.now().millisecondsSinceEpoch.toString(); // Generate unique user ID

    final newUser = {
      'id': userId,
      'name': _nameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'role': widget.role
    };

    if (await file.exists()) {
      final existingData = await file.readAsString();
      final List<dynamic> existingList = jsonDecode(existingData);
      existingList.add(newUser);
      await file.writeAsString(jsonEncode(existingList));
    } else {
      await file.writeAsString(jsonEncode([newUser]));
    }

    // Create an empty file for the patient's medicine details
    if (widget.role == 'Patient') {
      final medicineFile = File('${directory.path}/patient_${userId}_medicines.json');
      await medicineFile.writeAsString(jsonEncode([]));
    } else if (widget.role == 'Kin') {
      final kinFile = File('${directory.path}/kin_${userId}_patientmap.json');
      await kinFile.writeAsString(jsonEncode([]));
    }

    Navigator.pop(context); // Go back to the login screen after registration
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register as ${widget.role}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Register', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
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
              onPressed: _registerUser,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                backgroundColor: Color.fromARGB(255, 126, 195, 252),
                textStyle: TextStyle(fontSize: 20),
              ),
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
