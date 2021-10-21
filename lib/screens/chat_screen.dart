import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chatapp/utils/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

File? _image;
String _uploadedFileURL = "";
String url = "";

final _firestore = FirebaseFirestore.instance;
User? loggedInUser;

class ChatScreen extends StatefulWidget {
  static String id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  // User? loggedInUser;
  String messageText = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() {
    final user = _auth.currentUser;
    try {
      if (user != null) {
        loggedInUser = user;
        //String? s=user.email;
        print(loggedInUser!.email);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<XFile?> chooseFile() async {
    await ImagePicker().pickImage(source: ImageSource.gallery).then((image) {
      setState(() {
        _image = File(image!.path);
      });
    });
    uploadFile();
  }

  Future uploadFile() async {
    String filename = Uuid().v1();
    var storageReference =
        FirebaseStorage.instance.ref().child("$filename.jpg");
    var uploadTask = await storageReference.putFile(_image!);
    print('File Uploaded');
    await storageReference.getDownloadURL().then((fileURL) {
      setState(() {
        _uploadedFileURL = fileURL;
        print(_uploadedFileURL);
      });
    });
    Map<String, dynamic> chatMessageMap = {
      'sender': _auth.currentUser!.email,
      'text': _uploadedFileURL,
      'time': DateTime.now().millisecondsSinceEpoch,
      'isImg': true,
    };
    await FirebaseFirestore.instance.collection('messages').add(chatMessageMap);
  }
//to get message as snapshot of data
  // void getMessages() async {
  //   final messages = await _firestore.collection('messages').get();
  //   for (var message in messages.docs) {
  //     print(message.data());
  //   }
  // }
//to get message data
  // void messagesStream() async {
  //   await for (var snapshot in _firestore.collection('messages').snapshots()) {
  //     for (var message in snapshot.docs) {
  //       print(message.data());
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          // IconButton(
          //     icon: Icon(Icons.close),
          //     onPressed: () {
          //       //Implement logout functionality
          //     }),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: TextButton(
                child: Text('logout'),
                onPressed: () {
                  _auth.signOut();
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  primary: Colors.white,
                ),
              ),
            ),
          ),
          // TextButton(
          //   child: Text('get messages'),
          //   onPressed: () {
          //     messagesStream();
          //   },
          // )
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      messageTextController.clear();
                      //message + useremail
                      _firestore.collection('messages').add({
                        'text': messageText,
                        'sender': loggedInUser!.email,
                        'time': DateTime.now().millisecondsSinceEpoch,
                        'isImg': false,
                      });
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      chooseFile();
                    },
                    child: Text('choose image'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessagesStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').orderBy('time').snapshots(),
      builder: (context, snapshot) {
        // List<Text> messageWidgets = [];
        List<MessageBubble> messageWidgets = [];
        if (snapshot.hasData) {
          //to fetch and set the message that it always appears at bottom(reversed function)
          final messages = snapshot.data!.docs.reversed;
          // List<Text> messageWidgets = [];
          for (var message in messages) {
            final messageText = message.get('text');
            final messageSender = message.get('sender');
            final isimage = message.get('isImg');

            final currentUser = loggedInUser!.email;

            if (currentUser == messageSender) {
              //the message from logged user
            }

            final messageWidget = MessageBubble(
              sender: messageSender,
              text: messageText,
              isloggedUser: currentUser == messageSender,
              isimg: isimage,
            );
            messageWidgets.add(messageWidget);
          }
          // return Column(
          //   children: messageWidgets,
          // );
        } else {
          return Center(child: Text('No messages'));
        }
        return Expanded(
          child: ListView(
            reverse: true, //to make list view point always at bottom
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            children: messageWidgets,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble(
      {required this.sender,
      required this.text,
      required this.isloggedUser,
      required this.isimg});
  final String sender;
  final String text;
  final bool isloggedUser;
  final bool isimg;
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(10.0),
        child: isimg
            ? Column(
                crossAxisAlignment: isloggedUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    sender,
                    style: TextStyle(
                      fontSize: 11.0,
                      color: Colors.black54,
                    ),
                  ),
                  Container(
                    child: Image.network(
                      text,
                    ),
                    height: 200.0,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: isloggedUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    sender,
                    style: TextStyle(
                      fontSize: 11.0,
                      color: Colors.black54,
                    ),
                  ),
                  Material(
                    borderRadius: isloggedUser
                        ? BorderRadius.only(
                            topLeft: Radius.circular(30.0),
                            bottomLeft: Radius.circular(30.0),
                            bottomRight: Radius.circular(30.0))
                        : BorderRadius.only(
                            bottomLeft: Radius.circular(30.0),
                            bottomRight: Radius.circular(30.0),
                            topRight: Radius.circular(30.0)),
                    elevation: 5.0,
                    color: isloggedUser ? Colors.lightBlueAccent : Colors.white,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 10.0),
                      child: Text(text,
                          style: TextStyle(
                            color: isloggedUser ? Colors.white : Colors.black,
                            fontSize: 15.0,
                          )),
                    ),
                  ),
                ],
              ));
  }
}
