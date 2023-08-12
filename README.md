# Flutter如何透過Flyer Chat實作聊天室功能？

應用程式中聊天室功能很常見，自行從無到有建立整個聊天室邏輯需要很多時間，幸好Pub.dev上可以找到別人寫好的Chat UI 範本參考。

本次範例使用Flyer Chat的Chat UI來快速建立一個Chat聊天室頁面。一起來看看這個Package怎麼使用吧～

資料來源：[Flyer Chat官方文件](https://docs.flyer.chat/flutter/chat-ui/)

## Basic Usage
基本使用方式


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
   包含聊天室歷史訊息與訊息輸入框，它提供了很多客製化的選項，基本使用需要以下三個必填參數`messages`、`user`、`onSendPressed`。

      ```dart
      Chat(  
        messages: [], //歷史訊息
        user: User(id: '82091008-a484-4a89-ae75-a22bf8d6f3ac'), //自己的資料，
        onSendPressed: (PartialText message) {
          //點擊發送按鈕執行函數（方法）
        }, 
      )
      ```
3. flutter_chat_ui支援的訊息類型很多，除了文字、影音訊息外，還支援SystemMessage以及檔案與客製化訊息。從這些類的設計，也許可以啟發如何設計Chat App的各種資料。要使用這些類別需要引入另一個package——`flutter_chat_types`
   
   這個package，
   包含flutter_chat_ui所需要用到的類別，除了訊息類型也包含User、Room、PreviewData類型。

   ```
    flutter pub add flutter_chat_types
    ```

   或

    ```yaml
    dependencies:
    flutter_chat_ui: ^3.6.1
   ```
   
   訊息相關的類，它們都是繼承自共同的`Message`類

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
   。


4. 官方範例-basic

   以下範例，提供很基礎的Chat使用方式，message列表排序方式是index 0為最新訊息。
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

## 進階使用-分頁、Pagination
做聊天室的時候，如果歷史資料量非常龐大，每次開啟聊天室時將所有的聊天歷史資料從雲端下載下來，，會造成資料讀取時間拉長，也會對伺服器造成很大負擔。
* 通常會顯示前幾十筆資料，並在使用者滾動聊天室到底部時，再將雲端資料逐步下載，稱為pagination
* Chat Widget提供三個參數控制pagination，`onEndReached`, `onEndReachedThreshold` 和 `isLastPage`
* pagination提取資料的方式，依據後端設計不同，採取的方式也不同。在一個特定排序的資料表中，可以固定每20筆資料分為一頁。另一種方式是以document id作為起始點向後擷取20筆資料，或許還有其它的方式。

在網路上有看到pagination、infinite scroll、show more設計方式，三種的操作流程不同，基本核心概念還是分批次載入資料。

以下為官方提供的簡易範例
```dart
// ...
import 'package:http/http.dart' as http;

class _MyHomePageState extends State<MyHomePage> {
  //當前總共載入的頁數
  int _page = 0;
  // ...
  @override
  void initState() {
    super.initState();
    //在開啟聊天室畫面的時候，開始載入第一頁資料
    _handleEndReached();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: Chat(
        // ...
        onEndReached: _handleEndReached,//滾動到底部時，獲取更新的資料
      ),
    );
  
  //從雲端獲取資料
  //不同的後端或雲端資料庫所提供的API或許不同，這個範例採取的方式是用page區分頁數，每次固定提取20筆資料
  Future<void> _handleEndReached() async {
    final uri = Uri.parse(
      'https://api.instantwebtools.net/v1/passenger?page=$_page&size=20',
    );
    final response = await http.get(uri);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'] as List<dynamic>;
    //將得到資料序列化，轉為class
    final messages = data
        .map(
          (e) => types.TextMessage(
            author: _user,
            id: e['_id'] as String,
            text: e['name'] as String,
          ),
        )
        .toList();
    setState(() {
      //將新舊資料合併，並更新訊息列表以及頁面數
      _messages = [..._messages, ...messages];
      _page = _page + 1;
    });
  }
}
```

### Mock message repository
由於我暫時沒有適合的後端，所以做一個Mock Repository。
我選擇的獲取資料方式，是以某一個文件為起始點，繼續向後擷取數筆資料。

定義抽象類別`MessageRepository`這裡面提供兩個方法`fetchOlderMessage`、`fetchOlderMessage`，
用來獲取更新或更舊的資料

```dart
// ../lib/repository/message_repository.dart

abstract class MessageRepository {
  //

  Future<List<types.Message>> fetchOlderMessage(String roomId, int limit,
      [types.Message? startMessage]);

  Future<List<types.Message>> fetchNewerMessage(String roomId, int limit,
      [types.Message? startMessage]);
}

```

#### 實作Mock Repository
Mock Repository用 `List<types.Message> remoteMessages = [];` 模擬雲端的資料，
除了實作`fetchOlderMessage`，`fetchNewerMessage`，從 `remoteMessages`中取得數據並回傳外。
也額外實現一個`init`方法，在初始化Mock Repository時將從`assets/messages.json`將模擬資料導入。


```dart
//...

class MockMessageRepository implements MessageRepository {
  RxBool isLoading = false.obs;
  List<types.Message> remoteMessages = [];

  init() async {
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
```

```yaml
  assets:
    - assets/messages.json
```

### 應用MockMessageRepository



建造MockMessageRepository實例，以及宣告List陣列
```dart
  final MockMessageRepository _repository = MockMessageRepository();
  final List<types.Message> _messages = [];
```


初始化資料以及獲取前20筆訊息，存入List

```dart
Future<void> initMessages() async {
    await _repository.init(); //初始化
    List<types.Message> messages =
        await _repository.fetchOlderMessage(roomId, 20);
    _messages.addAll(messages);
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {});
    });
  }

```

畫面滾動到頂部時，繼續載入資料，並且更新List

```dart
Future<void> onEndReached() async {
    List<types.Message> messages =
        await _repository.fetchOlderMessage(roomId, 1, _messages.last);
    setState(() {
      _messages.addAll(messages);
    });
  }

```


完整程式碼：

```dart

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

```

## 總結
透過上面的範例，相信可以理解聊天室的基本邏輯是什麼，以及這個Package的基本使用方式。

這個Package幫助你建立了各種訊息的UI顯示方式以及常見的功能，即使沒有要使用它，它也會是個不錯的參考資料。