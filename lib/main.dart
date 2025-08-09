import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

// Import untuk inisialisasi tanggal
import 'package:intl/date_symbol_data_local.dart';

import 'package:image_picker_windows/image_picker_windows.dart';

import 'routes/app_routes.dart';
import 'providers/theme_provider.dart';

// PASTIKAN FUNGSI main ANDA SEPERTI INI:
void main() async {
  // 1. Pastikan binding siap
  WidgetsFlutterBinding.ensureInitialized();

  // 2. TUNGGU inisialisasi tanggal selesai
  await initializeDateFormatting('id_ID', null);

  // 3. Daftarkan delegate lain jika perlu (setelah await)
  if (Platform.isWindows) {
    ImagePickerWindows.registerWith();
  }

  // 4. BARU jalankan aplikasi
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Lapak ULBI',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          // Tema terang dan gelap Anda...
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF36067e),
            // ...sisa tema terang
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF36067e),
            // ...sisa tema gelap
          ),
          onGenerateRoute: AppRoutes.generateRoute,
          initialRoute: AppRoutes.splash,
        );
      },
    );
  }
}
