import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';



class UserData {

    static final GoogleSignIn googleSignIn = GoogleSignIn(scopes: <String>['email']);
    static FirebaseUser fireBaseUser;
    static bool isAdShowing;
    static bool isFullAd = false;
}