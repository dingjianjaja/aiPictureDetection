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
import 'package:sensors/sensors.dart';
import 'dart:math';

import 'common/widgets/ty_painter.dart';

class CropImageRoute extends StatefulWidget {
  CropImageRoute(this.image,this.url);

  String url;
  File image; //原始图片路径

  @override
  _CropImageRouteState createState() => new _CropImageRouteState();
}

enum RectEditMode {
  //矩形选框编辑方式
  reDraw, // 重绘
  move, // 移动
  scale, // 缩放
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
  Rect selectRect = Rect.fromLTWH(0, 0, 0, 0);
  List elementList = []; // 框内 元素数组，name ： 出现次数
  double radian; // 当前角度
  Map timeRadianMap = Map(); // 某时刻手机对应的角度
  bool isChangeRect = false; // 是否修改选框，false修改，true重绘
  RectEditMode editMode;

  @override
  void initState() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      radian = atan(event.x / event.y);
      /* 记录手机的方向角度
      DateTime date = DateTime.now();
      String timestamp = "${date.year.toString()}:${date.month.toString().padLeft(2,'0')}:${date.day.toString().padLeft(2,'0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}";
      timeRadianMap[timestamp] = radian;
      */
//      print(radian);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      color: Colors.white,
      child: selectDone
          ? resultView(context)
          : Column(
              children: <Widget>[
                Container(
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: Crop.file(
                    widget.image,
                    key: cropKey,
                    alwaysShowGrid: true,
                    aspectRatio: 1.0,
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

  Widget resultView(BuildContext context) {
    Map elemntMap = handleElementsData(elementList);

    return Column(
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.width,
          child: GestureDetector(
            /// 滑动手指
            onPanUpdate: (DragUpdateDetails details) {
              print(details);
              print(details.delta);
              if (editMode == RectEditMode.reDraw) {
                selectRect = Rect.fromLTWH(
                    selectRect.left,
                    selectRect.top,
                    selectRect.width + details.delta.dx,
                    selectRect.height + details.delta.dy);
              } else if (editMode == RectEditMode.scale) {
                selectRect = Rect.fromLTWH(
                    selectRect.left,
                    selectRect.top,
                    selectRect.width + details.delta.dx,
                    selectRect.height + details.delta.dy);
              } else if (editMode == RectEditMode.move) {
                selectRect = Rect.fromLTWH(
                    selectRect.left + details.delta.dx,
                    selectRect.top + details.delta.dy,
                    selectRect.width,
                    selectRect.height);
              }

              setState(() {});
            },

            /// 开始画
            onPanStart: (DragStartDetails details) {
              /// 通过点击位置判断编辑方式 如果起点在矩形右下角，编辑方式即为缩放
              /// 如果点在选框内，则为移动
              if (hitPoint(
                  details.globalPosition,
                  Offset(selectRect.left + selectRect.width,
                      selectRect.top + selectRect.height))) {
                editMode = RectEditMode.scale;
              } else if (pointInRect(details.globalPosition, selectRect)) {
                editMode = RectEditMode.move;
              } else {
                editMode = RectEditMode.reDraw;
                selectRect = Rect.fromLTWH(
                    details.globalPosition.dx, details.globalPosition.dy, 0, 0);
              }

              print(details);
            },
            child: CustomPaint(
              painter: TYPainter(
                  context, imageView, totalDataList, selectRect, elementList),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(10, 5, 10, 0),
          height: MediaQuery.of(context).size.height -
              MediaQuery.of(context).size.width,
          child: elemntMap.keys.length > 0
              ? ListView.builder(
                  itemBuilder: (context, index) {
                    String key = elemntMap.keys.toList()[index];
                    int value = elemntMap[key];
                    return Container(
                      height: 45,
                      child: Row(
                        children: [
                          Icon(Icons.clear),
                          Text(key),
                          Expanded(child: Container()),
                          Text("$value 个"),
                        ],
                      ),
                    );
                  },
                  itemCount: elemntMap.keys.length,
                )
              : Text('所选择区域无检测数据，请框选检测区域'),
        ),
      ],
    );
  }

  Map handleElementsData(List data) {
    Map itemsMap = Map();
    data.forEach((element) {
      if (itemsMap.containsKey(element[0])) {
        itemsMap[element[0]] = itemsMap[element[0]] + 1;
      } else {
        itemsMap[element[0]] = 1;
      }
    });
    return itemsMap;
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
        }).catchError((error) {
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

  /// 通过[Uint8List]获取图片
  Future<ui.Image> loadImageByUint8List(Uint8List list) async {
    ui.Codec codec = await ui.instantiateImageCodec(list);
    ui.FrameInfo frame = await codec.getNextFrame();
    return frame.image;
  }

  ///上传
  void upload(File file) {
    Dio dio = Dio();
//    dio
//        .post(widget.url,
//            data: FormData.fromMap(
//                {'file': MultipartFile.fromFileSync(file.path)}))
//        .then((response) {
//      if (!mounted) {
//        return;
//      }
//      //处理上传结果
//      print('上传结果 ${response.data}');
//      String resposeStr = response.data;
//
//      var tempMap = jsonDecode(resposeStr);
//      String listStr = tempMap['res'];
//      String newStr = listStr.replaceAll("'", '\"');
//      List tempArr = json.decode(newStr);
//
//      print(tempArr);
//
//      totalDataList = tempArr;

      /// 完成后更新UI
      selectDone = true;
      selectImage = file;
      setState(() {});
//    });
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

