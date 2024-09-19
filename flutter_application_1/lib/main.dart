import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase core
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 207, 6, 238)),
        useMaterial3: true,
      ),
      home: const TodaApp(),
    );
  }
}

class TodaApp extends StatefulWidget {
  const TodaApp({super.key});

  @override
  State<TodaApp> createState() => _TodaAppState();
}

class _TodaAppState extends State<TodaApp> {
  late TextEditingController _titleController;
  late TextEditingController _detailController;
  final CollectionReference tasks =
      FirebaseFirestore.instance.collection('tasks');

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _detailController = TextEditingController();
  }

  // ฟังก์ชันสร้างรายการใหม่
  Future<void> addTodoHandle(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("add"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), labelText: "name"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _detailController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), labelText: "details"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await tasks.add({
                  'name': _titleController.text,
                  'note': _detailController.text,
                  'status': false, // ค่าเริ่มต้นเป็น false (ยังไม่เสร็จ)
                });
                _titleController.clear();
                _detailController.clear();
                Navigator.pop(context);
              },
              child: const Text("save"),
            )
          ],
        );
      },
    );
  }

  // ฟังก์ชันแก้ไขข้อมูล
  Future<void> editTodoHandle(BuildContext context, String id,
      String currentName, String currentNote, bool currentStatus) async {
    _titleController.text = currentName;
    _detailController.text = currentNote;
    bool _isChecked = currentStatus; // สร้างตัวแปรเพื่อเก็บสถานะ

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("edit"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), labelText: "name"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _detailController,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), labelText: "details"),
                  ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    title: const Text("end"),
                    value: _isChecked,
                    onChanged: (bool? newValue) {
                      setState(() {
                        _isChecked = newValue!; // อัพเดตสถานะ
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await tasks.doc(id).update({
                      'name': _titleController.text,
                      'note': _detailController.text,
                      'status': _isChecked, // อัพเดตสถานะ
                    });
                    _titleController.clear();
                    _detailController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text("save"),
                )
              ],
            );
          },
        );
      },
    );
  }

  // ฟังก์ชันลบรายการ
  Future<void> deleteTodoHandle(String id) async {
    await tasks.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("amonrat"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder(
        stream: tasks.snapshots(), // ดึงข้อมูลจาก Firestore แบบเรียลไทม์
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return ListTile(
                title: Text(doc['name']),
                subtitle: Text(doc['note']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit,
                          color: Color.fromARGB(255, 158, 158, 158)),
                      onPressed: () {
                        editTodoHandle(
                          context,
                          doc.id,
                          doc['name'],
                          doc['note'],
                          doc['status'],
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete,
                          color: Color.fromARGB(255, 243, 6, 6)),
                      onPressed: () {
                        deleteTodoHandle(doc.id);
                      },
                    ),
                  ],
                ),
                leading: Checkbox(
                  value: doc['status'],
                  onChanged: (bool? value) {
                    tasks.doc(doc.id).update({'status': value});
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          addTodoHandle(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
