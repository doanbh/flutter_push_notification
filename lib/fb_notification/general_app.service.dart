import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:futter_push_notificartion/services/firebase_service.dart';

class GeneralAppService {
  //

//Hnadle background message
  static Future<void> onBackgroundMessageHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    FirebaseService().showNotification(message);
  }
}
