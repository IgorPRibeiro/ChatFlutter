import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class TextComposer extends StatefulWidget {
  TextComposer(this.sendMessage);

  final Function({String text, File imgFile}) sendMessage;

  @override
  _TextComposerState createState() => _TextComposerState();
}

class _TextComposerState extends State<TextComposer> {
  final TextEditingController _controller = TextEditingController();

  bool isComposing = false;

  void _reset() {
    _controller.clear();
    setState(() {
      isComposing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(icon: Icon(Icons.photo_camera), onPressed: () async {
            PickedFile selectFile = await ImagePicker().getImage(source: ImageSource.gallery);
            final File imgFile = File(selectFile.path);
            if (imgFile == null) return;
            widget.sendMessage(imgFile: imgFile);
          }),
          Expanded(
              child: TextField(
            controller: _controller,
            decoration:
                InputDecoration.collapsed(hintText: "Envie uma menssagem"),
            onChanged: (text) {
              setState(() {
                isComposing = text.isNotEmpty;
              });
            },
            onSubmitted: (text) {
              widget.sendMessage(text: text);
              _reset();
            },
          )),
          IconButton(
              icon: Icon(Icons.send),
              onPressed: isComposing
                  ? () {
                      widget.sendMessage(text : _controller.text);
                      _reset();
                    }
                  : null)
        ],
      ),
    );
  }
}
