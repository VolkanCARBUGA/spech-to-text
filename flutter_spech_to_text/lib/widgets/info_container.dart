import 'package:flutter/material.dart';

class InfoContainer extends StatelessWidget {
  const InfoContainer({
    super.key,
    required this.title,
    required this.description,
    required this.size,
  });

  final String title;
  final String description;
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
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(
          8,
        ),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          SizedBox(height: size.height * 0.01),
          Text(description),
        ],
      ),
    );
  }
}