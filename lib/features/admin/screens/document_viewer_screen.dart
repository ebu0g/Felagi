import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentViewerScreen extends StatelessWidget {
  final String url;
  const DocumentViewerScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Pharmacy Document'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              messenger.showSnackBar(
                const SnackBar(content: Text('Could not open document')),
              );
            }
          },
          child: const Text('Open Document'),
        ),
      ),
    );
  }
}
