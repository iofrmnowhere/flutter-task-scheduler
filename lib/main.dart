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
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary,

      ),
      // This trailing comma makes auto-formatting nicer for build methods.

    );
  }
}
