import 'package:flutter/material.dart';
import 'package:myapp/pages/friendslist_page.dart';
import 'package:myapp/pages/login_page.dart';
import 'package:myapp/services/login_service.dart';
import 'package:myapp/services/network_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // đảm bảo mọi thứ được khởi tạo
  final isLoggedIn = await LoginService.isLoggedInWithinAWeek();
  final hasInternet = await NetworkService.hasInternet();
  runApp(MyApp(isLoggedIn: isLoggedIn, hasInternet: hasInternet));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool hasInternet;

  const MyApp({super.key, required this.isLoggedIn, required this.hasInternet});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: !isLoggedIn ? LoginPage() : FriendsList(),
    );
  }
}
