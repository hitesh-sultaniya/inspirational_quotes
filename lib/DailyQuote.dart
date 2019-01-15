import 'dart:async';
import 'package:share/share.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/UserData.dart';
import 'ModalProgressHud.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:launch_review/launch_review.dart';

class DailyQuote extends StatefulWidget {
  @override
  _DailyQuoteState createState() => _DailyQuoteState();
  
}

class _DailyQuoteState extends State<DailyQuote> {
  String dailyQuote = "";
  String quoteAuthor = "";
  StreamSubscription<QuerySnapshot> subscription;
  StreamSubscription<QuerySnapshot> subscriptionAd;
  StreamSubscription<FirebaseUser> subscriptionUser;
  final CollectionReference collectionReference =
      Firestore.instance.collection("dailyquotes");
  final CollectionReference advertiseReference =
  Firestore.instance.collection("advertise");
  DocumentSnapshot advertiseData;
  DocumentSnapshot quoteData;
  Icon likeIcon = Icon(Icons.favorite_border);
  bool isProgressRunning = false;
  bool isDataLoading = true;

   void refreshQuoteState(){
    setState(() {
        FirebaseAuth.instance.currentUser().then((user) {
          UserData.fireBaseUser = user;
          if (UserData.fireBaseUser != null) {
            bool isLiked =
                quoteData["Users"].contains(UserData.fireBaseUser.uid);
            if (isLiked) {
              likeIcon = Icon(Icons.favorite);
            } else {
              likeIcon = Icon(Icons.favorite_border);
            }
          } else {
            likeIcon = Icon(Icons.favorite_border);
          }
        }).catchError((onError) => print(onError));
      });
  }

