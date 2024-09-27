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