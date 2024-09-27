# 智云物联平台移动应用

## 项目简介

智云物联平台移动应用是一个基于Flutter开发的移动端应用程序，旨在为用户提供便捷的物联网设备管理和数据监控功能。该应用允许用户登录、查看设备列表、查看设备详细信息以及设备数据的图表展示。

## 主要功能

1. 用户登录
2. 设备列表展示
3. 设备详细信息查看
4. 设备数据图表展示
5. 自定义日期范围的数据查询

## 技术栈

- Flutter
- Dart
- HTTP请求（使用http包）
- 自定义绘制（CustomPainter）
- 异步编程（Future和FutureBuilder）

## 项目结构

```
lib/
├── main.dart
├── pages/
│   ├── login_page.dart
│   ├── device_list_page.dart
│   └── device_detail_page.dart
└── services/
    └── api_service.dart
```

## 主要组件

### 1. 登录页面（LoginPage）

登录页面允许用户输入用户名和密码进行身份验证。成功登录后，用户将被导航到设备列表页面。

相关代码：

```1:80:lib/pages/login_page.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'device_list_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();

  void _login() async {
    if (_formKey.currentState!.validate()) {
      bool success = await _apiService.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceListPage(apiService: _apiService),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登录失败,请检查用户名和密码')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('登录')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: '用户名'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入用户名';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: '密码'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入密码';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                child: Text('登录'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```


### 2. 设备列表页面（DeviceListPage）

设备列表页面展示了用户所有可用的设备。用户可以点击任何设备以查看其详细信息。

相关代码：

```1:64:lib/pages/device_list_page.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'device_detail_page.dart';

class DeviceListPage extends StatefulWidget {
  final ApiService apiService;

  DeviceListPage({required this.apiService});

  @override
  _DeviceListPageState createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  late Future<List<dynamic>> _devicesFuture;

  @override
  void initState() {
    super.initState();
    _devicesFuture = widget.apiService.getDevices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('设备列表')),
      body: FutureBuilder<List<dynamic>>(
        future: _devicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('加载设备失败'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('没有可用的设备'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final device = snapshot.data![index];
                return ListTile(
                  title: Text(device['deviceName']),
                  subtitle: Text(device['macAddress']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DeviceDetailPage(
                          apiService: widget.apiService,
                          deviceId: device['id'].toString(),
                          deviceName: device['deviceName'],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
```


### 3. 设备详情页面（DeviceDetailPage）

设备详情页面显示了选定设备的详细信息和数据图表。用户可以选择自定义日期范围来查看特定时间段的数据。

相关代码：

```1:226:lib/pages/device_detail_page.dart
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
```


### 4. API服务（ApiService）

API服务负责处理与后端服务器的所有通信，包括用户认证、获取设备列表和设备数据。

相关代码：

```1:57:lib/services/api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl = 'http://10.0.2.2:8080';
  String? token;

  Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      token = data['token'];
      return true;
    }
    return false;
  }

  Future<List<dynamic>> getDevices() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/devices'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load devices');
  }

  Future<Map<String, dynamic>> getDeviceData(String deviceId, {DateTime? startTime, DateTime? endTime}) async {
    String url = '$baseUrl/api/devices/$deviceId/data';
    if (startTime != null && endTime != null) {
      url += '?startTime=${startTime.toIso8601String()}&endTime=${endTime.toIso8601String()}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load device data');
  }
}
```


## 如何运行

1. 确保您的开发环境中已安装Flutter和Dart。
2. 克隆此仓库到本地。
3. 在项目根目录下运行 `flutter pub get` 以安装依赖。
4. 确保您有一个可用的模拟器或连接的物理设备。
5. 运行 `flutter run` 启动应用。

## 注意事项

- 确保后端服务器正在运行，并且 `ApiService` 中的 `baseUrl` 设置正确。
- 当前配置假设后端服务器在Android模拟器上运行，使用 `10.0.2.2` 作为本地主机地址。如果您使用不同的设置，请相应地更新 `baseUrl`。

## 未来改进

1. 实现用户注册功能
2. 添加设备管理功能（添加、删除、编辑设备）
3. 实现实时数据更新
4. 增加更多的数据可视化选项
5. 改进错误处理和用户反馈
6. 添加单元测试和集成测试

## 贡献

欢迎提交问题报告和拉取请求。对于重大更改，请先开启一个问题讨论您想要改变的内容。

## 许可证

[MIT](https://choosealicense.com/licenses/mit/)