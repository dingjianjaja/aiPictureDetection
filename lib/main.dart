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
      title: 'AI智能',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'AI施工工艺识别'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  String url;

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
      body: Container(
        color: Color.fromARGB(255, 234, 234, 234),
        child: Center(
          child: Column(
            children: <Widget>[
              Text('请选择检测模型'),
              FlatButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TYSelectImagePage(
                                'http://192.168.0.230:5000', 'AAU施工识别')));
                  },
                  child: Text('AAU施工识别')),
              FlatButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TYSelectImagePage(
                                'http://192.168.0.230:8080', 'BBU施工点识别')));
                  },
                  child: Text('BBU施工识别')),
            ],
          ),
        ),
      ),
    );
  }

  Widget djButton() {
    Radius radius = Radius.circular(15);
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 60,
        width: 100,
        decoration: BoxDecoration(
            color: Color.fromARGB(255, 200, 200, 200),
            borderRadius: BorderRadius.horizontal(left: radius, right: radius)),
        child: Container(
            height: 60,
            width: 100,
            child: Center(
                child: Text(
              '25',
              style: TextStyle(
                  fontSize: 25,
                  color: Color.fromARGB(255, 25, 59, 116),
                  fontWeight: FontWeight.bold),
            )),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.horizontal(left: radius, right: radius),
              boxShadow: [
                BoxShadow(
                    color: Colors.white,
                    offset: Offset(30, 30),
                    blurRadius: 20.0,
                    spreadRadius: 20.0),
              ],
            )),
      ),
    );
  }
}

class TYSelectImagePage extends StatefulWidget {
  final String url;
  final String title;

  TYSelectImagePage(this.url, this.title);

  @override
  _TYSelectImagePageState createState() => _TYSelectImagePageState();
}

class _TYSelectImagePageState extends State<TYSelectImagePage> {
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
    String result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CropImageRoute(originalImage, widget.url)));
    if (result.isEmpty) {
      print('上传失败');
    } else {
      //result是图片上传后拿到的url
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        color: Color.fromARGB(255, 234, 234, 234),
        child: Center(
          child: Column(
            children: <Widget>[
              FlatButton(onPressed: getImage, child: Text('拍照')),
              FlatButton(onPressed: chooseImage, child: Text('从相册获取')),
            ],
          ),
        ),
      ),
    );
  }
}
