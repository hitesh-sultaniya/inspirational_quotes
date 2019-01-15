import 'dart:async';
import 'package:Quotes/ModalProgressHud.dart';
import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'models/QuoteModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'models/UserData.dart';
import 'package:page_indicator/page_indicator.dart';

class QuotesDetailScreen extends StatefulWidget {

  List<QuoteModel> listCollection;
  int seletedIndex;
  QuotesDetailScreen(this.listCollection,this.seletedIndex);
  @override
  _QuotesDetailScreenState createState() => _QuotesDetailScreenState();
}

class _QuotesDetailScreenState extends State<QuotesDetailScreen> {

  Icon likeIcon = Icon(Icons.favorite_border);
  bool isProgressRunning = false;
  bool isDataLoading = true;
  QuoteModel selectedQuote;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<QuerySnapshot> subscription;
  StreamSubscription<FirebaseUser> subscriptionUser;
  final CollectionReference collectionReference = Firestore.instance.collection("dailyquotes");
  Timer _timer;
  @override
  void initState(){
    super.initState();

    subscriptionUser = FirebaseAuth.instance.onAuthStateChanged.listen((onData){
      if (onData != null) {
        UserData.fireBaseUser = onData;
      }
      setUpCollectionLoad();
    });
  }

  void setUpCollectionLoad() async {
    subscription = collectionReference.where('isUser',isEqualTo: false).orderBy('likeCount',descending: true).snapshots().listen((onData){
      String userId = '';
      if (UserData.fireBaseUser != null) {
        userId = UserData.fireBaseUser.uid;
      }
      setState(() {
        isDataLoading = true;
      });
      widget.listCollection = List();
      onData.documents.forEach((document){
        QuoteModel quoteItem = QuoteModel();
        quoteItem.id = document.data['id'];
        quoteItem.author = document.data['author'];
        quoteItem.quote = document.data['quote'];
        quoteItem.users = document.data['Users'];
        if (userId != '' && document.data["Users"].contains(userId)) {
          quoteItem.isLiked = true;
        }
        else
        {
          quoteItem.isLiked = false;
        }
        widget.listCollection.add(quoteItem);
      });
      _timer = new Timer(const Duration(milliseconds: 400), () {
        setState(() {
          isDataLoading = false;
        });
      });
    });
  }

  @override
  void dispose(){
    super.dispose();
    subscription?.cancel();
    subscriptionUser?.cancel();
    _timer?.cancel();
  }

  void signIN() async {
    FirebaseAuth.instance.currentUser().then((onValue) {
      if (onValue != null) {
        UserData.googleSignIn.signOut().then((gSA) {
          FirebaseAuth.instance.signOut();
        }).whenComplete(() {
          setState(() {
            UserData.fireBaseUser = null;
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
              child: new Text('Sign In',style: TextStyle(fontWeight: FontWeight.bold,color: Color(0xff075E54),fontSize: 20.0)),
              onPressed: () {
                signIN();
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text('Cancel',style: TextStyle(fontWeight: FontWeight.bold,color: Color(0xff075E54),fontSize: 20.0)),
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
        int quoteId = selectedQuote.id;
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
          "quotes": [selectedQuote.id],
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
        .where('id', isEqualTo: selectedQuote.id)
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
    return Scaffold(
      appBar: AppBar(title: Text("Quotes"),),
      body: ModalProgressHUD(
        inAsyncCall:isProgressRunning,
        child: PageIndicatorContainer(
          padding: EdgeInsets.only(bottom: 90),
          length: 3,
          align: IndicatorAlign.bottom,
          indicatorSelectorColor: Color.fromRGBO(0,0,0,0.0),
          indicatorColor:Color(0xff075E54),
          pageView: PageView.builder(
              controller: PageController(
                  initialPage: widget.seletedIndex
              ),
              itemCount: widget.listCollection.length,
              itemBuilder: (context,index){
                return Column(
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
                            '" ${widget.listCollection[index].quote} "',
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
                          "- ${widget.listCollection[index].author}",
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
                          child: Icon(widget.listCollection[index].isLiked?Icons.favorite:Icons.favorite_border),
                          onPressed: (){
                            selectedQuote = widget.listCollection[index];
                            _signIn();
                          },
                        ),
                        RaisedButton(
                          padding: EdgeInsets.all(8.0),
                          textColor: Colors.white,
                          color: Colors.green,
                          child: Icon(Icons.share),
                          onPressed: () {
                            Share.share("https://bit.ly/2QbBSgc\n${widget.listCollection[index].quote}\nby ${widget.listCollection[index].author}");
                          },
                        )
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 30.0),
                    ),
                    Center(
                      child: Text(
                        'Swipe Left or Right',
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.red,
                          fontStyle: FontStyle.italic,
                          fontFamily: "Merriweather",
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              }),
        ),
      )
    );
  }
}
