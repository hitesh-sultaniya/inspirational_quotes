import 'package:flutter/material.dart';

class ModalProgressHUD extends StatelessWidget {
  final Widget _child;
  final bool _inAsyncCall;
  final double opacity;
  final Color color;
  final Widget progressIndicator;
  final Offset offset;

  ModalProgressHUD({
    Key key,
    @required child,
    @required inAsyncCall,
    this.opacity = 0.0,
    this.color = Colors.grey,
    this.progressIndicator = const LinearProgressIndicator(),
    this.offset,
  })  : assert(child != null),
        assert(inAsyncCall != null),
        _child = child,
        _inAsyncCall = inAsyncCall,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> widgetList = new List<Widget>();
    widgetList.add(_child);
    Widget layOutProgressIndicator = new Container(child: progressIndicator);
    if (offset != null) {
      layOutProgressIndicator = new Positioned(
        child: progressIndicator,
        left: offset.dx,
        top: offset.dy,
      );
    }
    if (_inAsyncCall) {
      final modal = [
        new Opacity(
          opacity: opacity,
          child: new ModalBarrier(dismissible: false, color: color),
        ),
        layOutProgressIndicator
      ];
      widgetList.addAll(modal);
    }
    return new Stack(
      children: widgetList,
    );
  }
}
