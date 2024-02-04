import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ConversationsListScreenState createState() =>
      _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Чаты',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Your action here
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('conversations').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Произошла ошибка'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Нет доступных чатов'));
          }

          return ListView.separated(
            separatorBuilder: (context, index) => const Divider(),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var conversation = snapshot.data!.docs[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  child: Text(
                    conversation['chatstitle'].toString().substring(0, 2),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                title: Text(conversation['chatstitle'] ?? 'Нет имени'),
                subtitle: Text(
                  conversation['lastMessage']['text'] ?? 'Нет сообщения',
                ),
                trailing: Text(
                  (conversation['lastMessage']['timestamp'] as Timestamp)
                      .toDate()
                      .toString(),
                ),
                onTap: () {
                },
              );
            },
          );
        },
      ),
    );
  }
}
