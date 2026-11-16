import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

Future<void> initializeAppCheck() async {
  if (kIsWeb) {
    const siteKey = String.fromEnvironment('APP_CHECK_WEB_SITE_KEY');
    if (siteKey.isEmpty) {
      return; // Login/manual editing still work; AI needs web setup.
    }
    await FirebaseAppCheck.instance.activate(
      providerWeb: ReCaptchaV3Provider(siteKey),
    );
  } else {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  }
}
