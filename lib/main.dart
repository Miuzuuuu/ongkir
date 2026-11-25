import 'package:device_preview_plus/device_preview_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/ongkir_providers.dart';
import 'pages/cek_ongkir.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (_) => const MyApp(),
    ),
  );
}

// test
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OngkirProvider(),
      child: MaterialApp(
        title: 'Cek Ongkir',
        locale: kReleaseMode ? null : DevicePreview.locale(context),
        builder: kReleaseMode ? null : DevicePreview.appBuilder,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: CekOngkirScreen(),
        debugShowCheckedModeBanner: true,
      ),
    );
  }
}
