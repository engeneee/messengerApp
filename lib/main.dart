import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:messenger_app/conversations_list.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ConversationsListScreen(),
    );
  }
}
