import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Today\'s Tasks',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(), // Set SplashScreen as home
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use a Future to navigate after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const TaskPage()),
      );
    });

    return Scaffold(
      body: Container(
        width: double.infinity, // Full width
        height: double.infinity, // Full height
        decoration: const BoxDecoration(
          image: DecorationImage(
            image:
                AssetImage('imtihon/A.jpg'), // Ensure the image path is correct
            fit:
                BoxFit.cover, // This makes the image cover the entire container
          ),
        ),
      ),
    );
  }
}

class TaskPage extends StatefulWidget {
  const TaskPage({Key? key}) : super(key: key);

  @override
  TaskPageState createState() => TaskPageState();
}

class TaskPageState extends State<TaskPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, List<Task>> categorizedTasks = {};
  final List<String> categories = ['Personal', 'Default', 'Study', 'Work'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/tasks.json');
  }

  Future<void> _loadTasks() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        String contents = await file.readAsString();
        final loadedTasks = (jsonDecode(contents) as List)
            .map((taskJson) => Task.fromJson(taskJson))
            .toList();

        // Group tasks by category
        for (var task in loadedTasks) {
          categorizedTasks.putIfAbsent(task.category, () => []).add(task);
        }
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error loading tasks: $e");
    }
  }

  Future<void> _saveTasks() async {
    try {
      final file = await _localFile;
      final tasksJson = jsonEncode(categorizedTasks.values
          .expand((x) => x)
          .map((task) => task.toJson())
          .toList());
      await file.writeAsString(tasksJson);
    } catch (e) {
      debugPrint("Error saving tasks: $e");
    }
  }

  void _addTask(Task task) {
    setState(() {
      categorizedTasks.putIfAbsent(task.category, () => []).add(task);
      _saveTasks();
    });
  }

  void _removeTask(Task task) {
    setState(() {
      categorizedTasks[task.category]?.remove(task);
      _saveTasks();
    });
  }

  void _toggleTask(Task task) {
    setState(() {
      task.isCompleted = !task.isCompleted; // Toggle the completion state
      _saveTasks(); // Save the updated tasks list
    });
  }

  List<Task> _getFilteredTasks(String category) {
    return categorizedTasks[category] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Today's Tasks",
          style: TextStyle(color: Colors.greenAccent, fontSize: 24),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: categories.map((category) => Tab(text: category)).toList(),
          labelColor: Colors.greenAccent,
          unselectedLabelColor: Colors.grey,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(color: Colors.greenAccent, width: 2),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage(
                'imtihon/A.jpg'), // Update with your image path
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.darken,
            ),
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: categories.map((category) {
            return TaskList(
              tasks: _getFilteredTasks(category),
              onRemove: _removeTask,
              onToggle: _toggleTask,
            );
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: Colors.greenAccent,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddTaskDialog(
          onAdd: _addTask,
          category: categories[_tabController.index],
        );
      },
    );
  }
}

class Task {
  String title;
  String description;
  DateTime date;
  TimeOfDay time;
  bool isCompleted;
  String category;

  Task({
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.category,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'time': '${time.hour}:${time.minute}',
      'isCompleted': isCompleted,
      'category': category,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      time: TimeOfDay(
        hour: int.parse(json['time'].split(':')[0]),
        minute: int.parse(json['time'].split(':')[1]),
      ),
      isCompleted: json['isCompleted'] ?? false,
      category: json['category'] ?? 'Default',
    );
  }
}

class TaskList extends StatelessWidget {
  final List<Task> tasks;
  final Function(Task) onRemove;
  final Function(Task) onToggle;

  const TaskList({
    Key? key,
    required this.tasks,
    required this.onRemove,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Image.asset(
          'imtihon/A.jpg', // Path to your "no tasks" image
          fit: BoxFit.cover,
        ),
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return Dismissible(
          key: Key(
              '${tasks[index].title}_${DateTime.now().millisecondsSinceEpoch}'),
          onDismissed: (direction) => onRemove(tasks[index]),
          background: Container(
            color: Colors.transparent, // Keep it transparent
          ),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.black54,
            child: ListTile(
              title: _buildTitle(tasks[index]),
              subtitle: Text(
                _formatDateTime(context, tasks[index].date, tasks[index].time),
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: Checkbox(
                value: tasks[index].isCompleted,
                onChanged: (bool? value) {
                  // Toggle task completion
                  onToggle(tasks[index]);
                },
                activeColor: Colors.greenAccent,
              ),
              onTap: () {
                // Navigate to DetailsScreen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DetailsScreen(task: tasks[index]),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle(Task task) {
    if (task.isCompleted) {
      return Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: task.title.length * 8.0,
                height: 2,
                color: Colors.yellow,
              ),
            ),
          ),
          Text(
            task.title,
            style: const TextStyle(
              color: Colors.green,
              decoration: TextDecoration.lineThrough,
              decorationColor: Colors.yellow,
              decorationThickness: 2,
            ),
          ),
        ],
      );
    } else {
      return Text(
        task.title,
        style: const TextStyle(color: Colors.green),
      );
    }
  }

  String _formatDateTime(BuildContext context, DateTime date, TimeOfDay time) {
    final dateString = '${date.day}/${date.month}/${date.year}';
    final timeString = '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    return '$dateString at $timeString';
  }
}

class AddTaskDialog extends StatefulWidget {
  final Function(Task) onAdd;
  final String category;

  const AddTaskDialog({
    Key? key,
    required this.onAdd,
    required this.category,
  }) : super(key: key);

  @override
  AddTaskDialogState createState() => AddTaskDialogState();
}

class AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF121212), // Dark background
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // No rounded corners
      ),
      title: const Text(
        'Adding personal Default',
        style: TextStyle(
            color: Colors.greenAccent, fontSize: 18), // Smaller title size
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Task',
                labelStyle: TextStyle(color: Colors.white),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.greenAccent),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a task title';
                }
                return null;
              },
              onChanged: (value) {
                _title = value;
              },
            ),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: Colors.white),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.greenAccent),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                _description = value;
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly, // Closer spacing
              children: [
                InkWell(
                  onTap: _selectDate,
                  child: const Column(
                    children: [
                      Text('Pick Date',
                          style: TextStyle(
                              color: Colors.green)), // Pick Date in green
                    ],
                  ),
                ),
                InkWell(
                  onTap: _selectTime,
                  child: const Column(
                    children: [
                      Text('Pick Time',
                          style: TextStyle(
                              color: Colors.green)), // Pick Time in green
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'Close',
            style: TextStyle(
                color: Colors.purpleAccent), // PurpleAccent close button
          ),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final task = Task(
                title: _title,
                description: _description,
                date: _date,
                time: _time,
                category: widget.category,
              );
              widget.onAdd(task);
              Navigator.of(context).pop();
            }
          },
          child: const Text(
            'Add',
            style: TextStyle(
                color: Colors.purpleAccent), // PurpleAccent add button
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null && picked != _time) {
      setState(() {
        _time = picked;
      });
    }
  }
}

// deatils
class DetailsScreen extends StatelessWidget {
  final Task task;

  const DetailsScreen({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(task.title, style: const TextStyle(color: Colors.greenAccent)),
      ),
      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description: ${task.description}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              'Date: ${task.date.day}/${task.date.month}/${task.date.year}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              'Time: ${task.time.hour}:${task.time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
