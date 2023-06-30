# flutter_chat_app_example

這個範例使用Flyer Chat的Chat UI來快速建立一個Chat App，並運用GetX為狀態管理工具

資料來源：[Flyer Chat官方文件](https://docs.flyer.chat/flutter/chat-ui/)
##Basic Usage
1. 從pub.dev安裝所需要的package，flutter_chat_ui 1.6.8

    ```
    flutter pub add flutter_chat_ui
    ```

   或

    ```yaml
    dependencies:
    flutter_chat_ui: ^1.6.8
   ```


2. flutter_chat_ui 提供的Chat Widget，可以用來畫聊天室的UI，
   包含聊天室歷史訊息與訊息輸入框，他提供了很多客製化的選項，基本使用需要以下三個必填參數。

      ```
      Chat(  
        messages: [], //歷史訊息
        user: User(id: '82091008-a484-4a89-ae75-a22bf8d6f3ac'), //自己的資料，
        onSendPressed: (PartialText message) {
          //點擊發送按鈕執行函數（方法）
        }, 
      )
      ```
3. flutter_chat_ui支援的訊息類型很多，除了文字、影音訊息外，還支援SystemMessage以及檔案與客製化訊息。
   它們都是繼承自共同的`Message`類。要使用這些類別需要引入另一個package，`flutter_chat_types`，這個package。
   包含flutter_chat_ui所需要用到的類別，除了訊息類型也包含User、Room、PreviewData類型。

   ```
    flutter pub add flutter_chat_types
    ```

   或

    ```yaml
    dependencies:
    flutter_chat_ui: ^3.6.1
   ```

      ```dart
       //message.dart中列出的訊息種類
       switch (type) {
         case MessageType.audio:
           return AudioMessage.fromJson(json);
         case MessageType.custom:
           return CustomMessage.fromJson(json);
         case MessageType.file:
           return FileMessage.fromJson(json);
         case MessageType.image:
           return ImageMessage.fromJson(json);
         case MessageType.system:
           return SystemMessage.fromJson(json);
         case MessageType.text:
           return TextMessage.fromJson(json);
         case MessageType.unsupported:
           return UnsupportedMessage.fromJson(json);
         case MessageType.video:
           return VideoMessage.fromJson(json);
       }
      ```
   User類，除了user id 還可以設定firstName、imageUrl、role 等變量。
   從這些類的設計，可以啟發如何設計Chat App的各種資料結構。


4. 官方範例-basic

   以下範例，提供很基礎的Chat使用方式，message列表排序方式是index 0為最新訊息，
   ```dart
   import 'dart:convert';
   import 'dart:math';
   
   import 'package:flutter/material.dart';
   import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
   import 'package:flutter_chat_ui/flutter_chat_ui.dart';
   
   // For the testing purposes, you should probably use https://pub.dev/packages/uuid.
   String randomString() {
     final random = Random.secure();
     final values = List<int>.generate(16, (i) => random.nextInt(255));
     return base64UrlEncode(values);
   }
   
   void main() {
     runApp(const MyApp());
   }
   
   class MyApp extends StatelessWidget {
     const MyApp({super.key});
   
     @override
     Widget build(BuildContext context) => const MaterialApp(
           home: MyHomePage(),
         );
   }
   
   class MyHomePage extends StatefulWidget {
     const MyHomePage({super.key});
   
     @override
     State<MyHomePage> createState() => _MyHomePageState();
   }
   
   class _MyHomePageState extends State<MyHomePage> {
     final List<types.Message> _messages = [];//歷史訊息列表
     final _user = const types.User(id: '82091008-a484-4a89-ae75-a22bf8d6f3ac');//user 自己
   
     @override
     Widget build(BuildContext context) => Scaffold(
           body: Chat(
             messages: _messages,
             onSendPressed: _handleSendPressed,
             user: _user,
           ),
         );
   
     void _addMessage(types.Message message) {
       setState(() {
         //新增新訊息時，將資料插入到index 0的位置，並且setState刷新UI
         _messages.insert(0, message);
       });
     }
   
     //當點擊send按鈕時，會從Chat Widget中觸發此函數並將訊息資料傳出。
     //根據資料內容可以創建新的`TextMessage`並加入訊息歷史列表中
     void _handleSendPressed(types.PartialText message) {
       final textMessage = types.TextMessage(
         author: _user,//自己
         createdAt: DateTime.now().millisecondsSinceEpoch,//訊息建立時間，我個人偏向使用伺服器的時間
         id: randomString(),//每一個message要有獨立的id
         text: message.text,//文字訊息
       );
   
       _addMessage(textMessage);
     }
   }
   ```

##進階使用-分頁、Pagination


##使用GetX進行狀態管理



##聊天室列表