import 'dart:io';

import 'package:ai_picture_detection_demo/crop_image_route.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            FlatButton(onPressed: getImage, child: Text('拍照')),
            FlatButton(onPressed: chooseImage, child: Text('从相册获取')),
          ],
        ),
      ),
    );
  }


  ///拍摄照片
  Future getImage() async {
    await ImagePicker.pickImage(source: ImageSource.camera)
        .then((image) => cropImage(image));
  }

  ///从相册选取
  Future chooseImage() async {
    await ImagePicker.pickImage(source: ImageSource.gallery)
        .then((image) => cropImage(image));
  }


  void cropImage(File originalImage) async {
    String result = await Navigator.push(context,
        MaterialPageRoute(builder: (context) => CropImageRoute(originalImage)));
    if (result.isEmpty) {
      print('上传失败');
    } else {
      //result是图片上传后拿到的url
      setState(() {

      });
    }
  }



}
