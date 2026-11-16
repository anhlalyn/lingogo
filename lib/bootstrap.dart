import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'branding.dart';
import 'auth_service.dart';
import 'content_repository.dart';
import 'firebase_options.dart';
import 'app_check_setup.dart';

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key, this.loadApp});
  final Future<Widget> Function()? loadApp;
  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late Future<Widget> loading;
  FirebaseAuthService? auth;
  @override
  void initState() {
    super.initState();
    loading = load();
  }

  Future<Widget> load() async {
    if (widget.loadApp != null) return widget.loadApp!();
    await Future.wait([
      Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 20)),
      Future<void>.delayed(const Duration(milliseconds: 900)),
    ]);
    if (!mounted) return const SizedBox.shrink();
    await initializeAppCheck();
    auth ??= FirebaseAuthService();
    return LingoGoApp(auth: auth!, content: FirebaseContentRepository());
  }

  @override
  void dispose() {
    auth?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Widget>(
    future: loading,
    builder: (context, snapshot) {
      if (snapshot.hasData) return snapshot.data!;
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'LingoGo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: purple),
          useMaterial3: true,
        ),
        home: SplashScreen(
          failed: snapshot.hasError,
          onRetry: () => setState(() {
            loading = load();
          }),
        ),
      );
    },
  );
}
