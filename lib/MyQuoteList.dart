import 'dart:async';
import 'package:share/share.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/UserData.dart';
import 'models/QuoteModel.dart';
import 'ModalProgressHud.dart';
import 'package:fluttertoast/fluttertoast.dart';


class MyQuoteList extends StatefulWidget {
  @override
  _MyQuoteListState createState() => _MyQuoteListState();
}

class _MyQuoteListState extends State<MyQuoteList> {

  StreamSubscription<QuerySnapshot> subscription;
  StreamSubscription<FirebaseUser> subscriptionUser;
  final CollectionReference collectionReference = Firestore.instance.collection("dailyquotes");
  List<QuoteModel> listQuoteCollection = List();
  QuoteModel selectedQuote;
  Icon likeIcon = Icon(Icons.favorite_border);
  bool isProgressRunning = false;
  bool isDataLoading = true;
  Timer _timer;

  @override
  void initState(){
    super.initState();
    subscriptionUser = FirebaseAuth.instance.onAuthStateChanged.listen((onData){
      if (onData != null) {
        UserData.fireBaseUser = onData;
      }
      getUserQuotes();
    });
    getUserQuotes();
  }

  void getUserQuotes() async {
    String userId = '';
    if (UserData.fireBaseUser != null) {
        userId = UserData.fireBaseUser.uid;
    }
    subscription = collectionReference.where('Users',arrayContains:userId).orderBy('likeCount',descending: true).snapshots().listen((onData){
      
        setState(() {
              isDataLoading = true;    
        });
      listQuoteCollection = List(); 
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
            listQuoteCollection.add(quoteItem);
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

    if (isDataLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    else
    {
      return ModalProgressHUD(
      inAsyncCall: isProgressRunning,
      child:Container(
      child: listQuoteCollection.length == 0 ?
      Center(
        child:Card(
          elevation:5.0,
          margin: EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
          child: Container(
          height: 200.0,
          child: Center(
            child: Text(
              '"Please sign in and mark atleast one quote as favourite!"',
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
        ) : ListView.builder(
        padding: EdgeInsets.only(bottom: UserData.isAdShowing?90.0:5.0),
        itemCount: listQuoteCollection.length,
          itemBuilder: (context,index) {
            return Card(
              elevation: 5.0,
              child: new ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 5.0,vertical: 5.0),
                title: new Text(listQuoteCollection[index].quote,textScaleFactor:1.05,style: TextStyle(fontSize: 15.0, color: Color(0xff075E54),fontFamily: "Merriweather")),
                subtitle: new Text(listQuoteCollection[index].author, textAlign: TextAlign.right,style:TextStyle(fontSize: 15.0, color: Colors.red,fontStyle: FontStyle.italic
             ,fontFamily: "LobsterTwo")),
             trailing: Column(
               children: <Widget>[
                 IconButton(
                   icon: Icon(Icons.delete),
                   onPressed: (){
                     selectedQuote = listQuoteCollection[index];
                     _signIn();
                   },
                   color: Color(0xff075E54),
                 ),
                 IconButton(
                   icon: Icon(Icons.share),
                   onPressed: (){
                     Share.share("https://bit.ly/2QbBSgc\n${listQuoteCollection[index].quote}\nby ${listQuoteCollection[index].author}");
                   },
                   color: Color(0xff075E54),
                 )
               ],
             ),
             ),
            );
          },
        ),
    )
    );
    }

  }
}