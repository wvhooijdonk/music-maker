import 'package:material_ui/material_ui.dart';

import 'pages/home_page.dart';

class MijnApp extends StatelessWidget {
  const MijnApp({super.key});

  static const title = 'Music Maker';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const HomePage(title: title),
    );
  }
}
