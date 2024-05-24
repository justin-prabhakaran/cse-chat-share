import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:aaa_chat_share/features/chat/data/models/chat_model.dart';

abstract class ChatRemoteDataSource {
  void sendChat(String message, String userName, DateTime time);
  Stream<ChatModel> listen();
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final StreamController<ChatModel> _streamController =
      StreamController<ChatModel>.broadcast();
  late final io.Socket _socket;

  ChatRemoteDataSourceImpl() {
    _socket = io.io(
      'http://localhost:1234',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    _socket.on('connect', (_) {
      print('Connected to socket server');
    });

    _socket.on('message', (data) {
      print(data);
      if (data is Map<String, dynamic>) {
        ChatModel chat = ChatModel.fromMap(data);
        _streamController.add(chat);
      } else {
        print('Invalid data format: $data');
      }
    });

    _socket.on('disconnect', (_) {
      print('Disconnected from socket server');
    });

    // Ensure the socket attempts to connect
    if (!_socket.connected) {
      _socket.connect();
    }
  }

  @override
  Stream<ChatModel> listen() {
    return _streamController.stream;
  }

  @override
  void sendChat(String message, String userName, DateTime time) {
    Map<String, dynamic> data = {
      'message': message,
      'user_name': userName,
      'time': time.millisecondsSinceEpoch
    };
    var jsondata = jsonEncode(data);
    print(jsondata);
    _socket.emit('message', jsondata);
  }

  // Remember to close the stream controller when done
  void dispose() {
    _streamController.close();
    _socket.dispose();
  }
}
