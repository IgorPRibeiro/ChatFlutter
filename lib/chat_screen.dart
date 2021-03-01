import 'dart:io';
import 'package:async/async.dart';
import 'package:chat/chat_message.dart';
import 'package:chat/text_composer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ChatScrenn extends StatefulWidget {
  @override
  _ChatScrennState createState() => _ChatScrennState();
}

class _ChatScrennState extends State<ChatScrenn> {

  final GoogleSignIn googleSignIn = GoogleSignIn();
  final GlobalKey<ScaffoldState> _scalfoldKey = GlobalKey<ScaffoldState>();

  User _currentUser;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  Future<User> getUSer() async {
    if(_currentUser != null) return _currentUser;
    try {
      final GoogleSignInAccount googleSignInAccount =
        await googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

      final AuthCredential authCredential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken,
      );

      final UserCredential authResult = await FirebaseAuth.instance.signInWithCredential(authCredential);


      final User user = authResult.user;

      return user;
    } catch (erro) {
      return null;
    }
  }

  void _sendMessage({String text, File imgFile}) async {

    final User user = await getUSer();

    if(user == null) {
      _scalfoldKey.currentState.showSnackBar(
        SnackBar(content: Text("Não fooi possivel fazer o login"),backgroundColor: Colors.red,),

      );
    }

    Map<String,dynamic> data = {
      "uid": user.uid,
      "senderName": user.displayName,
      "senderPhotoUrl": user.photoURL,
      "time": Timestamp.now(),
    };

    if(imgFile != null) {
      UploadTask task = FirebaseStorage.instance.ref().child(
        user.uid + DateTime.now().microsecondsSinceEpoch.toString()
      ).putFile(imgFile);
      setState(() {
        _isLoading = true;
      });
      TaskSnapshot taskSnapshot = await task;
      String url = await taskSnapshot.ref.getDownloadURL();
      data['imgUrl'] = url;
      setState(() {

        _isLoading = false;
      });
    }

    if(text != null) data['text'] = text;

    FirebaseFirestore.instance.collection("messages").add(data);


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scalfoldKey,
      appBar: AppBar(
        title: Text(_currentUser != null ? 'Olá, ${_currentUser.displayName}':'Chat App'),
        elevation: 0,
        actions: [
          _currentUser != null ?IconButton(icon: Icon(Icons.exit_to_app), onPressed: (){
            FirebaseAuth.instance.signOut();
            googleSignIn.signOut();
            _scalfoldKey.currentState.showSnackBar(
              SnackBar(content: Text("Você saiu com sucesso"),),

            );
          }) : Container()
        ],
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection("messages").orderBy("time").snapshots(),
                builder: (context,snapshot){
                  switch (snapshot.connectionState){
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    default:
                      List<DocumentSnapshot> documents = snapshot.data.docs.reversed.toList();
                      return ListView.builder(
                          itemCount: documents.length,
                          reverse: true,
                          itemBuilder: (context, index) {
                            return ChatMessage(documents[index].data(),
                              documents[index].data()['uid'] == _currentUser?.uid
                            );
                          }
                      );
                  }
                },
              )),
          _isLoading ? LinearProgressIndicator() :Container(),
          TextComposer(_sendMessage),
        ],
      ),
    );
  }
}
