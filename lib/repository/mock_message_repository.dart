import 'dart:convert';
import 'dart:math';

import 'package:flutter_chat_types/src/message.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'message_repository.dart';

class MockMessageRepository implements MessageRepository {
  RxBool isLoading = false.obs;
  List<types.Message> remoteMessages = [];

  Future<void> init() async {
    isLoading.value = true;
    remoteMessages = await _loadMessages();
    List<types.Message> messages = _generateMessages();
    remoteMessages.addAll(messages);
    isLoading.value = false;
  }

  @override
  Future<List<types.Message>> fetchNewerMessage(String roomId, int limit,
      [Message? startMessage]) async {
    if (startMessage == null) {
      return remoteMessages.take(limit).toList();
    } else {
      //以下模擬提取訊息
      List<types.Message> messages = remoteMessages.reversed
          .skipWhile((value) => value.id != startMessage.id)
          .take(limit + 1)
          .toList()
          .reversed
          .toList();
      return messages.isEmpty ? [] : messages.skip(1).toList();
    }
  }

  @override
  Future<List<Message>> fetchOlderMessage(String roomId, int limit,
      [Message? startMessage]) async {
    if (startMessage == null) {
      return remoteMessages.take(limit).toList();
    } else {
      List<types.Message> messages = remoteMessages.skipWhile((value) {
        final bool b = value.id != startMessage.id;
        return b;
      }).toList();

      messages = messages.take(limit + 1).toList();

      return messages.isEmpty ? [] : messages.skip(1).toList();
    }
  }

  Future<List<types.Message>> _loadMessages() async {
    final response = await rootBundle.loadString('assets/messages.json');
    final List<types.Message> messages = (jsonDecode(response) as List)
        .map((e) => types.Message.fromJson(e as Map<String, dynamic>))
        .toList();
    return messages;
  }

  List<types.TextMessage> _generateMessages() {
    const start = 1655624460000;
    List<types.TextMessage> result = [];
    for (int i = 1; i < 100; i++) {
      types.TextMessage msg = _generateMessage(start - i * 1000 * 60 * 60);
      result.add(msg);
    }
    return result;
  }

  types.TextMessage _generateMessage(int? createAt) {
    Map<String, String> map = authors[Random().nextInt(authors.length)];
    String textMessage = textSample[Random().nextInt(textSample.length)];

    return types.TextMessage(
      id: "${messageUUID.first}-$createAt",
      text: textMessage,
      author: types.User(
        id: map['id'] as String,
        firstName: map['firstName'] as String,
      ),
      createdAt: createAt,
    );
  }
}

//以下為一些假設資料
final ownUser = const types.User(
  id: '82091008-a484-4a89-ae75-a22bf8d6f3ac',
  firstName: "Ignacio",
);

List<Map<String, String>> authors = [
  {
    "firstName": "user1",
    "id": "e12452f4-835d-4dbe-ba77-b076e659774d",
    "imageUrl":
        "https://i.pravatar.cc/300?u=e52552f4-835d-4dbe-ba77-b076e659774d",
    "lastName": "Zhang"
  },
  {
    "firstName": "user2",
    "id": "e22552f4-835d-4dbe-ba77-b076e659774d",
    "imageUrl":
        "https://i.pravatar.cc/300?u=e52552f4-835d-4dbe-ba77-b076e659774d",
    "lastName": "King"
  },
  {
    "firstName": "user3",
    "id": "e32552f4-83sd-4dbe-ba77-b076e659774d",
    "imageUrl":
        "https://i.pravatar.cc/300?u=e52552f4-835d-4dbe-ba77-b076e659774d",
    "lastName": "King"
  },
];

List<String> textSample = [
  "你好，範例1",
  "你好，範例2",
  "你好，範例3",
  "你好，範例4",
];

final List<String> messageUUID = [
  "372aab90-c20f-4ee8-91e7-420ce1c2c8a2",
  "39966425-930e-4f5e-8bc5-351f39248505",
  "b2af6ada-ca0f-458e-9977-90c38e47182b",
  "d11114ae-8811-4c9f-8b56-28340d93b7c0",
  "973e17d9-aab8-4ba4-91a8-cdc888d67888",
  "9a117587-1733-4b3b-aa57-d8feef093ce0",
  "95b8c633-198f-47ca-92a6-7945577b1a39",
  "a1ef1a24-412b-46c2-a651-a1887339f897",
  "e761271c-5433-4c31-b751-f44eaae4fccb",
  "68dfb1ef-0eb8-41ab-8d33-82a5ca42c34d",
];
