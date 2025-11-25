import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


Future<void> saveUserFCMToken() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final token = await FirebaseMessaging.instance.getToken();
  if (token == null) return;

  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
    'fcmToken': token,
    //'latitude': userLat,   // YOU must fetch user’s live location
    //'longitude': userLng,  // and store here
  }, SetOptions(merge: true));
}


void requestPermission() async{
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings setting = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: true,
    sound: true
  );
  if (setting.authorizationStatus == AuthorizationStatus.authorized) {
    print ('User granted permission');
  }else if(setting.authorizationStatus == AuthorizationStatus.provisional){

  }else{
    print('User declined or has not accepted permission');
  }

}