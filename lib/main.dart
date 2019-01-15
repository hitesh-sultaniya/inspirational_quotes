import 'package:flutter/material.dart';
import 'HomeScreen.dart';
import 'SplashScreen.dart';
import 'package:Quotes/QuotesDetailScreen.dart';

var routes = <String, WidgetBuilder>{
  "/HomeScreen": (BuildContext context) => HomeScreen(),
};

void main() {
  runApp(new MaterialApp(
      title: 'Inspirational Quotes',
      theme: new ThemeData(
        primaryColor: new Color(0xff075E54),
        accentColor: new Color(0xff25D366),
      ),
      debugShowCheckedModeBanner: false,
      home: new SplashScreen(),
      routes: routes));
}
