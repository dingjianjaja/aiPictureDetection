

import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class TYPainter extends CustomPainter {
  Rect selectRect = Rect.fromLTWH(0, 0, 0, 0);
  List elementList;

  ui.Image image;
  List dataList = [];

  Paint tyPaint = Paint();
  final BuildContext context;
  Color color = Colors.red;

  TYPainter(this.context, this.image, this.dataList, this.selectRect,
      this.elementList) {
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

    /// 画 选框
    canvas.drawRect(
        selectRect,
        tyPaint
          ..color = Colors.orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    elementList.clear();

    /// 画右下角 编辑点
    canvas.drawCircle(
        Offset(selectRect.right, selectRect.bottom),
        4,
        tyPaint
          ..style = PaintingStyle.fill
          ..color = Colors.green);

    /// 根据返回检测点 进行绘制
    for (List item in dataList) {
      String title = item[0];
      double x = item[2];
      double y = item[3];
      double w = item[4];
      double h = item[5];

      /// 如果中心点在框选的范围内，则展示出来
      if (!pointInRect(Offset(x * scale, y * scale), selectRect)) {
        continue;
      }

      elementList.add(item);

      canvas.drawRect(
          Rect.fromCenter(
              center: Offset(x * scale, y * scale),
              width: w * scale,
              height: h * scale),
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

/// 点是否在给定矩形范围内部
bool pointInRect(Offset point, Rect rect) {
  if (point.dx > rect.left &&
      rect.right > point.dx &&
      point.dy > rect.top &&
      point.dy < rect.bottom) {
    return true;
  }
  return false;
}

/// 两个点是否近
bool hitPoint(Offset point, Offset hit) {
  print(point);
  print(hit);
  if ((point.dx - hit.dx).abs() < 10 && (point.dy - hit.dy).abs() < 10) {
    return true;
  }
  return false;
}
