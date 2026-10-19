import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

final _notifications = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _notifications.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  runApp(const RememberApp());
}

class RememberApp extends StatelessWidget {
  const RememberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Remember',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const ReminderPage(),
    );
  }
}

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  final _message = TextEditingController();
  Duration _delay = const Duration(minutes: 5);

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _schedule() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final allowed = await android?.requestNotificationsPermission() ?? true;
    if (!mounted) return;
    if (!allowed) {
      _toast('Allow notifications for this app to get reminders.');
      return;
    }

    final when = DateTime.now().add(_delay);
    await _notifications.zonedSchedule(
      id: DateTime.now().millisecondsSinceEpoch & 0x7fffffff,
      title: 'Remember',
      body: _message.text.trim(),
      // Only the instant matters, so UTC avoids needing the device's timezone.
      scheduledDate: tz.TZDateTime.from(when, tz.UTC),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders',
          'Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    if (!mounted) return;

    final at = TimeOfDay.fromDateTime(when).format(context);
    _toast('Reminder set for $at');
    _message.clear();
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Remember')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _message,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Text(
                'Remind me in',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 180,
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hm,
                  initialTimerDuration: _delay,
                  onTimerDurationChanged: (d) => setState(() => _delay = d),
                ),
              ),
              const SizedBox(height: 24),
              ListenableBuilder(
                listenable: _message,
                builder: (context, _) => FilledButton(
                  onPressed:
                      _message.text.trim().isEmpty || _delay == Duration.zero
                      ? null
                      : _schedule,
                  child: const Text('Remind me'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
