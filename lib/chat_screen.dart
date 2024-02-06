import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final Color bubbleColor;
  final void Function(String conversationId, String lastMessage)
      updateLastMessage;

  const ChatScreen({
    Key? key,
    required this.conversationId,
    required this.bubbleColor,
    required this.updateLastMessage,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final String mainUserId = 'mainuser';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();

  String getInitials(String name) => name.isNotEmpty
      ? name.trim().split(RegExp(' +')).map((s) => s[0]).take(2).join()
      : '';

  final FocusNode _messageFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _messageFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _messageFocusNode.dispose();
    super.dispose();
  }

  Future<void> sendMessage(String messageText) async {
    if (messageText.trim().isEmpty) {
      if (kDebugMode) {
        print('Сообщение пустое');
      }
      return;
    }

    await _firestore
        .collection('conversations')
        .doc(widget.conversationId)
        .update({
      'lastMessage': {
        'senderId': 'mainuser',
        'text': messageText,
        'timestamp': FieldValue.serverTimestamp(),
      },
    }).catchError((e) {
      if (kDebugMode) {
        print('Ошибка при обновлении последнего сообщения: $e');
      }
    });

    DocumentReference messageDoc = _firestore
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('messages')
        .doc();

    Map<String, dynamic> messageData = {
      'senderId': 'mainuser',
      'text': messageText,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await messageDoc.set(messageData).catchError((e) {
      if (kDebugMode) {
        print('Ошибка при отправке сообщения: $e');
      }
    });
    widget.updateLastMessage(widget.conversationId, messageText);
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      sendMessage(_messageController.text.trim());
      _messageController.clear();
    }
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return '';
    }
    return DateFormat('HH:mm').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection('conversations')
              .doc(widget.conversationId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.data() == null) {
              return const Text('Нет данных');
            }

            var data = snapshot.data!.data() as Map<String, dynamic>;
            String initials = getInitials(data['chatstitle'] ?? '');
            Color userColor = Colors.green;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: userColor,
                child:
                    Text(initials, style: const TextStyle(color: Colors.white)),
              ),
              title: Text(data['chatstitle'] ?? 'Нет имени'),
              subtitle: Text(data['isActive'] ? 'в сети' : 'не в сети'),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('conversations')
                  .doc(widget.conversationId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<DocumentSnapshot> docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> data =
                        docs[index].data() as Map<String, dynamic>;

                    bool isMainUser = data['senderId'] == mainUserId;
                    String formattedTime = '';
                    String formattedDate = '';
                    DateTime?
                        date; 
                    if (data['timestamp'] != null) {
                      Timestamp timestamp = data['timestamp'] as Timestamp;
                      date = timestamp
                          .toDate(); 
                      formattedTime = DateFormat('HH:mm').format(date);
                      if (DateTime.now()
                              .isBefore(date.add(const Duration(days: 1))) &&
                          DateTime.now().isAfter(
                              date.subtract(const Duration(days: 1)))) {
                        formattedDate = 'Сегодня';
                      } else {
                        formattedDate = DateFormat('dd.MM.yyyy').format(date);
                      }
                    } else {
                      formattedTime = 'Время неизвестно';
                      formattedDate = 'Дата неизвестна';
                    }

                    bool isDividerNeeded = false;
                    if (index > 0 && date != null) {
                      Map<String, dynamic> prevData =
                          docs[index - 1].data() as Map<String, dynamic>;
                      Timestamp? prevTimestamp = prevData['timestamp'];
                      if (prevTimestamp != null) {
                        DateTime prevDate = prevTimestamp.toDate();
                        if (DateFormat('dd.MM.yyyy').format(date) !=
                            DateFormat('dd.MM.yyyy').format(prevDate)) {
                          isDividerNeeded = true;
                        }
                      }
                    }

                    return Column(
                      children: [
                        if (isDividerNeeded)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ],
                          ),
                        Row(
                          mainAxisAlignment: isMainUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 10,
                              ),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isMainUser
                                    ? Colors.green
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isMainUser
                                        ? ' ${data['text']}'
                                        : data['text'],
                                    style: TextStyle(
                                      color: isMainUser
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        formattedTime,
                                        style: const TextStyle(
                                          color:
                                              Color.fromARGB(221, 56, 55, 55),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Color.fromARGB(221, 56, 55, 55),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              height: 70.0,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 4,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    iconSize: 25.0,
                    color: Theme.of(context).primaryColor,
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      focusNode: _messageFocusNode,
                      controller: _messageController,
                      decoration: const InputDecoration.collapsed(
                        hintText: 'Сообщение',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  _messageFocusNode.hasFocus
                      ? IconButton(
                          icon: const Icon(Icons.send),
                          iconSize: 25.0,
                          color: Theme.of(context).primaryColor,
                          onPressed: _sendMessage,
                        )
                      : IconButton(
                          icon: const Icon(Icons.mic),
                          iconSize: 25.0,
                          color: Theme.of(context).primaryColor,
                          onPressed: () {},
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
