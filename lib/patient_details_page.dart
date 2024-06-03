import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class PatientDetailsPage extends StatefulWidget {
  final String patientId;
  final String patientName;

  PatientDetailsPage({required this.patientId, required this.patientName});

  @override
  _PatientDetailsPageState createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  List<Map<String, dynamic>> _medicines = [];

  @override
  void initState() {
    super.initState();
    _loadMedicineData();
  }

  Future<void> _loadMedicineData() async {
    try {
      final directory = await getExternalStorageDirectory();
      final file = File('${directory!.path}/patient_${widget.patientId}_medicines.json');
      if (await file.exists()) {
        final data = await file.readAsString();
        final List<dynamic> medicineList = jsonDecode(data);
        setState(() {
          _medicines = List<Map<String, dynamic>>.from(medicineList);
        });
      }
    } catch (e) {
      print('Error loading medicine data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.patientName} Details'),
      ),
      body: _medicines.isEmpty
          ? Center(child: Text('No medicines found'))
          : ListView.builder(
              itemCount: _medicines.length,
              itemBuilder: (context, index) {
                final medicine = _medicines[index];
                return ListTile(
                  title: Text(medicine['name']),
                  subtitle: Text(
                    'Dosage: ${medicine['dosage']}\n'
                    'Schedule: ${medicine['schedule'].join(', ')}\n'
                    'Timings: ${medicine['times'].join(', ')}\n'
                    'Taken: ${medicine['taken'] ? 'Yes' : 'No'}',
                     style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal)
                  ),
                  isThreeLine: true,
                );
              },
            ),
    );
  }
}
