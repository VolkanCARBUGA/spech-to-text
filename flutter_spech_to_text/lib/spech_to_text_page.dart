import 'package:flutter/material.dart';
import 'package:flutter_spech_to_text/provider/spech_to_text_provider.dart';
import 'package:flutter_spech_to_text/widgets/error_widget.dart';
import 'package:flutter_spech_to_text/widgets/info_container.dart';
import 'package:flutter_spech_to_text/widgets/record_button.dart';
import 'package:flutter_spech_to_text/widgets/recording_animation.dart';
import 'package:provider/provider.dart';
class SpechToTextPage extends StatelessWidget {
  const SpechToTextPage({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SpeechToTextProvider>(context);
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        centerTitle: true,
        title: const Text(
          'Speech to Text',
          style: TextStyle(
            fontSize: 40,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      floatingActionButton: Stack(
        alignment: Alignment.center,
        children: [
          if (provider.isRecording)
            RecordingPulse(size: size.width * 0.5, color: Colors.green),
          RecordButton(provider: provider, size: size),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (provider.errorMessage != null)
              ErrorsWidget(size: size, provider: provider),

            SizedBox(height: size.height * 0.05),
            if (provider.transcription.isNotEmpty)
              InfoContainer(
                size: size,
                title: 'Transkripsiyon Sonucu',
                description: provider.transcription,
              ),
            if (provider.detectedLanguage != null)
              InfoContainer(
                title: 'Konuşma Dili',
                description:
                    '${provider.detectedLanguage}:(${(provider.languageProbability ?? 0).toStringAsFixed(2)})',
                size: size,
              ),
          ],
        ),
      ),
    );
  }
}
