import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'Themes/theme.dart';
import 'Themes/theme_provider.dart';

// Initialize notification plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
  InitializationSettings(android: initSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // ✅ Request permission for exact alarms (Android 12+)
  final bool? granted = await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.requestExactAlarmsPermission();

  if (granted == false) {
    debugPrint(
        "⚠️ Exact alarm permission NOT granted. Notifications may be delayed.");
  } else {
    debugPrint("✅ Exact alarm permission granted or not required.");
  }
}

Future<void> scheduleTaskNotification(String id, String title, DateTime dateTime) async {
  final androidPlugin =
  flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  final int baseId = id.hashCode;

  bool exactAllowed = true;
  if (androidPlugin != null) {
    final permissionGranted = await androidPlugin.requestExactAlarmsPermission();
    exactAllowed = permissionGranted ?? true;
  }

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'task_channel',
    'Task Notifications',
    channelDescription: 'Notifications for scheduled tasks',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails details = NotificationDetails(android: androidDetails);

  Future<void> safeSchedule(int notificationId, String title, String body, DateTime date) async {
    final tzTime = tz.TZDateTime.from(date, tz.local);

    // Check if the scheduled time is in the future (plus a small buffer)
    if (tzTime.isBefore(tz.TZDateTime.now(tz.local).subtract(const Duration(seconds: 1)))) {
      debugPrint("Skipping past due notification for: $title (ID: $notificationId)");
      return;
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      tzTime,
      details,
      androidScheduleMode: exactAllowed
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );

    // DEBUG OUTPUT
    debugPrint("--- NOTIFICATION SCHEDULED ---");
    debugPrint("Task: $title");
    debugPrint("ID: $notificationId");
    debugPrint("Time: $tzTime");
    debugPrint("Mode: ${exactAllowed ? 'Exact' : 'Inexact'}");
    debugPrint("------------------------------");
  }

  // 🔔 Main notification at the exact task time
  await safeSchedule(
    baseId,
    'Reminder: $title',
    'Your task is due now.',
    dateTime,
  );

  // 🔔 1 day before
  final oneDayBefore = dateTime.subtract(const Duration(days: 1));
  if (oneDayBefore.isAfter(DateTime.now())) {
    await safeSchedule(
      baseId + 1,
      'Heads up: $title',
      'Your task is due tomorrow.',
      oneDayBefore,
    );
  }

  // 🔔 30 minutes before
  final thirtyMinutesBefore = dateTime.subtract(const Duration(minutes: 30));
  if (thirtyMinutesBefore.isAfter(DateTime.now())) {
    await safeSchedule(
      baseId + 2,
      'Upcoming: $title',
      'Your task starts in 30 minutes.',
      thirtyMinutesBefore,
    );
  }
}

