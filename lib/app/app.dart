import 'package:flutter/material.dart';

import 'routes.dart';
import 'theme.dart';

class PongPongApp extends StatelessWidget {
  const PongPongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PongPong',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
