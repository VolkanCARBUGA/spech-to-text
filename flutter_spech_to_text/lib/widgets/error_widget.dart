import 'package:flutter/material.dart';
import 'package:flutter_spech_to_text/provider/spech_to_text_provider.dart';

class ErrorsWidget extends StatelessWidget {
  const ErrorsWidget({super.key, required this.provider, required this.size});

  final SpeechToTextProvider provider;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(
        size.width * 0.1,
      ),
      padding: EdgeInsets.all(
        size.width * 0.1,
      ),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(
          8,
        ),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red.shade700),
          SizedBox(width: size.width * 0.02),
          Expanded(
            child: Text(
              provider.errorMessage!,
              style: TextStyle(
                color: Colors.red.shade700,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade700),
            onPressed: () =>
                provider.clearError(),
          ),
        ],
      ),
    );
  }
}