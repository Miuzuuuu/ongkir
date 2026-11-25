import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../providers/ongkir_providers.dart';
import '../models/province.dart';
import '../models/city.dart';
import '../models/cost.dart';

class CekOngkirScreen extends StatefulWidget {
  const CekOngkirScreen({super.key});

  @override
  State<CekOngkirScreen> createState() => _CekOngkirScreenState();
}

class _CekOngkirScreenState extends State<CekOngkirScreen> {
  final TextEditingController _weightController = TextEditingController(
    text: '1',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OngkirProvider>().fetchProvinces();
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xff183c3a);
    const accent = Color(0xff09695d);
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: accent, primary: accent),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xffa5bab6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accent, width: 2),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xfff4f7f5),
        appBar: AppBar(
          backgroundColor: ink,
          foregroundColor: Colors.white,
          centerTitle: false,
          leading: const Icon(
            Icons.local_shipping_outlined,
            color: Color(0xffa9edcd),
          ),
          title: const Text(
            'Cek Ongkos Kirim',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                context.read<OngkirProvider>().reset();
                _weightController.text = '1';
              },
              tooltip: 'Reset',
            ),
          ],
        ),
        body: Consumer<OngkirProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (provider.locationError != null)
                        Text(provider.locationError!),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final origin = _buildOriginSection(provider);
                          final destination = _buildDestinationSection(
                            provider,
                          );
                          if (constraints.maxWidth >= 660) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: origin),
                                const SizedBox(width: 24),
                                Expanded(child: destination),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              origin,
                              const SizedBox(height: 24),
                              destination,
                            ],
                          );
                        },
                      ),
                      const Divider(height: 36),
                      _heading('Detail paket', Icons.inventory_2_outlined, ink),
                      const SizedBox(height: 12),
                      _buildWeightAndCourier(provider),
                      const SizedBox(height: 20),
                      _buildCheckButton(provider),
                      if (provider.costs.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildResults(provider),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _heading(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Color.alphaBlend(color.withAlpha(24), Colors.white),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Color(0xff183c3a),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOriginSection(OngkirProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'Asal pengiriman',
          Icons.my_location_rounded,
          const Color(0xff09695d),
        ),
        SizedBox(height: 12),
        DropdownSearch<Province>(
          items: provider.provinces,
          selectedItem: provider.selectedOriginProvince,
          onChanged: provider.setOriginProvince,
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              labelText: 'Provinsi Asal',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.map_outlined),
            ),
          ),
          popupProps: PopupProps.modalBottomSheet(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Cari provinsi...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            modalBottomSheetProps: ModalBottomSheetProps(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            itemBuilder: (context, item, isSelected) {
              return ListTile(title: Text(item.province), selected: isSelected);
            },
          ),
          filterFn: (item, filter) =>
              item.province.toLowerCase().contains(filter.toLowerCase()),
        ),
        SizedBox(height: 12),
        DropdownSearch<City>(
          items: provider.originCities,
          selectedItem: provider.selectedOriginCity,
          enabled: provider.originCities.isNotEmpty,
          onChanged: provider.setOriginCity,
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              labelText: 'Kota Asal',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
          ),
          popupProps: PopupProps.modalBottomSheet(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Cari kota...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            modalBottomSheetProps: ModalBottomSheetProps(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            itemBuilder: (context, item, isSelected) {
              return ListTile(
                title: Text(item.fullName),
                subtitle: Text('Kode Pos: ${item.zipCode}'),
                selected: isSelected,
              );
            },
            emptyBuilder: (context, searchEntry) => Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Pilih provinsi terlebih dahulu',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
          filterFn: (item, filter) =>
              item.fullName.toLowerCase().contains(filter.toLowerCase()),
        ),
        const SizedBox(height: 12),
        DropdownSearch<City>(
          items: provider.originDistricts,
          selectedItem: provider.originDistrict,
          enabled: provider.originDistricts.isNotEmpty,
          onChanged: (item) => provider.selectDistrict(item, true),
          popupProps: const PopupProps.menu(showSearchBox: true),
          dropdownDecoratorProps: const DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
                labelText: 'Kecamatan Asal', border: OutlineInputBorder()),
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationSection(OngkirProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'Tujuan pengiriman',
          Icons.outlined_flag_rounded,
          const Color(0xff97491d),
        ),
        SizedBox(height: 12),
        DropdownSearch<Province>(
          items: provider.provinces,
          selectedItem: provider.selectedDestProvince,
          onChanged: provider.setDestProvince,
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              labelText: 'Provinsi Tujuan',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.map_outlined),
            ),
          ),
          popupProps: PopupProps.modalBottomSheet(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Cari provinsi...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            modalBottomSheetProps: ModalBottomSheetProps(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            itemBuilder: (context, item, isSelected) {
              return ListTile(title: Text(item.province), selected: isSelected);
            },
          ),
          filterFn: (item, filter) =>
              item.province.toLowerCase().contains(filter.toLowerCase()),
        ),
        SizedBox(height: 12),
        DropdownSearch<City>(
          items: provider.destinationCities,
          selectedItem: provider.selectedDestCity,
          enabled: provider.destinationCities.isNotEmpty,
          onChanged: provider.setDestCity,
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              labelText: 'Kota Tujuan',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
          ),
          popupProps: PopupProps.modalBottomSheet(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Cari kota...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            modalBottomSheetProps: ModalBottomSheetProps(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            itemBuilder: (context, item, isSelected) {
              return ListTile(
                title: Text(item.fullName),
                subtitle: Text('Kode Pos: ${item.zipCode}'),
                selected: isSelected,
              );
            },
            emptyBuilder: (context, searchEntry) => Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Pilih provinsi terlebih dahulu',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
          filterFn: (item, filter) =>
              item.fullName.toLowerCase().contains(filter.toLowerCase()),
        ),
        const SizedBox(height: 12),
        DropdownSearch<City>(
          items: provider.destDistricts,
          selectedItem: provider.destDistrict,
          enabled: provider.destDistricts.isNotEmpty,
          onChanged: (item) => provider.selectDistrict(item, false),
          popupProps: const PopupProps.menu(showSearchBox: true),
          dropdownDecoratorProps: const DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
                labelText: 'Kecamatan Tujuan', border: OutlineInputBorder()),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightAndCourier(OngkirProvider provider) {
    return Column(
      children: [
        TextField(
          controller: _weightController,
          decoration: InputDecoration(
            labelText: 'Berat Paket (kg)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.scale_outlined),
            helperText: 'Contoh: 1 atau 1,5 kg',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            provider.setWeightKg(value);
          },
        ),
        SizedBox(height: 16),
        DropdownSearch<Courier>(
          items: provider.couriers,
          selectedItem: provider.selectedCourier,
          onChanged: provider.setCourier,
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              labelText: 'Pilih Kurir',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.local_shipping_outlined),
            ),
          ),
          popupProps: PopupProps.menu(
            showSearchBox: false,
            itemBuilder: (context, item, isSelected) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xffdcf1e7),
                  child: Icon(
                    Icons.local_shipping,
                    color: const Color(0xff09695d),
                  ),
                ),
                title: Text(item.name),
                selected: isSelected,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCheckButton(OngkirProvider provider) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: provider.isLoadingCosts
            ? null
            : () async {
                final error = await provider.checkShippingCost();
                if (mounted && error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: Colors.red),
                  );
                }
              },
        icon: provider.isLoadingCosts
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(Icons.search),
        label: Text(
          provider.isLoadingCosts ? 'Mengecek...' : 'Cek Ongkir',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff09695d),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildResults(OngkirProvider provider) {
    if (provider.costs.isEmpty) return SizedBox.shrink();

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: const Color(0xff09695d)),
                SizedBox(width: 8),
                Text(
                  'Pilih Paket Pengiriman',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              'Kurir: ${provider.selectedCourier?.name}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            SizedBox(height: 16),

            // 🔽 Dropdown paket (kurir + service)
            DropdownSearch<ShippingCost>(
              items: provider.costs,
              selectedItem: provider.selectedCost,
              onChanged: provider.setSelectedCost,
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: 'Pilih Paket',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_shipping_outlined),
                ),
              ),
              popupProps: PopupProps.modalBottomSheet(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: 'Cari paket (service/kurir)...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                modalBottomSheetProps: ModalBottomSheetProps(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                ),
                itemBuilder: (context, item, isSelected) {
                  return ListTile(
                    title: Text('${item.courierName} - ${item.service}'),
                    subtitle: Text(
                      '${item.formattedPrice} • Estimasi: ${item.etd.isEmpty ? '-' : item.etd}',
                    ),
                    selected: isSelected,
                  );
                },
              ),
              filterFn: (item, filter) =>
                  item.label.toLowerCase().contains(filter.toLowerCase()),
            ),

            SizedBox(height: 16),
            if (provider.selectedCost != null) ...[
              Divider(height: 24),
              Text(
                'Detail Paket Terpilih',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xffe9f5ef),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xffbad9cb)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${provider.selectedCost!.courierName} - ${provider.selectedCost!.service}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      provider.selectedCost!.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Biaya: ${provider.selectedCost!.formattedPrice}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff09695d),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Estimasi: ${provider.selectedCost!.etd.isEmpty ? '-' : provider.selectedCost!.etd}',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xff314e48),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
