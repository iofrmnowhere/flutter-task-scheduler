import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'Themes/theme.dart';
import 'Themes/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeNotifier(),
      child: const MyApp(),
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child){
          return MaterialApp(
            title: 'Flutter Demo',
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeNotifier.themeMode,
            home: const MyHomePage(title: 'Tasks'),
          );
        }
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
  int _counter = 0;
  List<Widget> _widgetList = [];

  void _showForm() async{
    final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (BuildContext context){
          return const TaskForm();
        }
    );
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
      DateTime now = DateTime.now();

      Widget newWidget = Card(
        child: Padding(
            padding: EdgeInsets.all(15.0),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("Task #$_counter"),
            Text("$now"),
            Text("6:30 P.M.")
          ],
        ),
        ),
      );

        _widgetList.add(newWidget);
        //pang clear lol
      //_widgetList = [];
      //_counter = 0;

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        toolbarHeight: 70.0,
        title: Text(widget.title,
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.primary
          ),
        ),

        actions: <Widget>[
          PopupMenuButton<ThemeMode>(
              initialValue: context.watch<ThemeNotifier>().themeMode,
              icon: const Icon(Icons.palette),
              onSelected: (ThemeMode newMode){
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


      body: ListView(
          children: <Widget>[
            ..._widgetList,
          ],
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showForm,
        tooltip: 'Increment',
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),

      ),
      // This trailing comma makes auto-formatting nicer for build methods.

    );
  }
}

class TaskForm extends StatefulWidget{
  const TaskForm({super.key});
  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm>{
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _txtCtrl = TextEditingController();
  DateTime? _slctdate;
  TimeOfDay? _slcttime;
  //pang format
  String get _fmtDate{
    if (_slctdate == null){
      return "";
    }
    return "${_slctdate!.day}/${_slctdate!.month}/${_slctdate}";
  }
  String get _fmtTime{
    if(_slcttime == null){
      return '';
    }
    return _slcttime!.format(context);
  }
  //open pickers
  void _presentDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
        context: context,
        initialDate: _slctdate ?? now,
        firstDate: now,
        lastDate: DateTime(now.year + 5)
    );
    if (pickedDate != null) {
      setState(() {
        _slctdate = pickedDate;
      });
    }
  }
    void _presentTimePicker() async{
      final now = TimeOfDay.now();
      final pickedTime = await showTimePicker(
          context: context,
          initialTime: _slcttime ?? now
      );
      if (pickedTime != null){
        setState(() {
          _slcttime = pickedTime;
        });
      }
    }

    @override
    void dispose(){
      _txtCtrl.dispose();
      super.dispose();
    }

    //validation and form submission
    void _submitData(){
      if(_formKey.currentState!.validate()){
        final Map<String, dynamic> taskData = {
          "name": _txtCtrl.text,
          "date":_fmtDate,
          "rawDate":_slctdate,
          "time":_fmtTime,
          "rawTime":_slcttime
        };
        Navigator.of(context).pop(taskData);
      }
    }
    Widget build(BuildContext context){
      return AlertDialog(
        title: const Text("Enter a Task"),
        content: SingleChildScrollView(
          child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  //task name
                  TextFormField(
                    controller: _txtCtrl,
                    decoration: const InputDecoration(
                      labelText:"Task",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label_outline)
                    ),
                    validator: (value){
                      if(value == null || value.isEmpty){
                        return "Please enter a Task";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  //date
                  TextFormField(
                    readOnly: true,
                    controller:TextEditingController(text: _fmtDate),
                    onTap: _presentDatePicker,
                    decoration: InputDecoration(
                      labelText: "Due Date",
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.calendar_today),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _presentDatePicker,
                      )
                    ),
                    validator: (value){
                      if (_slctdate == null){
                        return "Please Enter Due Date.";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  //time
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
                    validator: (value){
                      if(_slcttime == null){
                        return "Please Enter Due Time";
                      }
                      return null;
                    }
                  ),
                ],//parent ng mga forms
              )
          ),
        ),
        //buttons
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: (){
              Navigator.of(context).pop(null);
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
