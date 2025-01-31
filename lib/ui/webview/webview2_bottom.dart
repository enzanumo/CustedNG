import 'dart:async';

import 'package:custed2/core/open.dart';
import 'package:flutter/material.dart';
import 'package:share_extend/share_extend.dart';

class Webview2BottomController extends ChangeNotifier {
  bool canGoBack = false;
  bool canGoForward = false;

  void setCanGoBack(bool value) {
    canGoBack = value;
    notifyListeners();
  }

  void setCanGoForward(bool value) {
    canGoForward = value;
    notifyListeners();
  }
}

class Webview2Bottom extends StatefulWidget {
  Webview2Bottom({
    this.controller,
    this.url,
    this.onGoBack,
    this.onGoForward,
  });

  final Future<Object> Function() url;

  final Webview2BottomController controller;

  final void Function() onGoBack;

  final void Function() onGoForward;

  @override
  _Webview2BottomState createState() => _Webview2BottomState();
}

String resolveUrl(Object url) {
  if (url is Uri) return url.toString();
  return url;
}

class _Webview2BottomState extends State<Webview2Bottom> {
  bool get canGoBack => widget.controller.canGoBack;
  bool get canGoForward => widget.controller.canGoForward;

  @override
  void initState() {
    widget.controller.addListener(onStateChanged);
    super.initState();
  }

  @override
  void dispose() {
    widget.controller.removeListener(onStateChanged);
    super.dispose();
  }

  void onStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: canGoBack ? widget.onGoBack?.call : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: canGoForward ? widget.onGoForward?.call : null,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              // var url = await webview.evalJavascript('window.location.href');
              final url = await widget.url();
              ShareExtend.share(resolveUrl(url), 'text');
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser, size: 26),
            onPressed: () async {
              // var url = await webview.evalJavascript('window.location.href');
              // if (url.length >= 2) {
              //   url = url.substring(1, url.length - 1);
              // }
              final url = await widget.url();
              print('open in browser: $url');
              openUrl(resolveUrl(url));
            },
          ),
        ],
      ),
    );
  }
}
