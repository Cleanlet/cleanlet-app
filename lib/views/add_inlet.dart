import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AddInletPage extends StatefulWidget {
  const AddInletPage({super.key});

  @override
  _AddInletPageState createState() => _AddInletPageState();
}

class _AddInletPageState extends State<AddInletPage> {
  late final WebViewController controller;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(
          'https://docs.google.com/forms/d/e/1FAIpQLSe4ISFYoUAdZ93AZw14SBwfqHoH4ShKLfVVXKKhCz-3ibXZjQ/viewform'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Add Inlet'),
        ),
        body: SafeArea(child: WebViewWidget(controller: controller)));
  }
}
