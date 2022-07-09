import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:futter_push_notificartion/fb_notification/app_service.dart';
import 'package:futter_push_notificartion/fb_notification/models/notification.dart';
import 'package:futter_push_notificartion/fb_notification/notification_service.dart';
import 'package:futter_push_notificartion/models/chat_common_info_model.dart';
import 'package:futter_push_notificartion/repository/authen_repositories.dart';
import 'package:singleton/singleton.dart';
import 'package:sp_util/sp_util.dart';

class FirebaseService {
  //
  /// Factory method that reuse same instance automatically
  factory FirebaseService() =>
      Singleton.lazy(() => FirebaseService._()).instance;

  /// Private constructor
  FirebaseService._() {}

  //
  late NotificationModel notificationModel;
  late FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  late dynamic notificationPayloadData;

  late AuthRepo authenticationRepositories = AuthRepo();

  setUpFirebaseMessaging() async {
    // setUpFirebaseToken();
    //Request for notification permission
    /*NotificationSettings settings = */
    NotificationSettings settings = await firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('setUpFirebaseMessaging: User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('setUpFirebaseMessaging: User granted provisional permission');
    } else {
      print('setUpFirebaseMessaging: User declined or has not accepted permission');
    }

    //subscribing to all topic
    firebaseMessaging.subscribeToTopic("all");

    // Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

    // If the message also contains a data property with a "type" of "chat",
    // navigate to a chat screen
    if (initialMessage != null) {
      saveNewNotification(initialMessage);
      selectNotification("From onMessageOpenedApp");
    }

    //on notification tap tp bring app back to life
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      saveNewNotification(message);
      selectNotification("From onMessageOpenedApp");
      //
      refreshOrdersList(message);
    });

    //normal notification listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("---------FirebaseMessaging.onMessage.listen--------");
      saveNewNotification(message);
      showNotification(message);
      //
      refreshOrdersList(message);
    });

    // //background notification listener
    // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }



  setUpFirebaseToken(){
    if (AuthRepo.accessToken != null){
      if (AuthRepo.firebaseToken == null) {
        addFCMTokenForUser();
      } else {
        updateFCMTokenForUser();
      }
    } else {
      print("setUpFirebaseToken : Not login");
    }
  }

  //write to notification list
  saveNewNotification(RemoteMessage? message, {String? title, String? body}) {
    //
    notificationPayloadData = message != null ? message.data : null;
    if (message!.notification == null &&
        message.data != null &&
        message.data["title"] == null &&
        title == null) {
      return;
    }
    //Saving the notification
    notificationModel = NotificationModel();
    notificationModel.title =
        message.notification?.title ?? title ?? message.data["title"] ?? "";
    notificationModel.body =
        message.notification?.body ?? body ?? message.data["body"] ?? "";
    //

    if (message != null && message.data != null) {
      final imageUrl = message.data["image"] ??
          (Platform.isAndroid
              ? message.notification?.android?.imageUrl
              : message.notification?.apple?.imageUrl);
      notificationModel.image = imageUrl;
    }

    //
    notificationModel.timeStamp = DateTime.now().millisecondsSinceEpoch;

    // //add to database/shared pref
    // NotificationService.addNotification(notificationModel);
  }

  //
  showNotification(RemoteMessage message) async {
    if (message.notification == null && message.data["title"] == null) {
      return;
    }

    //
    notificationPayloadData = message.data;

    //
    try {
      //
      String? imageUrl;

      try {
        imageUrl = message.data["image"] ??
            (Platform.isAndroid
                ? message?.notification?.android?.imageUrl
                : message?.notification?.apple?.imageUrl);
      } catch (error) {
        print("error getting notification image");
      }

      //
      if (imageUrl != null) {
        //
        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: Random().nextInt(20),
            channelKey: NotificationService.appNotificationChannel().channelKey,
            title: message.data["title"] ?? message.notification!.title,
            body: message.data["body"] ?? message.notification!.body,
            bigPicture: imageUrl,
            icon: "resource://drawable/notification_icon",
            notificationLayout: imageUrl != null
                ? NotificationLayout.BigPicture
                : NotificationLayout.Default,
            payload: Map<String, String>.from(message.data),
          ),
        );
      } else {
        //
        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: Random().nextInt(20),
            channelKey: NotificationService.appNotificationChannel().channelKey,
            title: message.data["title"] ?? message.notification!.title,
            body: message.data["body"] ?? message.notification!.body,
            icon: "resource://drawable/notification_icon",
            notificationLayout: NotificationLayout.Default,
            payload: Map<String, String>.from(message.data),
          ),
        );
      }

      ///
    } catch (error) {
      print("Notification Show error ===> ${error}");
    }
  }

  //handle on notification selected
  Future selectNotification(String payload) async {
    if (payload == null) {
      return;
    }
    try {
      log("NotificationPaylod ==> ${jsonEncode(notificationPayloadData)}");
      String notType = notificationPayloadData["not_type"];
      if (notType == NOTIFICATION_TYPE.Chat.toShortString()){
        //go to detail_chat
        // AppRouter.replaceAllWithPage(
        //   AppService().navigatorKey.currentContext,
        //   AppPages.Navigation,
        //   arguments: {
        //     'chatInfo':
        //     ChatCommonInfoModel(chatId: notificationPayloadData["room_id"], comId: notificationPayloadData["sender_id"], comAvatarUrl: notificationPayloadData["sender_avatar"], comName: notificationPayloadData["sender_name"]),
        //   },
        // );
      }
    } catch (error) {
      print("Error opening Notification ==> $error");
    }
  }

  //refresh orders list if the notification is about assigned order
  void refreshOrdersList(RemoteMessage message) async {
    if (message.data != null && message.data["is_order"] != null) {
      await Future.delayed(Duration(seconds: 3));
      // AppService().refreshAssignedOrders.add(true);
    }
  }

  Future<void> addGuestUserForFCMToken() async {
    FirebaseMessaging.instance.getToken().then((value) {
      if (value != "" && value != null) {
        print("Firebase_Token: $value");
        // videoRepo.addGuestUser(value, platformId);
      }
    });
  }

  Future<void> addFCMTokenForUser() async {
    FirebaseMessaging.instance.getToken().then((firebaseToken) {
      if (firebaseToken != "" && firebaseToken != null) {
        print("Firebase_Token: $firebaseToken");
        authenticationRepositories.updateFirebaseToken("user_id", firebaseToken).then((value) {
          if (value != null){
            SpUtil.putString("firebase_token", firebaseToken);
          }
        });
      }
    });
  }

  Future<void> updateFCMTokenForUser() async {
    print("updateFCMTokenForUser");
    FirebaseMessaging.instance.getToken().then((firebaseToken) {
      if (firebaseToken != "" && firebaseToken != null) {
        String storeFirebaseToken = AuthRepo.firebaseToken;
        if (storeFirebaseToken != null){
          authenticationRepositories.updateFirebaseToken("user_id", firebaseToken).then((value) {
            if (value != null){
              SpUtil.putString("firebase_token", firebaseToken);
            }
          });
        }
        print("Firebase_Token: $firebaseToken");
        // videoRepo.updateFcmToken(value);
      }
    });
  }

  logoutFirebase(){
    firebaseMessaging.unsubscribeFromTopic("all");
    FirebaseMessaging.instance.deleteToken();
    //call to API delete columns ft_token with id and device if need
  }
}