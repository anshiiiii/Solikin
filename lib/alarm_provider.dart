import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class AlarmProvider extends ChangeNotifier {
  late SharedPreferences preferences;
  List<Map<String, dynamic>> modelist = [];
  List<String> listofstring = [];
  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
  late BuildContext context;

  Future<void> initialize(BuildContext con) async {
    context = con;
    var androidInitialize = const AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOSinitialize = const DarwinInitializationSettings();
    var initializationsSettings = InitializationSettings(android: androidInitialize, iOS: iOSinitialize);
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin!.initialize(initializationsSettings, onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
  }

  void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      debugPrint('notification payload: $payload');
    }
    // Handle navigation to a specific screen if necessary
  }

  Future<void> getData() async {
    preferences = await SharedPreferences.getInstance();
    List<String>? cominglist = preferences.getStringList("data");
    if (cominglist != null) {
      modelist = cominglist.map((e) => json.decode(e) as Map<String, dynamic>).toList();
      notifyListeners();
    }
  }

  Future<void> setData() async {
    listofstring = modelist.map((e) => json.encode(e)).toList();
    await preferences.setStringList("data", listofstring);
    notifyListeners();
  }

  void setAlarm(String label, String dateTime, bool check, String repeat, int id, int milliseconds) {
    modelist.add({
      'label': label,
      'dateTime': dateTime,
      'check': check,
      'repeat': repeat,
      'id': id,
      'milliseconds': milliseconds
    });
    notifyListeners();
  }

  void editSwitch(int index, bool check) {
    modelist[index]['check'] = check;
    notifyListeners();
  }

  Future<void> showNotification() async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      channelDescription: 'your channel description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);
    await flutterLocalNotificationsPlugin!.show(
      0,
      'plain title',
      'plain body',
      notificationDetails,
      payload: 'item x',
    );
  }

  Future<void> scheduleNotification(DateTime dateTime, int randomNumber, String medicineName, String schedule, String dosage) async {
    int newTime = dateTime.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch;
    await flutterLocalNotificationsPlugin!.zonedSchedule(
      randomNumber,
      'Medicine Reminder: $medicineName',
      'Dosage: $dosage\nSchedule: $schedule',
      tz.TZDateTime.now(tz.local).add(Duration(milliseconds: newTime)),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'your channel id',
          'your channel name',
          channelDescription: 'your channel description',
          sound: RawResourceAndroidNotificationSound("audio"),
          autoCancel: false,
          playSound: true,
          priority: Priority.max,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(int notificationId) async {
    await flutterLocalNotificationsPlugin!.cancel(notificationId);
  }
}
