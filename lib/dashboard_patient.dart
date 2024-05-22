import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _showMedicineForm = false;
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _timeController = TextEditingController();
  List<String> _schedules = [];
  bool _beforeFood = true;
  XFile? _medicineImage;
  List<Map<String, dynamic>> _savedMedicines = [];

  Future<void> _requestPermissions() async {
    if (await Permission.camera.request().isGranted &&
        await Permission.storage.request().isGranted) {
      // Permissions granted
    } else {
      // Permissions denied
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera and Storage permissions are required')),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: source);
    setState(() {
      _medicineImage = image;
    });
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Photo Library'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_camera),
              title: Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _saveImage(File image) async {
    try {
      final directory = await getExternalStorageDirectory();
      final imageDirectory = Directory('${directory!.path}/images');
      if (!await imageDirectory.exists()) {
        await imageDirectory.create(recursive: true);
      }
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newImage = await image.copy('${imageDirectory.path}/$fileName');
      print('Medicine image saved at: ${newImage.path}');
      return newImage.path;
    } catch (e) {
      print('Error saving image: $e');
      return ''; // Return empty string on error
    }
  }

  Future<void> _appendMedicineData(String jsonData) async {
    try {
      final directory = await getExternalStorageDirectory();
      final file = File('${directory!.path}/medicine_data.json');
      if (await file.exists()) {
        final existingData = await file.readAsString();
        final List<dynamic> existingList = jsonDecode(existingData);
        existingList.add(jsonDecode(jsonData));
        await file.writeAsString(jsonEncode(existingList));
      } else {
        await file.writeAsString('[$jsonData]');
      }
    } catch (e) {
      print('Error appending medicine data: $e');
    }
  }

  Future<void> _loadMedicineData() async {
    try {
      final directory = await getExternalStorageDirectory();
      final file = File('${directory!.path}/medicine_data.json');
      if (await file.exists()) {
        final existingData = await file.readAsString();
        final List<dynamic> existingList = jsonDecode(existingData);
        setState(() {
          _savedMedicines = List<Map<String, dynamic>>.from(existingList);
        });
      }
    } catch (e) {
      print('Error loading medicine data: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _loadMedicineData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: _showMedicineForm ? _buildMedicineForm() : _buildSavedMedicines(),
            ),
            _buildAddMedicineButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineForm() {
    return Form(
      child: ListView(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Medicine Name',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _dosageController,
            decoration: InputDecoration(
              labelText: 'Dosage',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Schedule'),
              CheckboxListTile(
                title: Text('Morning'),
                value: _schedules.contains('Morning'),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _schedules.add('Morning');
                    } else {
                      _schedules.remove('Morning');
                    }
                  });
                },
              ),
              CheckboxListTile(
                title: Text('Afternoon'),
                value: _schedules.contains('Afternoon'),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _schedules.add('Afternoon');
                    } else {
                      _schedules.remove('Afternoon');
                    }
                  });
                },
              ),
              CheckboxListTile(
                title: Text('Night'),
                value: _schedules.contains('Night'),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _schedules.add('Night');
                    } else {
                      _schedules.remove('Night');
                    }
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _timeController,
            decoration: InputDecoration(
              labelText: 'Time',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: Text('Before Food'),
                  leading: Radio<bool>(
                    value: true,
                    groupValue: _beforeFood,
                    onChanged: (value) {
                      setState(() {
                        _beforeFood = value!;
                      });
                    },
                  ),
                ),
              ),
              Expanded(
                child: ListTile(
                  title: Text('After Food'),
                  leading: Radio<bool>(
                    value: false,
                    groupValue: _beforeFood,
                    onChanged: (value) {
                      setState(() {
                        _beforeFood = value!;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _medicineImage != null
                  ? Image.file(
                      File(_medicineImage!.path),
                      width: 100,
                      height: 100,
                    )
                  : Text('No image selected'),
              ElevatedButton(
                onPressed: () => _showImageSourceActionSheet(context),
                child: Text('Select Image'),
              ),
            ],
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final imagePath = _medicineImage != null ? await _saveImage(File(_medicineImage!.path)) : '';
              final medicineData = {
                'name': _nameController.text,
                'dosage': _dosageController.text,
                'schedules': _schedules,
                'time': _timeController.text,
                'beforeFood': _beforeFood,
                'imagePath': imagePath,
              };
              final jsonData = jsonEncode(medicineData);
              await _appendMedicineData(jsonData);
              _loadMedicineData();
              setState(() {
                _showMedicineForm = false;
                _nameController.clear();
                _dosageController.clear();
                _timeController.clear();
                _schedules.clear();
                _beforeFood = true;
                _medicineImage = null;
              });
            },
            child: Text('Save Medicine'),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedMedicines() {
    return ListView.builder(
      itemCount: _savedMedicines.length,
      itemBuilder: (context, index) {
        final medicine = _savedMedicines[index];
        return ListTile(
          title: Text(medicine['name']),
          subtitle: Text('Dosage: ${medicine['dosage']}'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MedicineDetailPage(medicine: medicine),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddMedicineButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _showMedicineForm = !_showMedicineForm;
          });
        },
        child: Text(_showMedicineForm ? 'Cancel' : 'Add Medicine'),
      ),
    );
  }
}

class MedicineDetailPage extends StatelessWidget {
  final Map<String, dynamic> medicine;

  MedicineDetailPage({required this.medicine});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(medicine['name']),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dosage: ${medicine['dosage']}',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 10),
              Text(
                'Schedule: ${medicine['schedules'].join(', ')}',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 10),
              Text(
                'Time: ${medicine['time']}',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 10),
              Text(
                'Before Food: ${medicine['beforeFood'] ? 'Yes' : 'No'}',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 10),
              medicine['imagePath'] != null && medicine['imagePath'].isNotEmpty
                  ? Image.file(
                      File(medicine['imagePath']),
                      fit: BoxFit.contain,
                    )
                  : Text('No image available'),
            ],
          ),
        ),
      ),
    );
  }
}
