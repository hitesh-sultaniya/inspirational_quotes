import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/UserData.dart';
import 'models/QuoteModel.dart';
import 'QuotesDetailScreen.dart';
import 'package:firebase_admob/firebase_admob.dart';

const adUnitIdFullScreen = "ca-app-pub-7650945113243356/4618983315";
const appID = "ca-app-pub-7650945113243356~5062782624";

class CollectionList extends StatefulWidget {
  @override
  _CollectionListState createState() => _CollectionListState();
}

class _CollectionListState extends State<CollectionList> {

  StreamSubscription<QuerySnapshot> subscription;
  StreamSubscription<FirebaseUser> subscriptionUser;
  final CollectionReference collectionReference = Firestore.instance.collection("dailyquotes");
  List<QuoteModel> listQuoteCollection = List();
  bool isDataLoading = true;
  Timer _timer;
  InterstitialAd fullAd;
  MobileAdTargetingInfo targetingInfo = new MobileAdTargetingInfo();


  @override
  void initState(){
    super.initState();

    subscriptionUser = FirebaseAuth.instance.onAuthStateChanged.listen((onData){
      if (onData != null) {
        UserData.fireBaseUser = onData;
      }
      setUpCollectionLoad();
    });

    setUpCollectionLoad();
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
    subscription?.cancel();
    subscriptionUser?.cancel();
    fullAd?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  InterstitialAd createInterstitialAd() {
    InterstitialAd fullAd = InterstitialAd(
        adUnitId: adUnitIdFullScreen,
        targetingInfo: targetingInfo,
        listener: (MobileAdEvent event) {
          print("InterstitialAd event is $event");
        });
    return fullAd;
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
      return Container(
        child: ListView.builder(
          padding: EdgeInsets.only(bottom: UserData.isAdShowing?90.0:5.0),
          itemCount: listQuoteCollection.length,
          itemBuilder: (context,index) {
            return Card(
              elevation: 5.0,
              child: new ListTile(
                onTap: () async{
                  fullAd = createInterstitialAd();
                  fullAd.load();
                  await Navigator.push(
                      context,
                      new MaterialPageRoute(
                          builder: (context) =>
                          QuotesDetailScreen(listQuoteCollection,index)));
                  fullAd.show();
                },
                contentPadding: EdgeInsets.symmetric(horizontal: 7.0,vertical: 7.0),
                title: Text(
                    listQuoteCollection[index].quote,
                    textScaleFactor:1.05,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(
                        fontSize: 15.0,
                        color: Color(0xff075E54),
                        fontFamily: "Merriweather"
                    )
                ),
                subtitle:Text(
                    listQuoteCollection[index].author,
                    textAlign: TextAlign.right,
                    style:TextStyle(
                        fontSize: 15.0,
                        color: Colors.red,
                        fontStyle: FontStyle.italic,
                        fontFamily: "LobsterTwo"
                    ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.arrow_forward_ios),
                  onPressed: () async {
                    fullAd = createInterstitialAd();
                    fullAd.load();
                    await Navigator.push(
                        context,
                        new MaterialPageRoute(
                            builder: (context) =>
                            QuotesDetailScreen(listQuoteCollection,index)));
                    fullAd.show();
                  },
                  color: Color(0xff075E54),
                ),
              ),
            );
          },
        ),
      );
    }
  }
}