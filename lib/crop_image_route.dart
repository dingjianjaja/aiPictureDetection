import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_crop/image_crop.dart';
import 'package:image/image.dart' as ty;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

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
  List totalDataList;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      color: Colors.blue,
      child: selectDone
          ? CustomPaint(
              painter: TYPainter(context, imageView,totalDataList),
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
      } else {}
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



    imageView = await loadImageByUint8List(ty.encodeJpg(newImage));

    File newFile = File(await _findFileDownloadLocalPath('dingjian.jpg'));
    newFile.writeAsBytesSync(ty.encodeJpg(newImage));

    upload(newFile);


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
    Dio dio = Dio();
    dio
        .post("http://192.168.0.230:8080",
            data: FormData.fromMap(
                {'file': MultipartFile.fromFileSync(file.path)}))
        .then((response) {
      if (!mounted) {
        return;
      }
      //处理上传结果
      print('上传结果 ${response.data}');
      String resposeStr = response.data;

      var tempMap = jsonDecode(resposeStr);
      String listStr = tempMap['res'];
      String newStr = listStr.replaceAll("'", '\"');
      List tempArr = json.decode(newStr);

      print(tempArr);

      totalDataList = tempArr;
      /// 完成后更新UI
      selectDone = true;
      selectImage = file;
      setState(() {
      });

    });
  }

  /// 申请权限
  Future<bool> _checkPermission() async {
    /// 先对所在平台进行判断
    if (Theme.of(context).platform == TargetPlatform.android) {
      PermissionStatus permission = await PermissionHandler()
          .checkPermissionStatus(PermissionGroup.storage);
      if (permission != PermissionStatus.granted) {
        Map<PermissionGroup, PermissionStatus> permissions =
            await PermissionHandler()
                .requestPermissions([PermissionGroup.storage]);
        if (permissions[PermissionGroup.storage] == PermissionStatus.granted) {
          return true;
        }
      } else {
        return true;
      }
    } else {
      return true;
    }
    return false;
  }

  /// 获取设备主存储路径
  Future<String> _findLocalPath() async {
    await _checkPermission();

    /// 因为Apple没有外置存储，所以第一步我们需要先对所在平台进行判断
    /// 如果是android，使用getExternalStorageDirectory
    /// 如果是iOS，使用getApplicationSupportDirectory
    final directory = Theme.of(context).platform == TargetPlatform.android
        ? await getExternalStorageDirectory()
        : await getApplicationSupportDirectory();
    return directory.path;
  }

  /// 获取文件下载存储路径
  Future<String> _findFileDownloadLocalPath(String fileName) async {
    String mainPath = await _findLocalPath();
    var file = Directory(mainPath + "/" + "download/");
    try {
      bool exists = await file.exists();
      if (!exists) {
        await file.create();
      }
    } catch (e) {
      print(e);
    }
    return file.path + fileName;
  }
}

class TYPainter extends CustomPainter {
  ui.Image image;
  List dataList = [];

  Paint tyPaint = Paint();
  final BuildContext context;
  Color color = Colors.red;

  TYPainter(this.context, this.image, this.dataList) {
    this.tyPaint = Paint();
  }

  @override
  void paint(Canvas canvas, Size size) {
    double scale = size.width / image.width * 1;
    canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width * 1.0, image.height * 1.0),
        Rect.fromLTWH(0, 0, scale * image.width, scale * image.height),
        tyPaint);

    /// 根据返回检测点 进行绘制
    for (List item in dataList) {
      String title = item[0];
      double x = item[2];
      double y = item[3];
      double w = item[4];
      double h = item[5];

      canvas.drawRect(
        Rect.fromCenter(center: Offset(x * scale, y * scale),width: w * scale,height: h * scale),
          tyPaint
            ..style = PaintingStyle.stroke
            ..color = Colors.red
            ..strokeWidth = 2);

      TextPainter textPainter = TextPainter(
          textAlign: TextAlign.center,
          maxLines: 1,
          text: TextSpan(
            text: title,
            style: TextStyle(color: Colors.red),
          ),
          textDirection: TextDirection.rtl);
      textPainter
        ..layout(maxWidth: 150, minWidth: 50)
        ..paint(canvas, Offset(x * scale, (y - 20) * scale));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
