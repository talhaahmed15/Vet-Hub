import 'package:clinic_management_app/bloc/logged_clinic/logged_clinic_cubit.dart';
import 'package:clinic_management_app/screens/auth/app_start_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? "",
    anonKey: dotenv.env['ANON_KEY'] ?? "",
  );

  runApp(
    MultiBlocProvider(
      providers: [BlocProvider(create: (context) => LoggedClinicCubit())],
      child: VetHubApp(),
    ),
  );
}

class VetHubApp extends StatelessWidget {
  const VetHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // darkTheme: AppTheme.darkTheme,
      home: AppStartScreen(),
    );
  }
}
