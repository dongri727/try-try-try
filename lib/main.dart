import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:try_try_try/utils/fetch_with_map.dart';

import 'serverpod_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeServerpodClient();
  runApp(const MyApp());
}

/// Annotate the Dart function to bind it to the JavaScript `initChart` function.
/// This allows Dart to call the JavaScript function directly.
@JS('initChart')
external void initChart(String chartId, String optionsJson);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final String _viewType = 'echarts-div';
  final FetchWithMapRepository _repository = FetchWithMapRepository();

  // データリストを初期化
  List<Map<String, dynamic>> _dataList = [];

  @override
  void initState() {
    super.initState();

    // Register the view factory for the ECharts container
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final html.DivElement div = html.DivElement()
        ..id = 'echarts_div'
        ..style.width = '100%'
        ..style.height = '600px';

      // 初期化
      Future.microtask(() async {
        await _initializeChart();
      });

      return div;
    });
  }

  // データ取得ボタンのアクション
  Future<void> _onFetchWithMapButtonPressed() async {
    try {
      // データベースからデータ取得
      final listWithMap = await _repository.fetchWithMap(keyNumbers: [100, 101, 102, 103, 104]);

      // データをローカルに保存
      setState(() {
        _dataList = listWithMap.map((d) {
          return {
            'value': [d.longitude, d.latitude, d.logarithm, d.annee, d.location, d.precise],
            'name': d.affair
          };
        }).toList();
      });

      // チャートを再描画
      await _initializeChart();
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  // チャートを初期化または再描画
  Future<void> _initializeChart() async {
    try {
      final String coastLineString = await rootBundle.loadString('assets/coastline.json');
      final List<dynamic> coastLineData = json.decode(coastLineString);
      final String ridgeLineString = await rootBundle.loadString('assets/ridge.json');
      final List<dynamic> ridgeLineData = json.decode(ridgeLineString);
      final String trenchLineString = await rootBundle.loadString('assets/trench.json');
      final List<dynamic> trenchLineData = json.decode(trenchLineString);

      final transformedCoast = coastLineData.map((item) {
        final double lon = (item[0] is num) ? item[0].toDouble() : double.tryParse(item[0].toString()) ?? 0.0;
        final double lat = (item[1] is num) ? item[1].toDouble() : double.tryParse(item[1].toString()) ?? 0.0;
        return [lon, lat, 0.0];
      }).toList();

      final transformedRidge = ridgeLineData.map((item) {
        final double lon = (item[0] is num) ? item[0].toDouble() : double.tryParse(item[0].toString()) ?? 0.0;
        final double lat = (item[1] is num) ? item[1].toDouble() : double.tryParse(item[1].toString()) ?? 0.0;
        return [lon, lat, 0.0];
      }).toList();

      final transformedTrench = trenchLineData.map((item) {
        final double lon = (item[0] is num) ? item[0].toDouble() : double.tryParse(item[0].toString()) ?? 0.0;
        final double lat = (item[1] is num) ? item[1].toDouble() : double.tryParse(item[1].toString()) ?? 0.0;
        return [lon, lat, 0.0];
      }).toList();

      final Map<String, dynamic> option = {
        'tooltip': {},
        'xAxis3D': {
          'type': 'value',
          'name': 'Longitude',
          'min': -180,
          'max': 180,
          'splitNumber': 6
        },
        'yAxis3D': {
          'type': 'value',
          'name': 'Latitude',
          'min': -90,
          'max': 90,
          'splitNumber': 2
        },
        'zAxis3D': {
          'type': 'value',
          'name': 'Timeline',
          'min': -5000,
          'max': 2000,
          'splitNumber': 2
        },
        'grid3D': {
          'axisLine': {
            'lineStyle': {'color': '#fff'},
          },
          'axisPointer': {
            'lineStyle': {'color': '#ffbd67'},
          },
          'boxWidth': 360,
          'boxDepth': 180,
          'boxHeight': 180,
          'viewControl': {'projection': 'orthographic'},
        },
        'series': [
          {
            'type': 'scatter3D',
            'data': transformedCoast,
            'symbolSize': 3,
            'itemStyle': {'color': 'white'}
          },
          {
            'type': 'scatter3D',
            'data': transformedRidge,
            'symbolSize': 3,
            'itemStyle': {'color': '#bc8f8f'}
          },
          {
            'type': 'scatter3D',
            'data': transformedTrench,
            'symbolSize': 3,
            'itemStyle': {'color': '#cd5c5c'}
          },
          // ボタンで取得したデータをシリーズに追加
          if (_dataList.isNotEmpty)
            {
              'type': 'scatter3D',
              'data': _dataList,
              'symbolSize': 8,
              'dimensions': ['Longitude', 'Latitude', 'Logarithm', 'Year', 'Location', 'Precise'],
              'itemStyle': {'color': 'yellow'},
            }
        ],
      };

      final String optionJson = json.encode(option);
      initChart('echarts_div', optionJson);
    } catch (e) {
      print('Error initializing chart: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ECharts Flutter Web',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ECharts 3D Scatter Plot in Flutter Web'),
        ),
        body: Column(
          children: [
            Expanded(child: HtmlElementView(viewType: _viewType)),
            Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: ElevatedButton(
                onPressed: _onFetchWithMapButtonPressed,
                child: const Text('Get Data'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

