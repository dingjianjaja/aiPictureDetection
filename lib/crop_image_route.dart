import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_crop/image_crop.dart';
import 'package:image/image.dart' as ty;

class CropImageRoute extends StatefulWidget {
  CropImageRoute(this.image);

  File image; //原始图片路径

  @override
  _CropImageRouteState createState() => new _CropImageRouteState();
}

class _CropImageRouteState extends State<CropImageRoute> {
  double baseLeft; //图片左上角的x坐标
  double baseTop; //图片左上角的y坐标
  double imageWidth; //图片宽度，缩放后会变化
  double imageScale = 1; //图片缩放比例
  ui.Image imageView;
  final cropKey = GlobalKey<CropState>();
  bool selectDone = false;
  File selectImage;
  ty.Image newSizeImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      color: Colors.blue,
      child: selectDone
          ? CustomPaint(
            painter: TYPainter(context, imageView),
          )
          : Column(
              children: <Widget>[
                Container(
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: Crop.file(
                    widget.image,
                    key: cropKey,
                    aspectRatio: 1.0,
                    alwaysShowGrid: true,
                  ),
                ),
                RaisedButton(
                  onPressed: () {
                    _crop(widget.image);
                  },
                  child: Text('ok'),
                ),
              ],
            ),
    ));
  }

  Future<void> _crop(File originalFile) async {
    final crop = cropKey.currentState;
    final area = crop.area;
    if (area == null) {
      //裁剪结果为空
      print('裁剪不成功');
    }
    await ImageCrop.requestPermissions().then((value) {
      if (value) {
        ImageCrop.cropImage(
          file: originalFile,
          area: crop.area,
        ).then((value) {
          changeImageSizeToBase64String(value);
          print('裁剪成功');
        }).catchError(() {
          print('裁剪不成功');
        });
      } else {
        upload(originalFile);
      }
    });
  }

  /// 转换图片尺寸并返回Base64格式字符串
  Future<String> changeImageSizeToBase64String(File file) async {
    /// 获取原图
    ty.Image image = ty.decodeImage(file.readAsBytesSync());
    /// 修改为制定像素大小
    ty.Image newImage = ty.copyResize(image, width: 608);
    /// 转化为base64格式
    String imgString = base64Encode(ty.encodeJpg(newImage));

    /// 完成后更新UI
    selectDone = true;
    selectImage = file;

    imageView = await loadImageByUint8List(ty.encodeJpg(newImage));

    setState(() {});

    return imgString;
  }

  /// 通過[Uint8List]獲取圖片
  Future<ui.Image> loadImageByUint8List(Uint8List list) async {
    ui.Codec codec = await ui.instantiateImageCodec(list);
    ui.FrameInfo frame = await codec.getNextFrame();
    return frame.image;
  }

  ///上传
  void upload(File file) {
    print(file.path);
    Dio dio = Dio();
    dio
        .post("http://your ip:port/", data: FormData.fromMap({'file': file}))
        .then((response) {
      if (!mounted) {
        return;
      }
      //处理上传结果
      print('上传头像结果 ${response.data}');
    });
  }
}

class TYPainter extends CustomPainter {
  ui.Image image;

  Paint tyPaint = Paint();
  final BuildContext context;
  Color color = Colors.red;

  TYPainter(this.context, this.image) {
    this.tyPaint = Paint();
  }

  @override
  void paint(Canvas canvas, Size size) {
    double scale = size.width / image.width *1;

    canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width * 1.0, image.height * 1.0),
        Rect.fromLTWH(0, 0, scale*image.width, scale*image.height),
        tyPaint);
    canvas.drawRect(
        Rect.fromLTWH(140 *scale, 110*scale, 30*scale, 130*scale),
        tyPaint
          ..style = PaintingStyle.stroke
          ..color = Colors.red);

    TextPainter textPainter = TextPainter(
        textAlign: TextAlign.center,
        maxLines: 1,
        text: TextSpan(
          text: 'RRU',style: TextStyle(color: Colors.red),
        ),
        textDirection: TextDirection.rtl);
    textPainter
      ..layout(maxWidth: 50, minWidth: 50)
      ..paint(canvas, Offset(200*scale, 100*scale));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
