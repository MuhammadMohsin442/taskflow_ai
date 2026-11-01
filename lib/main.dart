import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/services/app_data_loader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  try {
    await AppDataLoader.load(container);
  } catch (error) {
    debugPrint('Failed to load saved data: $error');
  }

  runApp(
    UncontrolledProviderScope(container: container, child: const TaskFlowApp()),
  );
}
