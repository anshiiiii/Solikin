import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:solikin/main.dart';
import 'package:solikin/patient_details_page.dart'; // Import the HomePage for redirection

class DashboardKinPage extends StatefulWidget {
  final String kinId;

  DashboardKinPage({required this.kinId});

  @override
  _DashboardKinPageState createState() => _DashboardKinPageState();
}

class _DashboardKinPageState extends State<DashboardKinPage> {
  List<Map<String, dynamic>> _patients = [];

  @override
  void initState() {
    super.initState();
    print('Kin ID: ${widget.kinId}'); // Debug print to verify kinId
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
  try {
    final directory = await getExternalStorageDirectory();
    final mappingFilePath = '${directory!.path}/kin_${widget.kinId}_patientmap.json';
    final mappingFile = File(mappingFilePath);

    print('Mapping file path: $mappingFilePath'); // Debug print to check file path

    if (await mappingFile.exists()) {
      final data = await mappingFile.readAsString();
      print('Mapping data: $data'); // Print the file content for debugging
      final List<dynamic> patientIds = jsonDecode(data);

      print('Patient IDs: $patientIds'); // Debug print to check patient IDs

      List<Map<String, dynamic>> patients = [];

      final patientFilePath = '${directory.path}/patient_data.json';
      final patientFile = File(patientFilePath);
      if (await patientFile.exists()) {
        final patientData = await patientFile.readAsString();
        final List<dynamic> patientList = jsonDecode(patientData);

        for (var patientId in patientIds) {
          for (var patient in patientList) {
            if (patient['id'] == patientId['patientId']) { // Note the patientId mapping
              patients.add({
                'id': patient['id'],
                'name': patient['name'],
                'email': patient['email'],
              });
              break;
            }
          }
        }
      } else {
        print('Patient data file not found'); // Debug print if patient data file doesn't exist
      }

      setState(() {
        _patients = patients;
      });

      print('Patients: $_patients'); // Debug print to check loaded patients
    } else {
      print('Mapping file not found: $mappingFilePath'); // Debug print if mapping file doesn't exist
    }
  } catch (e) {
    print('Error loading patient data: $e');
  }
}


  Future<void> _logout() async {
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
            onPressed: _logout,
          ),
        ],
      ),
      body: _patients.isEmpty
          ? Center(
              child: Text('No patients found', style: TextStyle(fontSize: 24)),
            )
          : ListView.builder(
              itemCount: _patients.length,
              itemBuilder: (context, index) {
                final patient = _patients[index];
                return ListTile(
                  title: Text(patient['name']),
                  subtitle: Text(patient['email']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientDetailsPage(
                          patientId: patient['id'],
                          patientName: patient['name'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
