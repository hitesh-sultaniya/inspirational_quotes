import 'dart:async';
import 'package:flutter/material.dart';
import 'utils/CustomNavigator.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => new _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  startTime() async {
    var _duration = new Duration(seconds: 2);
    return new Timer(_duration, navigationPage);
  }

  void navigationPage() {
    TourNavigator.goToHome(context);
  }

  @override
  void initState() {
    super.initState();
    startTime();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        body: new Center(
      child: Text(
        '"Welcome to Inspirational Quotes"',
        style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xff075E54),
            fontSize: 50.0),
        textAlign: TextAlign.center,
      ),
    ));
  }
}
