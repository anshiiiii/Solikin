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
  String? _selectedKinId;
  List<Map<String, String>> _kinList = [];

  @override
  void initState() {
    super.initState();
    if (widget.role == 'Patient') {
      _loadKinList();
    }
  }

  Future<void> _loadKinList() async {
  try {
    final directory = await getExternalStorageDirectory();
    if (directory == null) {
      throw Exception("Could not get the external storage directory");
    }

    final kinFile = File('${directory.path}/kin_data.json');
    print('Looking for file at: ${kinFile.path}'); // Debugging statement

    if (await kinFile.exists()) {
      print('File exists, reading data'); // Debugging statement
      final kinData = await kinFile.readAsString();
      print('Kin data: $kinData'); // Print the file content for debugging
      final List<dynamic> kinList = jsonDecode(kinData);

      setState(() {
        _kinList = kinList.map((kin) {
          return {
            'id': kin['id'] as String,
            'name': kin['name'] as String,
          };
        }).toList();
      });
      print('Kin list loaded: $_kinList'); // Debugging statement
    } else {
      print('File does not exist'); // Debugging statement
    }
  } catch (e) {
    print("Error loading kin list: $e");
  }
}

  Future<void> _registerUser() async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception("Could not get the external storage directory");
      }

      final file = File('${directory.path}/${widget.role.toLowerCase()}_data.json');
      final String userId = DateTime.now().millisecondsSinceEpoch.toString(); // Generate unique user ID

      final newUser = {
        'id': userId,
        'name': _nameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'role': widget.role,
        if (widget.role == 'Patient') 'kinId': _selectedKinId
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

        // Add patient ID to the kin's patient map
        if (_selectedKinId != null) {
          final kinFile = File('${directory.path}/kin_${_selectedKinId}_patientmap.json');
          List<dynamic> patientMap = [];

          if (await kinFile.exists()) {
            final existingKinData = await kinFile.readAsString();
            patientMap = jsonDecode(existingKinData);
          }

          patientMap.add({'patientId': userId});
          await kinFile.writeAsString(jsonEncode(patientMap));
        }
      } else if (widget.role == 'Kin') {
        final kinFile = File('${directory.path}/kin_${userId}_patientmap.json');
        await kinFile.writeAsString(jsonEncode([]));
      }

      Navigator.pop(context); // Go back to the login screen after registration
    } catch (e) {
      print("Error registering user: $e");
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    } else {
      String patt = r'^[a-zA-Z ]+$';
      RegExp regExp = RegExp(patt);
      if (!regExp.hasMatch(value)) {
        return 'Please enter a valid name';
      }
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email or phone number';
    }
    else{
            String patt = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
            RegExp regExp = new RegExp(patt);
            if (!regExp.hasMatch(value)) {
                return 'Please enter a valid email';
              }
      }
    return null;
  }

 String? _validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your password';
  }
  // Check if the password is at least 8 characters long
  if (value.length < 8) {
    return 'Password must be at least 8 characters long';
  }
  // Check if the password contains at least one uppercase letter, one lowercase letter, one number, and one special character
  String pattern = r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}$';
  RegExp regex = RegExp(pattern);
  if (!regex.hasMatch(value)) {
    return 'Password must include atleast one uppercase, lowercase letters,a digit and a special character';
  }
  return null;
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
            const Text('Register', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(
                labelText: 'Enter your Name',
                border: OutlineInputBorder(),
              ),
              validator: _validateName,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(
                labelText: 'Enter your Email',
                border: OutlineInputBorder(),
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: 20),
            TextFormField(
              obscureText: true,
              controller: _passwordController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
               validator: _validatePassword,
            ),
            if (widget.role == 'Patient') ...[
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedKinId,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedKinId = newValue;
                  });
                },
                items: _kinList.map<DropdownMenuItem<String>>((Map<String, String> kin) {
                  return DropdownMenuItem<String>(
                    value: kin['id'],
                    child: Text('${kin['id']} - ${kin['name']}'),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  labelText: 'Choose your kin',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registerUser,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                backgroundColor: Colors.cyan.shade400,
              ),
              child: const DefaultTextStyle(
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              child:  Text('Register'),
            ),
            ),
          ],
        ),
      ),
    );
  }
}
