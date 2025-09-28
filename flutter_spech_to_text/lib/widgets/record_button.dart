import 'package:flutter/material.dart';
import 'package:flutter_spech_to_text/provider/spech_to_text_provider.dart';
import 'package:flutter_spech_to_text/widgets/error_widget.dart';

class RecordButton extends StatelessWidget {
  const RecordButton({
    super.key,
    required this.provider,
    required this.size,
  });

  final SpeechToTextProvider provider;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: Colors.green,
      onPressed: () async {
        try {
          if (provider.isRecording) {
            await provider.stopRecording();
          } else {
            await provider.startRecording();
          }
        } catch (e) {
          ErrorsWidget(size: size, provider: provider);
        }
      },
      child: Icon(
        provider.isRecording ? Icons.mic : Icons.mic_off,
        color: Colors.white,
        size: size.width * 0.1
      ),
    );
  }
}