  @override
  void initState() {
    super.initState();

    subscriptionUser = FirebaseAuth.instance.onAuthStateChanged.listen((onData){
      if (onData != null) {
        UserData.fireBaseUser = onData;
      }
      refreshQuoteState();
    });

    subscription = collectionReference
        .orderBy("id", descending: true)
        .limit(1)
        .snapshots()
        .listen((onData) {
      quoteData = onData.documents.single;
      setState(() {
        dailyQuote = quoteData["quote"];
        quoteAuthor = quoteData["author"];
        FirebaseAuth.instance.currentUser().then((user) {
          UserData.fireBaseUser = user;
          if (UserData.fireBaseUser != null) {
            bool isLiked =
                quoteData["Users"].contains(UserData.fireBaseUser.uid);
            if (isLiked) {
              likeIcon = Icon(Icons.favorite);
            } else {
              likeIcon = Icon(Icons.favorite_border);
            }
          } else {
            likeIcon = Icon(Icons.favorite_border);
          }
        }).catchError((onError) => print(onError));
        isDataLoading = false;
      });
    });

    subscriptionAd = advertiseReference.limit(1).snapshots().listen((onData) {
      setState(() {
        advertiseData = onData.documents.single;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    subscription?.cancel();
    subscriptionUser?.cancel();
    subscriptionAd?.cancel();
  }

  

Future<Null> _showSignInAlert() async {
  return showDialog<Null>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return new AlertDialog(
        content: new SingleChildScrollView(
          child: new ListBody(
            children: <Widget>[
              new Text('Please sign in first to continue.',style: TextStyle(fontWeight: FontWeight.bold,color: Color(0xff075E54),fontSize: 20.0)),
            ],
          ),
        ),
        actions: <Widget>[
          new FlatButton(
            child: new Text('OK',style: TextStyle(fontWeight: FontWeight.bold,color: Color(0xff075E54),fontSize: 25.0)),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

  Future _signIn() async {
    if (isProgressRunning) {
      showSnackBar("Please wait...");
      return;
    }
    setState(() {
      isProgressRunning = true;
    });

    FirebaseAuth.instance.currentUser().then((onValue) {
      if (onValue != null) {
        getQuote(onValue);
      } else {
        setState(() {
            isProgressRunning = false;      
        });
        _showSignInAlert();  
      }
    }).catchError((onError) {
      showSnackBar(
              "Something went wrong,Please try, Please try again later!");
    });
  }

  void getQuote(FirebaseUser user) async {
    UserData.fireBaseUser = user;
    DocumentReference documentReferenceUser =
        Firestore.instance.document("dailyquotes/${UserData.fireBaseUser.uid}");
    documentReferenceUser.get().then((onValue) {
      if (onValue.exists) {
        List quoteList = List.of(onValue.data["quotes"], growable: true);
        int quoteId = quoteData.data["id"];
        bool isLiked;
        if (quoteList.contains(quoteId)) {
          quoteList.remove(quoteId);
          isLiked = false;
        } else {
          isLiked = true;
          quoteList.add(quoteId);
        }
        documentReferenceUser.updateData({"quotes": quoteList}).then((onValue) {
          if (isLiked) {
            setState(() {
              likeIcon = Icon(Icons.favorite);
            });
            updateLikeCount(true);
          } else {
            setState(() {
              likeIcon = Icon(Icons.favorite_border);
            });
            updateLikeCount(false);
          }
        }).catchError((onError) {
          setState(() {
            isProgressRunning = false;      
          });
          showSnackBar(
              "Something went wrong,Please try, Please try again later!");
        });
      } else {
        documentReferenceUser.setData({
          "quotes": [quoteData.data["id"]],
          'isUser': true,
          'Email-id': UserData.fireBaseUser.email,
          'Name': UserData.fireBaseUser.displayName
        }).whenComplete(() {
          setState(() {
            likeIcon = Icon(Icons.favorite);
          });
          updateLikeCount(true);
        }).catchError((onError) {
          setState(() {
            isProgressRunning = false;      
          });
          showSnackBar(
              "Something went wrong,Please try, Please try again later!");
        });
      }
    }).catchError((onError) {
      setState(() {
            isProgressRunning = false;      
      });
      showSnackBar("Something went wrong,Please try, Please try again later!");
    });
  }

  void showSnackBar(String message) {
    Fluttertoast.showToast(
        msg: "$message",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIos: 1
    );
  }

  void updateLikeCount(bool isIncrement) {
    collectionReference
        .where('id', isEqualTo: quoteData.data['id'])
        .limit(1)
        .getDocuments()
        .then(((onValue) {
      final DocumentReference postRef = Firestore.instance
          .document('dailyquotes/${onValue.documents.single.documentID}');
      Firestore.instance.runTransaction((Transaction tx) async {
        DocumentSnapshot postSnapshot = await tx.get(postRef);
        if (postSnapshot.exists) {
          List users = List.from(postSnapshot.data['Users'], growable: true);
          if (isIncrement) {
            if (!users.contains(UserData.fireBaseUser.uid)) {
              users.add(UserData.fireBaseUser.uid);
            }
            await tx.update(postRef, <String, dynamic>{
              'likeCount': postSnapshot.data['likeCount'] + 1,
              'Users': users
            });
          } else {
            if (users.contains(UserData.fireBaseUser.uid)) {
              users.remove(UserData.fireBaseUser.uid);
            }
            await tx.update(postRef, <String, dynamic>{
              'likeCount': postSnapshot.data['likeCount'] - 1,
              'Users': users
            });
          }
          setState(() {
            isProgressRunning = false;      
          });
        }
      }).whenComplete(() {
        setState(() {
            isProgressRunning = false;      
          });
        if (isIncrement) {
          showSnackBar("Added to favourites successfully!");
        } else {
          showSnackBar("Remove from favourites successfully!");
        }
      }).catchError((onError) {
        setState(() {
            isProgressRunning = false;      
          });
        showSnackBar(
            "Something went wrong,Please try, Please try again later!");
      });
    })).whenComplete(() {
      setState(() {
            isProgressRunning = false;      
          });
    }).catchError((onError) {
      setState(() {
            isProgressRunning = false;      
          });
      showSnackBar("Something went wrong,Please try, Please try again later!");
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isDataLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    else
    {
      return ModalProgressHUD(
      inAsyncCall: isProgressRunning,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 90.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Card(
              elevation:5.0,
              margin: EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
              child: Container(
                height: 200.0,
                padding:EdgeInsets.only(top: 0.0, left: 0.0, right: 4.0),
                child: Center(
                  child: Text(
                    '" $dailyQuote "',
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 23.0,
                      color: Color(0xff075E54),
                      fontStyle: FontStyle.italic,
                      fontFamily: "Merriweather",
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Container(
                padding: EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
                child: Text(
                  "- $quoteAuthor",
                  style: TextStyle(
                    fontSize: 25.0,
                    color: Colors.red,
                    fontStyle: FontStyle.italic,
                    fontFamily: "LobsterTwo",
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                )),
            Padding(
              padding: EdgeInsets.only(top: 20.0),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                RaisedButton(
                  padding: EdgeInsets.all(8.0),
                  textColor: Colors.white,
                  color: Colors.green,
                  child: likeIcon,
                  onPressed: _signIn,
                ),
                RaisedButton(
                  padding: EdgeInsets.all(8.0),
                  textColor: Colors.white,
                  color: Colors.green,
                  child: Icon(Icons.share),
                  onPressed: () {
                    Share.share("https://bit.ly/2QbBSgc\n$dailyQuote\nby $quoteAuthor");
                  },
                )
              ],
            ),
            Padding(
              padding: EdgeInsets.only(top: 5.0,bottom: 5.0),
            ),
            Card(
              elevation: 5.0,
              margin: EdgeInsets.symmetric(horizontal: 10.0),
              child: ListTile(
                leading: advertiseData != null ? Image.network(advertiseData["iconUrl"],width: 50,) : Image.asset("icons/Wallyfy.png",width: 50.0,),
                title: Text(advertiseData != null ? advertiseData["title"] : "HD Wallpaper and Photos",textScaleFactor:1.05,style: TextStyle(fontSize: 15.0, color: Color(0xff075E54),fontFamily: "Merriweather")),
                  subtitle: new Text(advertiseData != null ? advertiseData['subtitle'] : "Tap to Download Now", textAlign: TextAlign.right,style:TextStyle(fontSize: 13.0, color: Colors.red,fontStyle: FontStyle.italic,fontFamily: "Merriweather")),
                onTap: (){
                  LaunchReview.launch(androidAppId: advertiseData != null ? advertiseData["bundleId"] : "com.lemontreeapps.wallyfy");
                },
              ),
            )
          ],
        ),
      )
    );
    }
  }
}
