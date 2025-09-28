import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
class SpeechToTextProvider extends ChangeNotifier {
  final record = AudioRecorder();
  bool isRecording = false;
  String transcription = "";
  String? errorMessage;
  String? currentRecordingPath;
  String detectedLanguage="";
  double? languageProbability;
  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
  Future<String> getFilePath() async {
    try {
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().day;
      final fileName = "audio_$timestamp.m4a";
      final filePath = "${dir.path}/$fileName";
      final file = File(filePath);
      await file.parent.create(recursive: true);
      return filePath;
    } catch (e) {
      throw Exception("Dosya yolu oluşturulamadı: $e");
    }
  }
  Future<bool> _ensurePermission() async {
    final has = await record.hasPermission();
    return has;
  }
  Future<void> startRecording() async {
    try {
      clearError();
      
      transcription = "";
      detectedLanguage = "";
      languageProbability = null;
      
      if (!await _ensurePermission()) {
        throw Exception("Mikrofon izni verilmedi. Lütfen ayarlardan izin verin.");
      } 
      await _startRecordingInternal();
    } catch (e) {
      if (errorMessage == null) {
        errorMessage = "Kayıt başlatma hatası: $e";   
        debugPrint("Kayıt başlatma hatası: $e");
        notifyListeners();
      }
      rethrow;
    }
  }
  Future<void> _startRecordingInternal() async {
    try {
      final path = await getFilePath();
      currentRecordingPath = path;
      final file = File(path);
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      await record.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: path,
      );
      isRecording = true;
      notifyListeners();
    } catch (e) {
      if (e.toString().contains("permission")) {
        throw Exception("Mikrofon izni verilmedi. Lütfen izin verin.");
      }
      if (e.toString().contains("ENOENT") || e.toString().contains("No such file")) {
        throw Exception("Kayıt dosyası oluşturulamadı. Uygulama izinlerini kontrol edin.");
      }
      throw Exception("Kayıt başlatılamadı: $e");
    }
  }
  Future<void> stopRecording() async {
    try {
      if (!isRecording) {
        return;
      }
      final path = await record.stop();
      isRecording = false;
      notifyListeners();
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          final fileSize = await file.length();
          if (fileSize > 0) {
            await sendToApi(file);
          } else {
            throw Exception("Kayıt dosyası boş (0 bytes)");
          }
        } else {
          throw Exception("Kayıt dosyası bulunamadı: $path");
        }
      } else {
        throw Exception("Kayıt dosyası oluşturulamadı");
      }
    } catch (e) {
      isRecording = false;
      notifyListeners();
      rethrow;
    }
  }
  Future<void> sendToApi(File audioFile) async {
    try {
      var uri = Uri.parse("http://192.168.0.3:8000/transcribe");
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', audioFile.path));
      var response = await request.send();
      var respStr = await response.stream.bytesToString();
      var jsonResp = jsonDecode(respStr);
      final lang = jsonResp["language"];
      final prob = jsonResp["language_probability"];
      final text = jsonResp["transcription"];
      detectedLanguage = lang is String ? lang : "";
      languageProbability = prob is num ? prob.toDouble() : null;
      transcription = text is String ? text : "Metin bulunamadı";
      debugPrint("Dil: $detectedLanguage (${languageProbability?.toStringAsFixed(2) ?? '-'})");
      debugPrint("Transkripsiyon: $transcription");
      notifyListeners();
    } catch (e) {
      transcription = "API hatası: $e";
      debugPrint("API hatası: $e");
      notifyListeners();
      rethrow;
    }
  }
  @override
  void dispose() {
    record.dispose();
    super.dispose();
  }
}
