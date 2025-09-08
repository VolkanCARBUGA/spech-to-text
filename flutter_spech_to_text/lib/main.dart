// ===== GEREKLİ KÜTÜPHANELERİ İMPORT EDİYORUZ =====
import 'package:flutter/material.dart';                                    // Flutter'ın temel UI bileşenleri için
import 'package:flutter_spech_to_text/provider/spech_to_text_provider.dart'; // Ses kaydı ve API işlemlerini yöneten provider
import 'package:flutter_spech_to_text/spech_to_text_page.dart';             // Ana sayfa widget'ı
import 'package:provider/provider.dart';                                    // State management için Provider paketi

// ===== UYGULAMAYI BAŞLATAN ANA FONKSİYON =====
void main() {
  runApp(ChangeNotifierProvider(                                           // Provider ile state management başlatıyoruz
    create: (context) => SpeechToTextProvider(),                           // SpeechToTextProvider instance'ı oluşturuyoruz
    child: MyApp(),                                                        // Ana uygulama widget'ını provider ile sarıyoruz
  ));
}

// ===== ANA UYGULAMA WIDGET'I =====
class MyApp extends StatelessWidget {                                       // StatelessWidget: Değişmeyen ana uygulama yapısı
  const MyApp({super.key});                                                // Constructor: key parametresi ile widget'ı tanımlıyoruz

  // Bu widget uygulamanın kök yapısıdır
  @override
  Widget build(BuildContext context) {                                     // Widget'ın nasıl oluşturulacağını tanımlıyoruz
    return MaterialApp(                                                     // Material Design tabanlı uygulama oluşturuyoruz
      title: 'Flutter Demo',                                                // Uygulama başlığı (task manager'da görünür)
      debugShowCheckedModeBanner: false,                                   // Debug banner'ı gizliyoruz (production görünümü için)
      home: const SpechToTextPage(),                                        // Uygulama açıldığında gösterilecek ana sayfa
    );
  }
}

