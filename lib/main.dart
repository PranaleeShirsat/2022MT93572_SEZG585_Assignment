import 'dart:async';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final keyApplicationId = 'HprSCxgDMITe6wkC5I9fA5ERnQDiMJqG7MYr1dkq';
  final keyClientKey = '0osWHgmaWbPSXHFntF4mOjfQY18HqCWh0urVyPmp';
  final keyParseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(keyApplicationId, keyParseServerUrl,
      clientKey: keyClientKey, debug: true);

  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  HomePage createState() => HomePage();
}

class ViewTask extends StatefulWidget {
  @override
  String title;
  String description;
  bool status;
  String id;
  ViewTask ({ Key? key, required this.title, required this.description, required this.status, required this.id }): super(key: key);
  ViewTaskDetails createState() => ViewTaskDetails();
}

class AddTask extends StatefulWidget {
  @override
  AddNewTask createState() => AddNewTask();
}

class HomePage extends State<Home> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Task Manager"),
        backgroundColor: Colors.teal[200],
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
              child: FutureBuilder<List<ParseObject>>(
                  future: getTaskDetails(),
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.none:
                      case ConnectionState.waiting:
                        return Center(
                          child: Container(
                              width: 100,
                              height: 100,
                              child: CircularProgressIndicator()),
                        );
                        default:
                        if (snapshot.hasError) {
                          return Center(
                            child: Text("Error..."),
                          );
                        }
                        if (!snapshot.hasData) {
                          return Center(
                            child: Text("No Data..."),
                          );
                        } else {
                          return ListView.builder(
                              padding: EdgeInsets.only(top: 10.0),
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, index) {
                                final taskDetails = snapshot.data![index];
                                final taskTitle = taskDetails.get<String>('Title')!;
                                final taskDesc = taskDetails.get<String>('Description')!;
                                final taskStatus =  taskDetails.get<bool>('Done')!;
                                final id = taskDetails.get<String>('objectId')!;
                                return ListTile(

                                  title: Text(taskTitle),
                                  onTap:(){
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => ViewTask( title: taskTitle, description: taskDesc, status: taskStatus, id: id)),
                                    ).then((_){
                                      setState(() {});
                                    });
                                  },
                                  leading: CircleAvatar(
                                    child: Icon(
                                        taskStatus ? Icons.check : Icons.error),
                                    backgroundColor:
                                    taskStatus ? Colors.green : Colors.teal[200],
                                    foregroundColor: Colors.white,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.teal[200],
                                        ),
                                        onPressed: () async {
                                          await deleteTask(taskDetails.objectId!);
                                          setState(() {
                                            final snackBar = SnackBar(
                                              content: Text("Task deleted!"),
                                              duration: Duration(seconds: 2),
                                            );
                                            ScaffoldMessenger.of(context)
                                              ..removeCurrentSnackBar()
                                              ..showSnackBar(snackBar);
                                          });
                                        },
                                      )
                                    ],
                                  ),
                                );
                              });
                        }
                    }
                  })
          ),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  onPrimary: Colors.white,
                  primary: Colors.teal[200]
              ),
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => AddTask()),
                ).then((_){
                  setState(() {});
                });
              },
              child: Text("ADD NEW TASK")
          ),
        ],
      ),
    );
  }

  Future<List<ParseObject>> getTaskDetails() async {
    QueryBuilder<ParseObject> getQuery =
    QueryBuilder<ParseObject>(ParseObject('Task'));
    final ParseResponse apiResponse = await getQuery.query();

    if (apiResponse.success && apiResponse.results != null) {
      return apiResponse.results as List<ParseObject>;
    } else {
      return [];
    }
  }

  Future<void> deleteTask(String id) async {
    var task = ParseObject('Task')..objectId = id;
    await task.delete();
  }
}

class ViewTaskDetails extends State<ViewTask> {
  final taskTitleController = TextEditingController();
  final taskDescController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    setState(() {
      taskTitleController.text = widget.title;
      taskDescController.text = widget.description;
    });
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Manager'),
        backgroundColor: Colors.teal[200],
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
              child: TextField(
            controller: taskTitleController,
            decoration: InputDecoration(
              labelText: 'Title',
              labelStyle: TextStyle(color: Colors.teal),
            ),
          )
          ),
          Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: TextField(
                controller: taskDescController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.teal),
            ),
          )),
          
          Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: TextField(
            decoration: InputDecoration(
              labelText: 'Status: '+ (widget.status ? 'Done' : 'Pending'),
              labelStyle: TextStyle(color: Colors.teal),
              enabled: false
            ),
          )),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget> [
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    onPrimary: Colors.white,
                    primary: Colors.teal[200],
                  ),
                  onPressed: (){addTask(widget.id);},
                  child: Text("Update")
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    onPrimary: Colors.white,
                    primary: Colors.teal[200],
                  ),
                  onPressed: (){updateTaskStatus(widget.id, !widget.status);},
                  child: Text(widget.status ? "Mark As Undone" : "Mark As Done")
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> addTask(String id) async {
    if (taskTitleController.text.trim().isEmpty || taskDescController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Empty details"),
        duration: Duration(seconds: 2),
      ));
      return;
    }

    if(widget.title == taskTitleController.text.trim() && widget.description ==taskDescController.text.trim()){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("No Changes Made"),
        duration: Duration(seconds: 2),
      ));
      return;
    }
    await updateTaskDetails(id, taskTitleController.text, taskDescController.text);
    setState(() {
      taskTitleController.clear();
      taskDescController.clear();
    });
  }

  Future<void> updateTaskDetails(String id, String title, String description) async {
    var task = ParseObject('Task')
      ..objectId = id
      ..set('Title', title)
      ..set('Description',description);
    await task.save();
    setState(() {
      Navigator.pop(context);
    });
  }

  Future<void> updateTaskStatus(String id, bool done) async {
    var task = ParseObject('Task')
      ..objectId = id
      ..set('Done', done);
    await task.save();
    setState(() {
      Navigator.pop(context);
    });
  }
}

class AddNewTask extends State<AddTask> {
  final taskTitleController = TextEditingController();
  final taskDescController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Task Manager'),
        backgroundColor: Colors.teal[200],
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: TextField(
            controller: taskTitleController,
            decoration: InputDecoration(
              labelText: 'Title',
              labelStyle: TextStyle(color: Colors.teal),
            ),
          )),
          Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: TextField(
                controller: taskDescController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.teal),
                ),
              )
          ),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                onPrimary: Colors.white,
                primary: Colors.teal[200],
              ),
              onPressed: addTask,
              child: Text("ADD")
          )
        ],
      ),
    );
  }

  void addTask() async {
    if (taskTitleController.text.trim().isEmpty || taskDescController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Empty title"),
        duration: Duration(seconds: 2),
      ));
      return;
    }
    await saveTask(taskTitleController.text, taskDescController.text);
    setState(() {
      taskTitleController.clear();
      taskDescController.clear();
      Navigator.pop(context);
    });
  }

  Future<void> saveTask(String title, String description) async {
    final task = ParseObject('Task')..set('Title', title)..set('Description', description)..set('Done', false);
    await task.save();
  }
}