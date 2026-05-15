import 'package:flutter/material.dart';

import 'routes.dart';
import 'theme.dart';

class PhonePongApp extends StatelessWidget {
  const PhonePongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhonePong',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
