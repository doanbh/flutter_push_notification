import 'dart:io';

import 'package:sp_util/sp_util.dart';

class AuthRepo {
  static String get accessToken => SpUtil.getString("token", defValue: null);

  static String get firebaseToken => SpUtil.getString("firebase_token", defValue: null);

  Future<Object?> updateFirebaseToken(String userId, String firebaseToken) async {
    return Object();
  }

}
