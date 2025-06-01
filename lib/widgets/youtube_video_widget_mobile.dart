import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class YoutubeVideoWidget extends StatelessWidget {
  final String embedUrl;
  const YoutubeVideoWidget({required this.embedUrl, super.key});

  @override
  Widget build(BuildContext context) {
    return WebView(
      initialUrl: embedUrl,
      javascriptMode: JavascriptMode.unrestricted,
    );
  }
}
