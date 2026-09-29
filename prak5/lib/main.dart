import 'package:flutter/material.dart';
import 'core/di/injection_container.dart' as di;
import 'features/quotes/screens/quotes_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initDependencies();
  runApp(const ApiNinjasApp());
}

class ApiNinjasApp extends StatelessWidget {
  const ApiNinjasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Api Ninjas Quotes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const QuotesScreen(),
    );
  }
}