import 'package:flutter/material.dart';
import '../models/province.dart';
import '../models/city.dart';
import '../models/cost.dart';
import '../services/service_rajaongkir.dart';

class OngkirProvider with ChangeNotifier {
  final RajaOngkirService _service = RajaOngkirService();

  // ================================
  // DATA LISTS
  // ================================
  List<Province> _provinces = [];
  List<City> _originCities = [];
  List<City> _destinationCities = [];
  List<ShippingCost> _costs = [];

  // ================================
  // SELECTED VALUES
  // ================================
  Province? _selectedOriginProvince;
  City? _selectedOriginCity;
  Province? _selectedDestProvince;
  City? _selectedDestCity;
  Courier? _selectedCourier;
  double? _weightKg = 1;

  List<City> originDistricts = [], destDistricts = [];
  City? originDistrict, destDistrict;
  String? locationError;
  int _revision = 0;

  void _invalidateCosts() {
    _revision++;
    _costs = [];
    _selectedCost = null;
  }

  void selectDistrict(City? value, bool origin) {
    if (origin) {
      originDistrict = value;
    } else {
      destDistrict = value;
    }
    _invalidateCosts();
    notifyListeners();
  }

  // Paket pengiriman terpilih
  ShippingCost? _selectedCost;

  // ================================
  // LOADING STATES
  // ================================
  bool _isLoadingProvinces = false;
  bool _isLoadingOriginCities = false;
  bool _isLoadingDestCities = false;
  bool _isLoadingCosts = false;

  // ================================
  // GETTERS
  // ================================
  List<Province> get provinces => _provinces;
  List<City> get originCities => _originCities;
  List<City> get destinationCities => _destinationCities;
  List<ShippingCost> get costs => _costs;

  Province? get selectedOriginProvince => _selectedOriginProvince;
  City? get selectedOriginCity => _selectedOriginCity;
  Province? get selectedDestProvince => _selectedDestProvince;
  City? get selectedDestCity => _selectedDestCity;
  Courier? get selectedCourier => _selectedCourier;

  ShippingCost? get selectedCost => _selectedCost;

  bool get isLoadingProvinces => _isLoadingProvinces;
  bool get isLoadingOriginCities => _isLoadingOriginCities;
  bool get isLoadingDestCities => _isLoadingDestCities;
  bool get isLoadingCosts => _isLoadingCosts;

  // ================================
  // AVAILABLE COURIERS (UNTUK DROPDOWN)
  // ================================
  // Sesuaikan dengan daftar kurir yang didukung endpoint calculate cost.
  final List<Courier> couriers = [
    Courier(code: 'jne', name: 'JNE'),
    Courier(code: 'pos', name: 'POS Indonesia'),
    Courier(code: 'tiki', name: 'TIKI'),
    Courier(code: 'lion', name: 'Lion Parcel'),
    Courier(code: 'anteraja', name: 'AnterAja'),
    Courier(code: 'sicepat', name: 'SiCepat'),
    Courier(code: 'jnt', name: 'J&T'),
  ];

  // ================================
  // FETCH PROVINCES
  // ================================
  Future<void> fetchProvinces() async {
    locationError = null;
    _isLoadingProvinces = true;
    notifyListeners();

    try {
      _provinces = await _service.getProvinces();
    } catch (e) {
      locationError = 'Gagal memuat provinsi. $e';
      _provinces = [];
    } finally {
      _isLoadingProvinces = false;
      notifyListeners();
    }
  }

  // ================================
  // FETCH ORIGIN CITIES
  // ================================
  Future<void> fetchOriginCities(String provinceId) async {
    _isLoadingOriginCities = true;
    notifyListeners();

    try {
      final items = await _service.getCities(provinceId);
      if (_selectedOriginProvince?.provinceId == provinceId)
        _originCities = items;
    } catch (e) {
      if (_selectedOriginProvince?.provinceId == provinceId)
        locationError = 'Gagal memuat kota. $e';
    } finally {
      if (_selectedOriginProvince?.provinceId == provinceId)
        _isLoadingOriginCities = false;
      notifyListeners();
    }
  }

  // ================================
  // FETCH DESTINATION CITIES
  // ================================
  Future<void> fetchDestinationCities(String provinceId) async {
    _isLoadingDestCities = true;
    notifyListeners();

    try {
      final items = await _service.getCities(provinceId);
      if (_selectedDestProvince?.provinceId == provinceId)
        _destinationCities = items;
    } catch (e) {
      if (_selectedDestProvince?.provinceId == provinceId)
        locationError = 'Gagal memuat kota. $e';
    } finally {
      if (_selectedDestProvince?.provinceId == provinceId)
        _isLoadingDestCities = false;
      notifyListeners();
    }
  }

