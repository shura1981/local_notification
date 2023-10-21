import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart' as tz;

class Messaje {
  String title;
  String body;
  Messaje({required this.title, required this.body});
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initNotifications() async {
    _initializateZone();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
            iOS: initializationSettingsDarwin,
            android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static _getNotificationDetails(
      {notificationChannelId = 'notificaciones 3',
      notificationChannelName = 'mensajes de elitenutrition',
      notificationChannelDescription = 'notificaciones de elitenutrition',
      ticker = 'ticker'}) {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      notificationChannelId,
      notificationChannelName,
      channelDescription: notificationChannelDescription,
      ticker: ticker,
      importance: Importance.max,
      priority: Priority.high,
      sound: const RawResourceAndroidNotificationSound('alert'),
      ledColor: Colors.blueAccent,
      ledOffMs: 1000,
      ledOnMs: 1000,
      enableLights: true,
    );

    const DarwinNotificationDetails darwinPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(
        iOS: darwinPlatformChannelSpecifics,
        android: androidPlatformChannelSpecifics);
  }

  static tz.TZDateTime _scheduledMinute(DateTime scheduleTime) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month,
        now.day, scheduleTime.hour, scheduleTime.minute, 30);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static DateTime getTime(
      {year = 0, month = 0, day = 0, hour = 0, minute = 0, second = 0}) {
    //obtener la fecha y hora actual y si algún parámetro es igual a cero poner la fecha y hora actual
    DateTime now = DateTime.now();
    year = year == 0 ? now.year : year;
    month = month == 0 ? now.month : month;
    day = day == 0 ? now.day : day;
    hour = hour == 0 ? now.hour : hour;
    minute = minute == 0 ? now.minute : minute;
    second = second == 0 ? now.second : second;
    return DateTime(year, month, day, hour, minute, second);
  }

  static Future<void> scheduleMessage(Messaje msg, DateTime fechaHora) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        msg.title,
        msg.body,
        _scheduledMinute(fechaHora),
        _getNotificationDetails(
            notificationChannelId: 'elitenutrition 0',
            notificationChannelName: 'elitenutrition schedule',
            notificationChannelDescription:
                'notificaciones programadas para elitenutrition'),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);

    print('Notificación programada');
  }

  static Future<void> periodicalMessage(Messaje msg) async {
    RepeatInterval repeatInterval = RepeatInterval.everyMinute;
    await flutterLocalNotificationsPlugin.periodicallyShow(
        1,
        msg.title,
        msg.body,
        repeatInterval,
        _getNotificationDetails(
            notificationChannelId: 'elitenutrition 1',
            notificationChannelName: 'elitenutrition periodic',
            notificationChannelDescription:
                'notificaciones periódicas para elitenutrition'),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);
  }

  static Future<void> message(Messaje msg) async {
    await flutterLocalNotificationsPlugin.show(
      2,
      msg.title,
      msg.body,
      _getNotificationDetails(),
      payload: msg.body,
    );
  }

  static Future<void> _showMyDialog(context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Notificaciones desactivadas'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Las notificaciones están desactivadas.'),
                Text('¿Deseas activarlas?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Activar Notificaciones'),
              onPressed: () {
                // ir a preferencias de notificaciones
                AppSettings
                    .openAppSettings(); // Abre la pantalla de configuración de la aplicación
                // Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> mostrarNotificacion(
      BuildContext context, Messaje msg) async {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission()
        .then((value) {
      if (value == true) {
        final fecha = getTime(minute: 52, hour: 9);
        scheduleMessage(msg, fecha);
      } else {
        _showMyDialog(context);
        // mostrar alerta de que no se otorgó permiso
      }
      return null;
    });
  }

  // close a specific channel notification
  static Future cancel(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // close all the notifications available
  static Future cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  static Future<void> cancelarNotificacion(
      BuildContext context, Messaje msg) async {
    flutterLocalNotificationsPlugin.cancelAll().then((value) {
      return showDialog<void>(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: const Text('Notificación cancelada'),
          content: const Text('La notificación ha sido cancelada'),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
            ),
          ],
        ),
      );
    });

// mostrar dialog de que se canceló la notificación
  }

  static void _initializateZone() {
    initializeTimeZones();
    // Configurar la zona horaria predeterminada
    final colombiaTimeZone = tz.getLocation('America/Bogota');
    tz.setLocalLocation(colombiaTimeZone);
// final now = tz.TZDateTime.now(tz.local);
// print("La hora actual en Colombia es: $now");
  }
}
