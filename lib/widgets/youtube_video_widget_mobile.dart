import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class YoutubeVideoWidget extends StatelessWidget {
  final String embedUrl;
  const YoutubeVideoWidget({required this.embedUrl, super.key});

  @override
  Widget build(BuildContext context) {
    // Əgər URL boşdursa və ya etibarlı deyilsə error message göstər
    final uri = Uri.tryParse(embedUrl);
    if (embedUrl.isEmpty || uri?.isAbsolute != true) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_call_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Video məzmunu hazırda mövcud deyil',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return WebViewWidget(
      controller:
          WebViewController()
            ..loadRequest(Uri.parse(embedUrl))
            ..setJavaScriptMode(JavaScriptMode.unrestricted),
    );
  }
}
