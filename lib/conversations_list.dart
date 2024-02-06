import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import 'package:intl/intl.dart';

class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({Key? key}) : super(key: key);

  @override
  State<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String getInitials(String name) => name.isNotEmpty
      ? name.trim().split(RegExp(' +')).map((s) => s[0]).take(2).join()
      : '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Поиск',
                hintStyle: const TextStyle(color: Color.fromRGBO(157, 183, 203, 1)),
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
          if (snapshot.hasError || !snapshot.hasData) {
            return const Text('Произошла ошибка');
          }

          final conversations = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = data['chatstitle']?.toLowerCase() ?? '';
            return title.contains(_searchController.text.toLowerCase());
          }).toList();

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final data = conversations[index].data() as Map<String, dynamic>;
              final chatTitle = data['chatstitle'] ?? 'Нет имени';
              final initials = getInitials(chatTitle);
              final lastMessageData = data['lastMessage'] ?? {};
              final lastMessageText = lastMessageData['senderId'] == 'mainuser' ? 'Вы: ${lastMessageData['text']}' : lastMessageData['text'];
              final timestamp = lastMessageData['timestamp'] as Timestamp?;
              final formattedDate = timestamp != null ? DateFormat('dd.MM.yyyy').format(timestamp.toDate()) : '';

              return ListTile(
                leading: CircleAvatar(backgroundColor: Colors.green, child: Text(initials, style: const TextStyle(color: Colors.white))),
                title: Text(chatTitle),
                subtitle: Text(lastMessageText),
                trailing: Text(formattedDate),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      conversationId: conversations[index].id,
                      bubbleColor: Colors.green,
                      updateLastMessage: updateLastMessage,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void updateLastMessage(String conversationId, String lastMessage) async {
    try {
      await _firestore.collection('conversations').doc(conversationId).update({
        'lastMessage.text': lastMessage,
        'lastMessage.timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Ошибка при обновлении последнего сообщения: $e');
    }
  }
}
