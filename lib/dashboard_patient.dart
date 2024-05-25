import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:solikin/services/notifications_service.dart';
import 'dart:io';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _showMedicineForm = false;
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _timeControllers = {
    'Morning': TextEditingController(),
    'Afternoon': TextEditingController(),
    'Night': TextEditingController(),
  };
  List<String> _schedules = [];
  bool _beforeFood = true;
  final _instructionsController = TextEditingController();
  XFile? _medicineImage;
  List<Map<String, dynamic>> _savedMedicines = [];
  final NotificationsService _notificationsService = NotificationsService();

  Future<void> _requestPermissions() async {
    if (await Permission.camera.request().isGranted &&
        await Permission.storage.request().isGranted &&
        await Permission.manageExternalStorage.request().isGranted &&
        await Permission.systemAlertWindow.request().isGranted) {
      // Permissions granted
    } else {
      // Handle permissions not granted
    }
  }

  Future<void> _requestExactAlarmsPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.systemAlertWindow.request().isGranted) {
        // Exact alarms permission granted
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exact alarms permission is required')),
        );
      }
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
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Library'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
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
      if (directory != null) {
        final imagePath = path.join(directory.path, 'MedicineImages');
        final imageDirectory = Directory(imagePath);
        if (!await imageDirectory.exists()) {
          await imageDirectory.create(recursive: true);
        }
        final fileName = path.basenameWithoutExtension(image.path) + '.jpg';
        final newImage = await image.copy(path.join(imageDirectory.path, fileName));
        return newImage.path;
      } else {
        return '';
      }
    } catch (e) {
      print('Error saving image: $e');
      return '';
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
    _requestExactAlarmsPermission();
    _loadMedicineData();
    _notificationsService.initNotification();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _timeControllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, String schedule) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
      useRootNavigator: false,
    );
    if (picked != null) {
      final formattedTime = _formatTime(picked);
      setState(() {
        _timeControllers[schedule]?.text = formattedTime;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = DateFormat.jm(); // uses a 12-hour format
    return format.format(dt);
  }

  Future<void> _scheduleNotifications(Map<String, dynamic> medicineData) async {
    for (int i = 0; i < medicineData['schedule'].length; i++) {
      final schedule = medicineData['schedule'][i];
      final time = medicineData['times'][i];
      if (time != null && time.isNotEmpty) {
        final timeOfDay = DateFormat.jm().parse(time);
        final now = DateTime.now();
        var firstNotification = DateTime(
          now.year,
          now.month,
          now.day,
          timeOfDay.hour,
          timeOfDay.minute,
        );
        if (firstNotification.isBefore(now)) {
          firstNotification = firstNotification.add(Duration(days: 1));
        }
        await _notificationsService.scheduleNotification(
          id: medicineData['name'].hashCode + schedule.hashCode,
          title: 'Time to take your medicine',
          message: '${medicineData['name']} - ${schedule}',
          scheduledNotificationDateTime: firstNotification,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Dashboard'),
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
            decoration: const InputDecoration(
              labelText: 'Medicine Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _dosageController,
            decoration: const InputDecoration(
              labelText: 'Dosage',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Schedule'),
              CheckboxListTile(
                title: const Text('Morning'),
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
              if (_schedules.contains('Morning'))
                TextFormField(
                  controller: _timeControllers['Morning'],
                  readOnly: true,
                  onTap: () => _selectTime(context, 'Morning'),
                  decoration: const InputDecoration(
                    labelText: 'Time for Morning (AM/PM)',
                    border: OutlineInputBorder(),
                  ),
                ),
              CheckboxListTile(
                title: const Text('Afternoon'),
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
              if (_schedules.contains('Afternoon'))
                TextFormField(
                  controller: _timeControllers['Afternoon'],
                  readOnly: true,
                  onTap: () => _selectTime(context, 'Afternoon'),
                  decoration: const InputDecoration(
                    labelText: 'Time for Afternoon (AM/PM)',
                    border: OutlineInputBorder(),
                  ),
                ),
              CheckboxListTile(
                title: const Text('Night'),
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
              if (_schedules.contains('Night'))
                TextFormField(
                  controller: _timeControllers['Night'],
                  readOnly: true,
                  onTap: () => _selectTime(context, 'Night'),
                  decoration: const InputDecoration(
                    labelText: 'Time for Night (AM/PM)',
                    border: OutlineInputBorder(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: const Text('Before Food'),
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
                  title: const Text('After Food'),
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
          const SizedBox(height: 20),
          TextFormField(
            controller: _instructionsController,
            decoration: const InputDecoration(
              labelText: 'Special Instructions',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          _medicineImage == null
              ? const Text('No image selected.')
              : Image.file(File(_medicineImage!.path)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _showImageSourceActionSheet(context),
                child: const Text('Pick Image'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isEmpty || _dosageController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Please fill in all fields'),
                ));
                return;
              }
              String imagePath = '';
              if (_medicineImage != null) {
                imagePath = await _saveImage(File(_medicineImage!.path));
              }
              final medicineData = {
                'name': _nameController.text,
                'dosage': _dosageController.text,
                'schedule': _schedules,
                'times': _schedules.map((schedule) => _timeControllers[schedule]?.text).toList(),
                'beforeFood': _beforeFood,
                'instructions': _instructionsController.text,
                'imagePath': imagePath,
              };
              final jsonData = jsonEncode(medicineData);
              await _appendMedicineData(jsonData);
              await _loadMedicineData();
              await _scheduleNotifications(medicineData);
              setState(() {
                _showMedicineForm = false;
                _nameController.clear();
                _dosageController.clear();
                _timeControllers.forEach((key, controller) {
                  controller.clear();
                });
                _schedules.clear();
                _beforeFood = true;
                _instructionsController.clear();
                _medicineImage = null;
              });
              Navigator.of(context).pop(); // Navigate back to the dashboard
            },
            child: const Text('Save Medicine'),
          ),
          const SizedBox(height: 20),
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
                builder: (context) => MedicineDetailsPage(medicine: medicine),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddMedicineButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _showMedicineForm = true;
          });
        },
        child: const Text('Add Medicine'),
      ),
    );
  }
}

class MedicineDetailsPage extends StatelessWidget {
  final Map<String, dynamic> medicine;

  MedicineDetailsPage({required this.medicine});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(medicine['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('Dosage: ${medicine['dosage']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.normal)),
            const SizedBox(height: 10),
            Text('Schedule: ${medicine['schedule'].join(', ')}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.normal)),
            const SizedBox(height: 10),
            Text('Times: ${medicine['times'].join(', ')}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.normal)),
            const SizedBox(height: 10),
            Text(medicine['beforeFood'] ? 'Before Food' : 'After Food', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.normal)),
            const SizedBox(height: 10),
            Text('Special Instructions: ${medicine['instructions']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.normal)),
            const SizedBox(height: 10),
            medicine['imagePath'].isNotEmpty
                ? Image.file(File(medicine['imagePath']))
                : const Text('No image available', style: TextStyle(fontSize: 24, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
