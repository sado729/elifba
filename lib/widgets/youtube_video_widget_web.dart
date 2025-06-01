import 'package:flutter/material.dart';

class YoutubeVideoWidget extends StatelessWidget {
  final String embedUrl;
  const YoutubeVideoWidget({required this.embedUrl, super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Youtube videosu yalnız mobil applikasiyada göstərilir.',
        style: TextStyle(color: Colors.black),
      ),
    );
  }
}
