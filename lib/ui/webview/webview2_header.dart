import 'package:custed2/ui/webview/webview2_progress.dart';
import 'package:custed2/ui/widgets/navbar/navbar.dart';
import 'package:custed2/ui/widgets/navbar/navbar_middle.dart';
import 'package:flutter/material.dart';

class Webview2HeaderController with ChangeNotifier {
  String host = '...';
  String title = '加载中';
  bool isLoading = false;
  double progress = 0;

  void setUrl(String url) {
    host = Uri?.tryParse(url)?.host ?? url;
    notifyListeners();
  }

  void setTitle(String title) {
    this.title = title;
    notifyListeners();
  }

  void startLoad() {
    isLoading = true;
    progress = 0;
    notifyListeners();
  }

  void stopLoad() {
    isLoading = false;
    notifyListeners();
  }

  void setProgress(double progress) {
    this.progress = progress;
    notifyListeners();
  }
}

class Webview2Header extends StatefulWidget with PreferredSizeWidget {
  Webview2Header({this.controller, this.onClose, this.onReload});

  final void Function(BuildContext) onClose;

  final void Function(BuildContext) onReload;

  final Webview2HeaderController controller;

  @override
  _Webview2HeaderState createState() => _Webview2HeaderState();

  @override
  Size get preferredSize => AppBar().preferredSize;
}

class _Webview2HeaderState extends State<Webview2Header> {
  @override
  void initState() {
    widget.controller.addListener(onChanged);
    super.initState();
  }

  @override
  void dispose() {
    widget.controller.removeListener(onChanged);
    super.dispose();
  }

  void onChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        buildNavigationBar(context),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 3,
            child: Webview2Progress(
              isLoading: widget.controller.isLoading,
              progress: widget.controller.progress,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildNavigationBar(BuildContext context) {
    return NavBar.material(
      context: context,
      leading: Container(
        alignment: Alignment.centerLeft,
        width: 70,
        child: Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: GestureDetector(
            child: Icon(Icons.close),
            onTap: () => widget.onClose?.call(context),
          ),
        ),
      ),
      middle: NavbarMiddle(
        textAbove: widget.controller.title ?? '',
        textBelow: widget.controller.host ?? '',
      ),
      trailing: [
        Padding(
          padding: EdgeInsets.only(right: 8.0),
          child: GestureDetector(
            child: Icon(Icons.refresh),
            onTap: () => widget.onReload?.call(context),
          ),
        )
      ],
    );
  }
}
