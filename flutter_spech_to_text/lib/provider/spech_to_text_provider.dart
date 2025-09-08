import 'dart:io'; // Dosya işlemleri için (File, Platform)
import 'dart:convert'; // JSON işlemleri için (jsonDecode)
import 'package:flutter/material.dart'; // Flutter'ın temel bileşenleri (ChangeNotifier)
import 'package:record/record.dart'; // Ses kaydı için (AudioRecorder, RecordConfig)
import 'package:path_provider/path_provider.dart'; // Geçici dizin yolları için (getTemporaryDirectory)
import 'package:http/http.dart' as http; // HTTP istekleri için (MultipartRequest)
class SpeechToTextProvider extends ChangeNotifier { // ChangeNotifier: UI'ı güncellemek için state değişikliklerini bildirir
  final record = AudioRecorder(); // Mikrofon kaydı için AudioRecorder nesnesi
  bool isRecording = false; // Kayıt durumu: true = kayıt yapılıyor, false = kayıt yapılmıyor
  String transcription = ""; // API'den dönen transkripsiyon metni
  String? errorMessage; // Hata mesajı: null = hata yok, string = hata var
  String? currentRecordingPath; // Mevcut kayıt dosyasının yolu (private değişken)
  String? detectedLanguage; // Algılanan dil kodu (örn: "tr")
  double? languageProbability; // Dil olasılığı (0..1)
  void clearError() { // Hata mesajını sıfırlar ve UI'ı günceller
    errorMessage = null; // Hata mesajını null yap
    notifyListeners(); // UI'ı güncelle (Provider pattern)
  }
  Future<String> getFilePath() async { // Async fonksiyon: Geçici dizinde benzersiz dosya adı oluşturur
    try { // Hata yakalama bloğu başlangıcı
      final dir = await getTemporaryDirectory(); // Sistem geçici dizinini al (iOS: /tmp, Android: /data/data/.../cache)     
      final timestamp = DateTime.now().day; // Şu anki zamanı milisaniye cinsinden al
      final fileName = "audio_$timestamp.m4a"; // iOS/macOS uyumlu AAC konteyner
      final filePath = "${dir.path}/$fileName"; // Tam dosya yolu: "/tmp/audio_1703123456789.mp3"     
      final file = File(filePath); // File nesnesi oluştur
      await file.parent.create(recursive: true); // Ebeveyn dizini oluştur (recursive: alt dizinler de oluşturulur)      
      return filePath; // Oluşturulan dosya yolunu döndür
    } catch (e) { // Hata yakalama
      throw Exception("Dosya yolu oluşturulamadı: $e"); // Hata durumunda exception fırlat
    }
  }
  Future<bool> _ensurePermission() async { // Mikrofon izni kontrolü (record ile)
    final has = await record.hasPermission();
    return has;
  }
  Future<void> startRecording() async { // Async fonksiyon: Ses kaydını başlatır
    try { // Hata yakalama bloğu başlangıcı
      clearError(); // Önceki hata mesajlarını temizle
      
      // Önceki kayıt sonuçlarını temizle
      transcription = ""; // Transkripsiyon metnini temizle
      detectedLanguage = null; // Algılanan dili temizle
      languageProbability = null; // Dil olasılığını temizle
      
      if (!await _ensurePermission()) { // Mikrofon izni yoksa
        throw Exception("Mikrofon izni verilmedi. Lütfen ayarlardan izin verin."); // Hata fırlat
      } 
      await _startRecordingInternal(); // İç kayıt fonksiyonunu çağır     
    } catch (e) { // Hata yakalama
      if (errorMessage == null) { // Eğer henüz hata mesajı yoksa
        errorMessage = "Kayıt başlatma hatası: $e";   
        debugPrint("Kayıt başlatma hatası: $e"); // Hata mesajını ayarla
        notifyListeners(); // UI'ı güncelle
      }
      rethrow; // Hatayı yukarı fırlat (UI'da yakalanacak)
    }
  }
  Future<void> _startRecordingInternal() async { // Private async fonksiyon: Asıl kayıt işlemini yapar
    try { // Hata yakalama bloğu başlangıcı
      final path = await getFilePath(); // Geçici dosya yolu al
      currentRecordingPath = path; // Mevcut kayıt yolunu sakla      
      final file = File(path); // File nesnesi oluştur
      if (!await file.parent.exists()) { // Ebeveyn dizin yoksa
        await file.parent.create(recursive: true); // Dizini oluştur
      }     
      await record.start( // Kayıt başlat
        const RecordConfig( // Kayıt konfigürasyonu (iOS/macOS için uyumlu)
          encoder: AudioEncoder.aacLc, // AAC-LC geniş destekli
          sampleRate: 44100, // Yaygın destekli örnekleme hızı
          numChannels: 1, // Mono kayıt
        ),
        path: path, // Kayıt dosyasının yolu
      );      
      isRecording = true; // Kayıt durumunu true yap
      notifyListeners(); // UI'ı güncelle
    } catch (e) { // Hata yakalama
      if (e.toString().contains("permission")) { // İzin hatası
        throw Exception("Mikrofon izni verilmedi. Lütfen izin verin.");
      }     
      if (e.toString().contains("ENOENT") || e.toString().contains("No such file")) { // Dosya hatası
        throw Exception("Kayıt dosyası oluşturulamadı. Uygulama izinlerini kontrol edin.");
      }
      throw Exception("Kayıt başlatılamadı: $e"); // Genel hata
    }
  }
  Future<void> stopRecording() async { // Async fonksiyon: Kaydı durdurur ve API'ye gönderir
    try { // Hata yakalama bloğu başlangıcı
      if (!isRecording) { // Eğer kayıt yapılmıyorsa
        return; // Hiçbir şey yapma
      }    
      final path = await record.stop(); // Kaydı durdur ve dosya yolunu al
      isRecording = false; // Kayıt durumunu false yap
      notifyListeners(); // UI'ı güncelle
      if (path != null && path.isNotEmpty) { // Dosya yolu geçerliyse
        final file = File(path); // File nesnesi oluştur
        if (await file.exists()) { // Dosya varsa
          final fileSize = await file.length(); // Dosya boyutunu al        
          if (fileSize > 0) { // Dosya boş değilse
            await sendToApi(file); // API'ye gönder
          } else { // Dosya boşsa
            throw Exception("Kayıt dosyası boş (0 bytes)"); // Hata fırlat
          }
        } else { // Dosya yoksa
          throw Exception("Kayıt dosyası bulunamadı: $path"); // Hata fırlat
        }
      } else { // Dosya yolu geçersizse
        throw Exception("Kayıt dosyası oluşturulamadı"); // Hata fırlat
      }
    } catch (e) { // Hata yakalama
      isRecording = false; // Kayıt durumunu false yap
      notifyListeners(); // UI'ı güncelle
      rethrow; // Hatayı yukarı fırlat
    }
  }
  Future<void> sendToApi(File audioFile) async { // Async fonksiyon: Ses dosyasını API'ye gönderir
    try { // Hata yakalama bloğu başlangıcı
      var uri = Uri.parse("http://192.168.0.3:8000/transcribe"); // FastAPI backend adresi
      var request = http.MultipartRequest('POST', uri); // POST isteği ile multipart form data
      request.files.add(await http.MultipartFile.fromPath('file', audioFile.path)); // Ses dosyasını ekle
      var response = await request.send(); // HTTP isteğini gönder
      var respStr = await response.stream.bytesToString(); // Cevap stream'ini string'e çevir
      var jsonResp = jsonDecode(respStr); // JSON string'i parse et
      final lang = jsonResp["language"];
      final prob = jsonResp["language_probability"];
      final text = jsonResp["transcription"];
      detectedLanguage = lang is String ? lang : null;
      languageProbability = prob is num ? prob.toDouble() : null;
      transcription = text is String ? text : "Metin bulunamadı";
      debugPrint("Dil: ${detectedLanguage ?? '-'} (${languageProbability?.toStringAsFixed(2) ?? '-'})");
      debugPrint("Transkripsiyon: $transcription");
      notifyListeners(); // UI'ı güncelle
    } catch (e) { // Hata yakalama
      transcription = "API hatası: $e";       
      debugPrint("API hatası: $e"); // Hata mesajını transkripsiyon alanına yaz
      notifyListeners(); // UI'ı güncelle
      rethrow; // Hatayı yukarı fırlat
    }
  }
  @override
  void dispose() { // Widget dispose edildiğinde çağrılır
    record.dispose(); // AudioRecorder kaynaklarını temizle
    super.dispose(); // Parent dispose metodunu çağır
  }
}
