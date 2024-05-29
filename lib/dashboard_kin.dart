import 'package:flutter/material.dart';
import 'package:solikin/main.dart'; // Import the HomePage for redirection

class DashboardKinPage extends StatelessWidget {
  Future<void> _logout(BuildContext context) async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Text('Welcome, Kin!', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
