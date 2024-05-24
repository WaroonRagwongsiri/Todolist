import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TodoList',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.grey),
      ),
      home: const MyHomePage(title: 'TodoList'),
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
  late SharedPreferences _prefs;
  List<Map<String, String>> _items = [];
  List<Map<String, String>> _finish_items = [];
  int currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _readFromPrefs();
    _readDoneFromPrefs();
  }

  void _readFromPrefs() {
    final jsonData = _prefs.getString('items');
    if (jsonData != null) {
      final List<Map<String, String>> decodedData =
          (json.decode(jsonData) as List<dynamic>)
              .map((dynamic item) =>
                  Map<String, String>.from(item as Map<String, dynamic>))
              .toList();
      setState(() {
        _items = decodedData;
      });
    }
  }

  void _readDoneFromPrefs() {
    final jsonData = _prefs.getString('done_items');
    if (jsonData != null) {
      final List<Map<String, String>> decodedData =
          (json.decode(jsonData) as List<dynamic>)
              .map((dynamic item) =>
                  Map<String, String>.from(item as Map<String, dynamic>))
              .toList();
      setState(() {
        _finish_items = decodedData;
      });
    }
  }

  Future<void> _writeToPrefs(List<Map<String, String>> items) async {
    final jsonData = json.encode(items);
    await _prefs.setString('items', jsonData);
  }

  Future<void> _writeDoneToPrefs(List<Map<String, String>> finish_items) async {
    final jsonData = json.encode(finish_items);
    await _prefs.setString('done_items', jsonData);
  }

  Future<void> removeTaskFromPrefs(int index) async {
    setState(() {
      _finish_items.add(_items[index]);
      _items.removeAt(index);
    });
    await _writeToPrefs(_items);
    await _writeDoneToPrefs(_finish_items);
  }

  Future<void> removeDoneTaskFromPrefs(int index) async {
    setState(() {
      _finish_items.removeAt(index);
    });
    await _writeDoneToPrefs(_finish_items);
  }

  void _addItem(String task, String date) {
    setState(() {
      _items.add({'task': task, 'date': date});
    });
    _writeToPrefs(_items);
  }

  void _showListCreator() {
    String task = '';
    String date = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                decoration: const InputDecoration(labelText: 'Task'),
                onChanged: (value) => task = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Date'),
                onChanged: (value) => date = value,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                _addItem(task, date);
                Navigator.of(context).pop();
              },
              child: const Text('Confirm'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            style: const TextStyle(
                color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orange,
        ),
        body: IndexedStack(
          index: currentPageIndex,
          children: [
            Column(
              children: [
                Flexible(
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_items[index]['task']!),
                        subtitle: Text(_items[index]['date']!),
                        leading: Column(
                          children: <Widget>[
                            FloatingActionButton.small(
                              child: const Icon(Icons.check_circle),
                              onPressed: () {
                                removeTaskFromPrefs(index);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                FloatingActionButton(
                  onPressed: _showListCreator,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            Container(
              child: ListView.builder(
                itemCount: _finish_items.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_finish_items[index]['task']!),
                    subtitle: Text(_finish_items[index]['date']!),
                    leading: Column(
                      children: <Widget>[
                        FloatingActionButton.small(
                          child: const Icon(Icons.delete),
                          onPressed: () {
                            removeDoneTaskFromPrefs(index);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
            });
          },
          selectedIndex: currentPageIndex,
          destinations: const <Widget>[
            NavigationDestination(
              selectedIcon: Icon(Icons.home),
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.flag),
              icon: Icon(Icons.flag_outlined),
              label: 'Done',
            ),
          ],
        ));
  }
}