// ✅ Cancel notifications for a specific task (using title.hashCode)
Future<void> cancelTaskNotificationsByIdHash(String id) async {
  final int baseId = int.tryParse(id) ?? id.hashCode;
  await flutterLocalNotificationsPlugin.cancel(baseId);
  await flutterLocalNotificationsPlugin.cancel(baseId + 1);
  await flutterLocalNotificationsPlugin.cancel(baseId + 2);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation("Asia/Manila"));
  await initializeNotifications();

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'Flutter Demo',
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeNotifier.themeMode,
          home: const MyHomePage(title: 'Tasks'),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString('tasks');
    if (tasksJson != null) {
      final List decoded = jsonDecode(tasksJson);
      setState(() {
        _tasks = decoded.map((task) {
          return {
            "id": task['id'],              // ✅ ADD THIS
            "name": task['name'],
            "date": task['date'],
            "time": task['time'],
            "rawDate": task['rawDate'] != null ? DateTime.parse(task['rawDate']) : null,
            "rawTime": task['rawTime'] != null
                ? TimeOfDay(hour: task['rawTime']['hour'], minute: task['rawTime']['minute'])
                : null,
          };
        }).toList();
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_tasks.map((task) {
      return {
        "id": task['id'],              // ✅ ADD THIS
        "name": task['name'],
        "date": task['date'],
        "time": task['time'],
        "rawDate": task['rawDate']?.toIso8601String(),
        "rawTime": task['rawTime'] != null
            ? {
          "hour": task['rawTime'].hour,
          "minute": task['rawTime'].minute,
        }
            : null,
      };
    }).toList());
    await prefs.setString('tasks', encoded);
  }


  void _showForm({Map<String, dynamic>? existingTask, int? index}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return TaskForm(existingTask: existingTask);
      },
    );

    if (result == null) return;

    final bool isEdit = index != null;
    String? previousId;
    if (isEdit && _tasks.length > index!) {
      previousId = _tasks[index]['id'];
      if(previousId != null){
        await cancelTaskNotificationsByIdHash(previousId);
      }
    }

    if (result['action'] == 'delete') {
      if (isEdit) {
        setState(() {
          _tasks.removeAt(index!);
        });
        await _saveTasks();
      }
      return;
    }

    final Map<String, dynamic> newTask = {
      "name": result['name'],
      "date": result['date'],
      "time": result['time'],
      "rawDate": result['rawDate'],
      "rawTime": result['rawTime'],
    };

    if (isEdit) {
      newTask['id'] = previousId;
      setState(() {
        _tasks[index!] = newTask;
      });
    } else {
      final String newId = DateTime.now().microsecondsSinceEpoch.toString();
      newTask['id'] = newId;
      setState(() {
        _tasks.add(newTask);
      });
    }

    await _saveTasks();

    if (newTask['rawDate'] != null && newTask['rawTime'] != null) {
      final DateTime dueDateTime = DateTime(
        newTask['rawDate'].year,
        newTask['rawDate'].month,
        newTask['rawDate'].day,
        newTask['rawTime'].hour,
        newTask['rawTime'].minute,
      );

      await scheduleTaskNotification(newTask['id'],newTask['name'], dueDateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        toolbarHeight: 70.0,
        title: Text(
          widget.title,
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        actions: <Widget>[
          PopupMenuButton<ThemeMode>(
            initialValue: context.watch<ThemeNotifier>().themeMode,
            icon: const Icon(Icons.palette),
            onSelected: (ThemeMode newMode) {
              context.read<ThemeNotifier>().setThemeMode(newMode);
            },
            itemBuilder: (context) => <PopupMenuEntry<ThemeMode>>[
              const PopupMenuItem<ThemeMode>(
                value: ThemeMode.system,
                child: Text("System Default"),
              ),
              const PopupMenuItem<ThemeMode>(
                value: ThemeMode.light,
                child: Text("Light Mode"),
              ),
              const PopupMenuItem<ThemeMode>(
                value: ThemeMode.dark,
                child: Text("Dark Mode"),
              ),
            ],
          )
        ],
      ),
      body: ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                _showForm(existingTask: task, index: index);
              },
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        task['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text("Due: ${task['date']}"),
                      const SizedBox(height: 5),
                      Text("@ ${task['time']}"),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        tooltip: 'Add Task',
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TaskForm extends StatefulWidget {
  final Map<String, dynamic>? existingTask;
  const TaskForm({super.key, this.existingTask});

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _txtCtrl;
  DateTime? _slctdate;
  TimeOfDay? _slcttime;

  @override
  void initState() {
    super.initState();
    _txtCtrl = TextEditingController(
        text: widget.existingTask != null ? widget.existingTask!['name'] : '');
    _slctdate =
    widget.existingTask != null ? widget.existingTask!['rawDate'] : null;
    _slcttime =
    widget.existingTask != null ? widget.existingTask!['rawTime'] : null;
  }

  String get _fmtDate {
    if (_slctdate == null) return "";
    return "${_slctdate!.day}/${_slctdate!.month}/${_slctdate!.year}";
  }

  String get _fmtTime {
    if (_slcttime == null) return "";
    return _slcttime!.format(context);
  }

  void _presentDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _slctdate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate != null) {
      setState(() {
        _slctdate = pickedDate;
      });
    }
  }

  void _presentTimePicker() async {
    final now = DateTime.now();
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _slcttime ?? TimeOfDay.now(),
    );
    if (pickedTime != null) {
      bool isCurrentDay = _slctdate != null &&
          _slctdate!.day == now.day &&
          _slctdate!.month == now.month &&
          _slctdate!.year == now.year;

      if (isCurrentDay) {
        final selectedDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        if (!selectedDateTime.isBefore(now)) {
          setState(() {
            _slcttime = pickedTime;
          });
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("That time has passed."),
                duration: Duration(seconds: 2)),
          );
        }
      } else {
        setState(() {
          _slcttime = pickedTime;
        });
      }
    }
  }

  void _submitData() {
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> taskData = {
        "action": "save",
        "name": _txtCtrl.text,
        "date": _fmtDate,
        "rawDate": _slctdate,
        "time": _fmtTime,
        "rawTime": _slcttime,
      };
      Navigator.of(context).pop(taskData);
    }
  }

  @override
  void dispose() {
    _txtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingTask != null ? "Edit Task" : "Add Task"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _txtCtrl,
                decoration: const InputDecoration(
                  labelText: "Task",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a Task";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                controller: TextEditingController(text: _fmtDate),
                onTap: _presentDatePicker,
                decoration: InputDecoration(
                  labelText: "Due Date",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _presentDatePicker,
                  ),
                ),
                validator: (value) {
                  if (_slctdate == null) {
                    return "Please Enter Due Date.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                controller: TextEditingController(text: _fmtTime),
                onTap: _presentTimePicker,
                decoration: InputDecoration(
                  labelText: "Due Time",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.access_time),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _presentTimePicker,
                  ),
                ),
                validator: (value) {
                  if (_slcttime == null) {
                    return "Please Enter Due Time";
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop(null);
          },
        ),
        if (widget.existingTask != null)
          TextButton(
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () {
              Navigator.of(context).pop({
                'action': 'delete',
                'name': widget.existingTask!['name'],
              });
            },
          ),
        ElevatedButton(
          onPressed: _submitData,
          child: const Text("Save"),
        ),
      ],
    );
  }
}
