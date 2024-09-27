import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class DeviceDetailPage extends StatefulWidget {
  final ApiService apiService;
  final String deviceId;
  final String deviceName;

  DeviceDetailPage({
    required this.apiService,
    required this.deviceId,
    required this.deviceName,
  });

  @override
  _DeviceDetailPageState createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  late Future<Map<String, dynamic>> _deviceDataFuture;
  DateTime _startDate = DateTime.now().subtract(Duration(days: 7));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDeviceData();
  }

  void _loadDeviceData() {
    _deviceDataFuture = widget.apiService.getDeviceData(
      widget.deviceId,
      startTime: _startDate,
      endTime: _endDate,
    );
  }

  List<MapEntry<DateTime, double>> _getDataPoints(List<dynamic> datapoints) {
    return datapoints.map((datapoint) {
      final dateTime = DateTime.parse(datapoint['at']);
      final value = double.parse(datapoint['value'].toString());
      return MapEntry(dateTime, value);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.deviceName)),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('开始日期: ${DateFormat('yyyy-MM-dd').format(_startDate)}'),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null && picked != _startDate) {
                      setState(() {
                        _startDate = picked;
                        _loadDeviceData();
                      });
                    }
                  },
                  child: Text('选择开始日期'),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('结束日期: ${DateFormat('yyyy-MM-dd').format(_endDate)}'),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (picked != null && picked != _endDate) {
                      setState(() {
                        _endDate = picked;
                        _loadDeviceData();
                      });
                    }
                  },
                  child: Text('选择结束日期'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _deviceDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('加载设备数据失败'));
                } else if (!snapshot.hasData || snapshot.data!['datapoints'].isEmpty) {
                  return Center(child: Text('没有可用的数据'));
                } else {
                  final datapoints = snapshot.data!['datapoints'] as List;
                  final dataPoints = _getDataPoints(datapoints);
                  return Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 250,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(40, 20, 20, 40),
                            child: CustomPaint(
                              painter: ChartPainter(dataPoints),
                              size: Size.infinite,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Text('数据点数量: ${datapoints.length}'),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  final List<MapEntry<DateTime, double>> dataPoints;
  final double minY;
  final double maxY;
  final DateTime minX;
  final DateTime maxX;

  ChartPainter(this.dataPoints)
      : minY = dataPoints.map((e) => e.value).reduce((a, b) => a < b ? a : b),
        maxY = dataPoints.map((e) => e.value).reduce((a, b) => a > b ? a : b),
        minX = dataPoints.map((e) => e.key).reduce((a, b) => a.isBefore(b) ? a : b),
        maxX = dataPoints.map((e) => e.key).reduce((a, b) => a.isAfter(b) ? a : b);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // 绘制坐标轴
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), axisPaint);
    canvas.drawLine(Offset(0, size.height), Offset(0, 0), axisPaint);

    // 绘制数据点和连线
    final path = Path();
    for (int i = 0; i < dataPoints.length; i++) {
      final point = dataPoints[i];
      final x = (point.key.difference(minX).inSeconds / maxX.difference(minX).inSeconds) * size.width;
      final y = size.height - ((point.value - minY) / (maxY - minY)) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // 绘制横轴标签
    final textStyle = TextStyle(color: Colors.black, fontSize: 10);
    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i <= 5; i++) {
      final x = i * size.width / 5;
      final date = minX.add(Duration(seconds: (maxX.difference(minX).inSeconds * i ~/ 5)));
      textPainter.text = TextSpan(
        text: DateFormat('MM-dd HH:mm').format(date),
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height + 5));
    }

    // 绘制纵轴标签
    for (int i = 0; i <= 5; i++) {
      final y = size.height - i * size.height / 5;
      final value = minY + (maxY - minY) * i / 5;
      textPainter.text = TextSpan(
        text: value.toStringAsFixed(2),
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(-textPainter.width - 5, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}