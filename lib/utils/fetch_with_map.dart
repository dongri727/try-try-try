import 'package:acorn_client/acorn_client.dart';
import 'package:flutter/material.dart';
import '../serverpod_client.dart';

class FetchWithMapRepository {
  List<WithMap> listWithMap = [];
  List<int> withMapIds = [];

  // データを返すように変更
  Future<List<WithMap>> fetchWithMap({List<int>? keyNumbers}) async {
    try {
      // データ取得
      listWithMap = await client.withMap.getWithMap(keyNumbers: keyNumbers);
      withMapIds = listWithMap.map((item) => item.id as int).toList();
      print('Fetched listWithMap: $listWithMap');
      return listWithMap; // 取得したデータを返す
    } on Exception catch (e) {
      debugPrint('$e');
      return []; // エラー時には空のリストを返す
    }
  }
}