  // ================================
  // CHECK SHIPPING COST
  // ================================
  Future<String?> checkShippingCost() async {
    final kg = _weightKg;
    if (kg == null || kg < 0.001 || !(kg * 1000).isFinite) {
      return "Masukkan berat dalam kg, minimal 0,001 kg dan maksimal tiga angka desimal.";
    }
    if (originDistrict == null ||
        destDistrict == null ||
        _selectedCourier == null) {
      return 'Mohon lengkapi provinsi, kota asal, kota tujuan, kecamatan asal dan tujuan, serta kurir.';
    }

    _isLoadingCosts = true;
    _costs = [];
    _selectedCost = null;
    notifyListeners();

    try {
      final revision = _revision;
      final options = await _service.checkCost(
        origin: originDistrict!.id, // id district asal
        destination: destDistrict!.id, // id district tujuan
        weightGrams: (kg * 1000).round(),
        courier: _selectedCourier!.code,
      );

      if (revision != _revision) return null;
      _costs = options;
      if (options.isEmpty) return 'Tidak ada layanan untuk rute dan kurir ini.';
      if (_costs.isNotEmpty) {
        _selectedCost = _costs.first;
      }

      return null; // sukses, tidak ada error
    } catch (e) {
      print('Error checkShippingCost: $e');
      return 'Error: $e';
    } finally {
      _isLoadingCosts = false;
      notifyListeners();
    }
  }

  // ================================
  // SETTERS / UPDATERS
  // ================================
  void setOriginProvince(Province? province) {
    originDistricts = [];
    originDistrict = null;
    locationError = null;
    _invalidateCosts();
    _selectedOriginProvince = province;
    _selectedOriginCity = null;
    _originCities = [];
    notifyListeners();

    if (province != null) {
      fetchOriginCities(province.provinceId);
    }
  }

  Future<void> setOriginCity(City? city) async {
    originDistricts = [];
    originDistrict = null;
    locationError = null;
    _invalidateCosts();
    _selectedOriginCity = city;
    notifyListeners();
    if (city == null) return;
    try {
      final items = await _service.getDistricts(city.id);
      if (_selectedOriginCity == city) originDistricts = items;
    } catch (e) {
      if (_selectedOriginCity == city)
        locationError = 'Gagal memuat kecamatan. $e';
    }
    notifyListeners();
  }

  void setDestProvince(Province? province) {
    destDistricts = [];
    destDistrict = null;
    locationError = null;
    _invalidateCosts();
    _selectedDestProvince = province;
    _selectedDestCity = null;
    _destinationCities = [];
    notifyListeners();

    if (province != null) {
      fetchDestinationCities(province.provinceId);
    }
  }

  Future<void> setDestCity(City? city) async {
    destDistricts = [];
    destDistrict = null;
    locationError = null;
    _invalidateCosts();
    _selectedDestCity = city;
    notifyListeners();
    if (city == null) return;
    try {
      final items = await _service.getDistricts(city.id);
      if (_selectedDestCity == city) destDistricts = items;
    } catch (e) {
      if (_selectedDestCity == city)
        locationError = 'Gagal memuat kecamatan. $e';
    }
    notifyListeners();
  }

  void setCourier(Courier? courier) {
    _invalidateCosts();
    _selectedCourier = courier;
    notifyListeners();
  }

  void setWeightKg(String input) {
    _invalidateCosts();
    final value = input.trim().replaceAll(',', '.');
    _weightKg = RegExp(r'^\d+(?:\.\d{1,3})?$').hasMatch(value)
        ? double.tryParse(value)
        : null;
    notifyListeners();
  }

  void setSelectedCost(ShippingCost? cost) {
    _selectedCost = cost;
    notifyListeners();
  }

  // ================================
  // RESET SEMUA FORM
  // ================================
  void reset() {
    _invalidateCosts();
    originDistricts = [];
    destDistricts = [];
    originDistrict = destDistrict = null;
    locationError = null;
    _selectedOriginProvince = null;
    _selectedOriginCity = null;
    _selectedDestProvince = null;
    _selectedDestCity = null;
    _selectedCourier = null;
    _selectedCost = null;

    _weightKg = 1;
    _originCities = [];
    _destinationCities = [];
    _costs = [];

    notifyListeners();
  }
}
