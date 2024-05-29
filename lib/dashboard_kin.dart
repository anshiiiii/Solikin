import 'package:flutter/material.dart';

class DashboardKinPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kin Dashboard'),
      ),
      body: Center(
        child: Text('Welcome, Kin!', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
