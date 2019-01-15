import 'package:flutter/material.dart';
import 'DailyQuote.dart';
import 'CollectionList.dart';
import 'MyQuoteList.dart';
import 'dart:async';
import 'models/UserData.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:launch_review/launch_review.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';

const adUnitIdBanner = "ca-app-pub-7650945113243356/9987806249";
//const adUnitIdBanner = "ca-app-pub-7650945113243356/5835453917";
const appID = "ca-app-pub-7650945113243356~5062782624";
const privacyUrl = 'https://lemontreeapps.github.io/privacy.html';
const playUrl = 'https://play.google.com/store/apps/developer?id=Incognito+Apps';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  MobileAdTargetingInfo targetingInfo = new MobileAdTargetingInfo();
  BannerAd _bannerAd;
  TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DailyQuote dailyQuote = DailyQuote();
  final MyQuoteList myQuoteList = MyQuoteList();
  final CollectionList collectionList = CollectionList();
  StreamSubscription<ConnectivityResult> _connectivitySubscription;
  StreamSubscription<FirebaseUser> subscriptionUser;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  String signCaption = "Sign In";

  BannerAd createBannerAd() {
    return new BannerAd(
      adUnitId: adUnitIdBanner,
      size: AdSize.smartBanner,
      targetingInfo: targetingInfo,
      listener: (MobileAdEvent event) {
        print("BannerAd event $event");
      },
    );
  }


  @override
  void initState() {
    super.initState();
    firebaseCloudMessagingListeners();
    _tabController = new TabController(vsync: this, length: 3);
    FirebaseAuth.instance.currentUser().then((onValue) {
      if (onValue != null) {
        setState(() {
          UserData.fireBaseUser = onValue;
          signCaption = "Sign Out";
        });
      } else {
        setState(() {
          signCaption = "Sign In";
        });
      }
    });
    FirebaseAdMob.instance.initialize(appId: appID);
    _bannerAd = createBannerAd()
      ..load()
      ..show().then((onValue) {
        if (onValue) {
          setState(() {
            UserData.isAdShowing = true;
          });
        } else {
          setState(() {
            UserData.isAdShowing = false;
          });
        }
      });
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      setState(() {
        if (result == ConnectivityResult.none) {
          _showConnectivityAlert();
        } 
      });
    });
    subscriptionUser = FirebaseAuth.instance.onAuthStateChanged.listen((onData){
      if (onData != null) {
        setState(() {
          UserData.fireBaseUser = onData;
          signCaption = "Sign Out";
        });
      } else {
        setState(() {
          signCaption = "Sign In";
        });
      }
    });
    displayRateAppDialogue();
  }

  void displayRateAppDialogue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String lastDate = prefs.getString("LastRate");
    if(lastDate != null && DateTime.now().difference(DateTime.parse(lastDate)).inHours >= 12)
    {
        _showRateAlert();
        await prefs.setString("LastRate", DateTime.now().toString());
    }
    else if (lastDate == null){
      await prefs.setString("LastRate", DateTime.now().toString());
    }
  }

  Future<Null> _showRateAlert() async {
    return showDialog<Null>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return new AlertDialog(
          content: new SingleChildScrollView(
            child: new ListBody(
              children: <Widget>[
                new Text('Loving or Getting Inspired by Quotes, Help us by Rating App.',style: TextStyle(fontWeight: FontWeight.bold,color: Color(0xff075E54),fontSize: 18.0)),
              ],
            ),
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text('Rate Now',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.red,fontSize: 17.0)),
              onPressed: () {
                LaunchReview.launch();
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text('Cancel',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.red,fontSize: 17.0)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    subscriptionUser.cancel();
    _tabController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void firebaseCloudMessagingListeners() {
    _firebaseMessaging.getToken().then((token) {
      print(token);
    });

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print('on message $message');
      },
      onResume: (Map<String, dynamic> message) async {
        print('on resume $message');
      },
      onLaunch: (Map<String, dynamic> message) async {
        print('on launch $message');
      },
    );
  }

  Future<Null> _showConnectivityAlert() async {
    return showDialog<Null>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text('Network Error',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xff075E54),
                  fontSize: 20.0)),
          content: new SingleChildScrollView(
            child: new ListBody(
              children: <Widget>[
                new Text('Please enable mobile data or wifi to continue.',
                    style: TextStyle(color: Color(0xff075E54), fontSize: 15.0)),
              ],
            ),
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text('OK',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xff075E54),
                      fontSize: 20.0)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void signOut() async {
    FirebaseAuth.instance.currentUser().then((onValue) {
      if (onValue != null) {
        UserData.googleSignIn.signOut().then((gSA) {
          FirebaseAuth.instance.signOut();
        }).whenComplete(() {
          setState(() {
            UserData.fireBaseUser = null;
            signCaption = "Sign In";
          });
        }).catchError((onError) {
          showSnackBar(
              "Something went wrong,Please try, Please try again later!");
        });
      } else {
        UserData.googleSignIn.signIn().then((googleSignInAccount) {
          googleSignInAccount.authentication.then((gSA) {
            _auth
                .signInWithGoogle(
                    idToken: gSA.idToken, accessToken: gSA.accessToken)
                .then((user) {
              setState(() {
                UserData.fireBaseUser = user;
                signCaption = "Sign Out";
              });
            }).catchError((onError) {
              showSnackBar(
                  "Something went wrong,Please try, Please try again later!");
            });
          }).catchError((onError) {
            showSnackBar(
                "Something went wrong,Please try, Please try again later!");
          });
        }).catchError((onError) {
          showSnackBar(
              "Something went wrong,Please try, Please try again later!");
        });
      }
    }).catchError((onError) {
      showSnackBar("Something went wrong,Please try, Please try again later!");
    });
  }

  void showSnackBar(String message) {
    final snackBar = SnackBar(content: Text(message));
    Scaffold.of(context).showSnackBar(snackBar);
  }

  void _launchPrivacyURL() async {
    if (await canLaunch(privacyUrl)) {
      await launch(privacyUrl);
    } else {
      throw 'Could not launch $privacyUrl';
    }
  }

  void _launchPlayAccount() async {
    if (await canLaunch(privacyUrl)) {
      await launch(playUrl);
    } else {
      throw 'Could not launch $playUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child:Scaffold(
        appBar: AppBar(
          title: Text("Inspirational Quotes"),
          elevation: 0.7,
          actions: <Widget>[
            FlatButton(
                child: Text(
                  signCaption,
                  textScaleFactor: 1.25,
                ),
                onPressed: signOut,
                textColor: Colors.white),
            PopupMenuButton(
                onSelected: (String str) {
                  switch (str) {
                    case "Privacy Policy":
                      {
                        _launchPrivacyURL();
                      }
                      break;
                    case "Rate App":
                      {
                        LaunchReview.launch();
                      }
                      break;
                    case "Share App":
                      {
                        Share.share(
                            "Hey, Check out new inspirational quotes app\nhttps://bit.ly/2QbBSgc\nFor great inspiring quotes.");
                      }
                      break;
                    case "More Apps":
                      {
                        _launchPlayAccount();
                      }
                      break;
                    default:
                  }
                },
                itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<String>>[
                  PopupMenuItem(
                    child: Text(
                      'Privacy Policy',
                      textScaleFactor: 1.25,
                      style: TextStyle(
                          color: Color(0xff075E54),
                          fontWeight: FontWeight.bold),
                    ),
                    value: 'Privacy Policy',
                  ),
                  PopupMenuItem(
                    child: Text(
                      'Rate App',
                      textScaleFactor: 1.25,
                      style: TextStyle(
                          color: Color(0xff075E54),
                          fontWeight: FontWeight.bold),
                    ),
                    value: 'Rate App',
                  ),
                  PopupMenuItem(
                    child: Text(
                      'Share App',
                      textScaleFactor: 1.25,
                      style: TextStyle(
                          color: Color(0xff075E54),
                          fontWeight: FontWeight.bold),
                    ),
                    value: 'Share App',
                  ),
                  PopupMenuItem(
                    child: Text(
                      'More Apps',
                      textScaleFactor: 1.25,
                      style: TextStyle(
                          color: Color(0xff075E54),
                          fontWeight: FontWeight.bold),
                    ),
                    value: 'More Apps',
                  ),
                  //com.lemontreeapps.inspirationalquotes
                ])
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            tabs: <Widget>[
              Tab(text: "DAILY QUOTE"),
              Tab(text: "COLLECTION"),
              Tab(
                text: "FAVOURITES",
              )
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: <Widget>[
            dailyQuote,
            collectionList,
            myQuoteList,
          ],
        ),
      )
    );
  }
}
