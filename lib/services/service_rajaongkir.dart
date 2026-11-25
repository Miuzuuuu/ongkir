import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/city.dart';
import '../models/cost.dart';
import '../models/province.dart';

class RajaOngkirService {
  static const _apiKey = String.fromEnvironment('RAJAONGKIR_API_KEY');
  static const _apiUrl = 'https://rajaongkir.komerce.id/api/v1';

  // Saat demo web, server lokal meneruskan request dan menambahkan header key.
  static const _root = kIsWeb ? 'http://127.0.0.1:8766' : _apiUrl;
  static const _destinationUrl = '$_root/destination';
  static const _costUrl = '$_root/calculate/district/domestic-cost';

  Map<String, String> get _headers => kIsWeb ? {} : {'key': _apiKey};

  // 1. Daftar provinsi asal dan tujuan.
  Future<List<Province>> getProvinces() async {
    final response = await http.get(
      Uri.parse('$_destinationUrl/province'),
      headers: _headers,
    );
    return _readData(response).map(Province.fromJson).toList();
  }

  // 2. Kota/kabupaten berdasarkan ID provinsi.
  Future<List<City>> getCities(String provinceId) async {
    final response = await http.get(
      Uri.parse('$_destinationUrl/city/$provinceId'),
      headers: _headers,
    );
    return _readData(response).map(City.fromJson).toList();
  }

  // 3. Kecamatan berdasarkan ID kota/kabupaten.
  Future<List<City>> getDistricts(String cityId) async {
    final response = await http.get(
      Uri.parse('$_destinationUrl/district/$cityId'),
      headers: _headers,
    );
    return _readData(response).map(City.fromJson).toList();
  }

  // 4. Kelurahan/desa berdasarkan ID kecamatan (opsional untuk tarif kecamatan).
  Future<List<City>> getSubDistricts(String districtId) async {
    final response = await http.get(
      Uri.parse('$_destinationUrl/sub-district/$districtId'),
      headers: _headers,
    );
    return _readData(response).map(City.fromJson).toList();
  }

  // 5. Tarif domestik berdasarkan kecamatan asal, kecamatan tujuan dan kurir.
  Future<List<ShippingCost>> checkCost({
    required String origin,
    required String destination,
    required int weightGrams,
    required String courier,
  }) async {
    final response = await http.post(
      Uri.parse(_costUrl),
      headers: {
        ..._headers,
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: {
        'origin': origin,
        'destination': destination,
        'weight':
            weightGrams.toString(), // Berat dari form kg sudah dikonversi.
        'courier': courier,
        'price': 'lowest',
      },
    );
    return _readData(response)
        .map(ShippingCost.fromJson)
        .where((option) => option.courierCode == courier)
        .toList();
  }

  List<Map<String, dynamic>> _readData(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception(
          'Permintaan RajaOngkir gagal (HTTP ${response.statusCode}).');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return (decoded['data'] as List).cast<Map<String, dynamic>>();
  }
}
