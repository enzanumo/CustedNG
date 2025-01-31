import 'package:custed2/constants.dart';
import 'package:flutter/material.dart';

class HomeCard extends StatelessWidget {
  HomeCard(
      {this.title,
      this.content,
      this.trailing = false,
      this.padding = 15,
      this.borderRadius = 7});

  HomeCard.loading({
    this.title = const Center(),
    this.content = const Center(child: CircularProgressIndicator()),
    this.trailing = false,
    this.padding = 15,
    this.borderRadius = 7,
  });

  final Widget title;
  final Widget content;
  final bool trailing;
  final double padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 3.0,
        shape: roundShape,
        clipBehavior: Clip.antiAlias,
        semanticContainer: false,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Flexible(child: _buildContent(context)),
            if (trailing) Icon(Icons.keyboard_arrow_right),
            if (trailing) SizedBox(width: 7),
          ],
        ));
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null) _buildTitle(context),
          if (title != null) SizedBox(height: 5),
          if (content != null) content,
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        title,
      ],
    );
  }
}
