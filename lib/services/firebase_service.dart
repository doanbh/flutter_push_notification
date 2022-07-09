import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseService {
  //
  /// Factory method that reuse same instance automatically
  static final FirebaseService _singleton = FirebaseService._internal();

  factory FirebaseService() {
    return _singleton;
  }

  FirebaseService._internal();

  /// Private constructor
  FirebaseService._() {}

  //
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  dynamic notificationPayloadData;


  setUpFirebaseMessaging() async {
    setUpFirebaseToken();
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
    addFCMTokenForUser();
  }

  //write to notification list
  saveNewNotification(RemoteMessage message, {String? title, String? body}) {
    //
    notificationPayloadData = message != null ? message.data : null;
    if (message.notification == null &&
        message.data != null &&
        message.data["title"] == null &&
        title == null) {
      return;
    }
    //Saving the notification
    // notificationModel = NotificationModel();
    // notificationModel.title =
    //     message?.notification?.title ?? title ?? message?.data["title"] ?? "";
    // notificationModel.body =
    //     message?.notification?.body ?? body ?? message?.data["body"] ?? "";
    // //
    //
    // if (message != null && message.data != null) {
    //   final imageUrl = message?.data["image"] ??
    //       (Platform.isAndroid
    //           ? message?.notification?.android?.imageUrl
    //           : message?.notification?.apple?.imageUrl);
    //   notificationModel.image = imageUrl;
    // }
    //
    // //
    // notificationModel.timeStamp = DateTime.now().millisecondsSinceEpoch;
    //
    // // //add to database/shared pref
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
      String imageUrl;

      try {
        imageUrl = message.data["image"] ??
            (Platform.isAndroid
                ? message?.notification?.android?.imageUrl
                : message?.notification?.apple?.imageUrl);
      } catch (error) {
        print("error getting notification image");
      }

      //
      // if (imageUrl != null) {
      //   //
      //   AwesomeNotifications().createNotification(
      //     content: NotificationContent(
      //       id: Random().nextInt(20),
      //       channelKey: NotificationService.appNotificationChannel().channelKey,
      //       title: message.data["title"] ?? message.notification.title,
      //       body: message.data["body"] ?? message.notification.body,
      //       bigPicture: imageUrl,
      //       icon: "resource://drawable/notification_icon",
      //       notificationLayout: imageUrl != null
      //           ? NotificationLayout.BigPicture
      //           : NotificationLayout.Default,
      //       payload: Map<String, String>.from(message.data),
      //     ),
      //   );
      // } else {
      //   //
      //   AwesomeNotifications().createNotification(
      //     content: NotificationContent(
      //       id: Random().nextInt(20),
      //       channelKey: NotificationService.appNotificationChannel().channelKey,
      //       title: message.data["title"] ?? message.notification.title,
      //       body: message.data["body"] ?? message.notification.body,
      //       icon: "resource://drawable/notification_icon",
      //       notificationLayout: NotificationLayout.Default,
      //       payload: Map<String, String>.from(message.data),
      //     ),
      //   );
      // }

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
      // if (notType == NOTIFICATION_TYPE.Chat.toShortString()){
      //   AppRouter.replaceAllWithPage(
      //     AppService().navigatorKey.currentContext,
      //     AppPages.Navigation,
      //     arguments: {
      //       'chatInfo':
      //       ChatCommonInfoModel(chatId: notificationPayloadData["room_id"], comId: notificationPayloadData["sender_id"], comAvatarUrl: notificationPayloadData["sender_avatar"], comName: notificationPayloadData["sender_name"]),
      //     },
      //   );
      //   // AppRouter.toPage(
      //   //   AppService().navigatorKey.currentContext,
      //   //   AppPages.Chat_Detail,
      //   //   arguments: {
      //   //     'chatInfo':
      //   //     ChatCommonInfoModel(chatId: notificationPayloadData["room_id"], comId: notificationPayloadData["sender_id"], comAvatarUrl: notificationPayloadData["sender_avatar"], comName: notificationPayloadData["sender_name"]),
      //   //   },
      //   //   // blocValue: AppService().navigatorKey.currentContext.read<OnlineCompaniesCubit>(),
      //   // );
      // }
      //
      final isChat = notificationPayloadData != null &&
          notificationPayloadData["is_chat"] != null;
      final isOrder = notificationPayloadData != null &&
          notificationPayloadData["is_order"] != null;

      ///
      final hasProduct = notificationPayloadData != null &&
          notificationPayloadData["product"] != null;
      final hasVendor = notificationPayloadData != null &&
          notificationPayloadData["vendor"] != null;
      final hasService = notificationPayloadData != null &&
          notificationPayloadData["service"] != null;
      //
      if (isChat) {
        //
        dynamic user = jsonDecode(notificationPayloadData['user']);
        dynamic peer = jsonDecode(notificationPayloadData['peer']);
        String chatPath = notificationPayloadData['path'];
        // //
        // Map<String, PeerUser> peers = {
        //   '${user['id']}': PeerUser(
        //     id: '${user['id']}',
        //     name: "${user['name']}",
        //     image: "${user['photo']}",
        //   ),
        //   '${peer['id']}': PeerUser(
        //     id: '${peer['id']}',
        //     name: "${peer['name']}",
        //     image: "${peer['photo']}",
        //   ),
        // };
        // //
        // final peerRole = peer["role"];
        // //
        // final chatEntity = ChatEntity(
        //   mainUser: peers['${user['id']}'],
        //   peers: peers,
        //   //don't translate this
        //   path: chatPath,
        //   title: peer["role"] == null
        //       ? "Chat with".i18n + " ${peer['name']}"
        //       : peerRole == 'vendor'
        //           ? "Chat with vendor".i18n
        //           : "Chat with driver".i18n,
        // );
        // AppService().navigatorKey.currentContext.navigator.pushNamed(
        //       AppRoutes.chatRoute,
        //       arguments: chatEntity,
        //     );
      }
      //order
      else if (isOrder) {
        //
        // final order = Order(
        //   id: int.parse(notificationPayloadData['order_id'].toString()),
        // );
        // //
        // AppService().navigatorKey.currentContext.navigator.pushNamed(
        //       AppRoutes.orderDetailsRoute,
        //       arguments: order,
        //     );
      }
      //vendor type of notification
      else if (hasVendor) {
        //
        // final vendor = Vendor.fromJson(
        //   jsonDecode(notificationPayloadData['vendor']),
        // );
        // //
        // AppService().navigatorKey.currentContext.navigator.pushNamed(
        //       AppRoutes.vendorDetails,
        //       arguments: vendor,
        //     );
      }
      //product type of notification
      else if (hasProduct) {
        //
        // final product = Product.fromJson(
        //   jsonDecode(notificationPayloadData['product']),
        // );
        // //
        // AppService().navigatorKey.currentContext.navigator.pushNamed(
        //       AppRoutes.product,
        //       arguments: product,
        //     );
      }
      //service type of notification
      else if (hasService) {
        //
        // final service = Service.fromJson(
        //   jsonDecode(notificationPayloadData['service']),
        // );
        // //
        // AppService().navigatorKey.currentContext.push(
        //       (context) => ServiceDetailsPage(service),
        //     );
      }
      //regular notifications
      else {
        // AppService().navigatorKey.currentContext.navigator.pushNamed(
        //       AppRoutes.notificationDetailsRoute,
        //       arguments: notificationModel,
        //     );
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
      }
    });
  }

}