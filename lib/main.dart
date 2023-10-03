import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:uuid/uuid.dart';

import 'repository/mock_message_repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chat Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Chat Demo Page'),
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
  final MockMessageRepository _repository = MockMessageRepository();
  final List<types.Message> _messages = [];
  final _user = const types.User(
      id: '82091008-a484-4a89-ae75-a22bf8d6f3ac', firstName: '我');

  final String roomId = "test_room_id";
  Future<void> initMessages() async {
    await _repository.init(); //初始化
    List<types.Message> messages =
        await _repository.fetchOlderMessage(roomId, 20);
    _messages.addAll(messages);
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {});
    });
  }

  Future<void> onEndReached() async {
    List<types.Message> messages =
        await _repository.fetchOlderMessage(roomId, 1, _messages.last);
    setState(() {
      _messages.addAll(messages);
    });
  }

  @override
  void initState() {
    initMessages();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Chat(
        messages: _messages,
        onSendPressed: (types.PartialText message) {
          setState(() {
            _messages.insert(
                0,
                types.TextMessage(
                  author: _user,
                  id: Uuid().v4(),
                  text: message.text,
                ));
          });
        },
        onEndReached: onEndReached,
        user: _user,
        showUserNames: true,
        showUserAvatars: true,
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
