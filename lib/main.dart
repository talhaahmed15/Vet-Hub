import 'package:clinic_management_app/bloc/appointment/owner_pets_bloc.dart';
import 'package:clinic_management_app/bloc/appointment/pet_management_bloc.dart';
import 'package:clinic_management_app/bloc/inventory_bloc/inventory_txn_cubit.dart';
import 'package:clinic_management_app/bloc/inventory_bloc/item_detail_bloc.dart';
import 'package:clinic_management_app/bloc/inventory_bloc/items_bloc.dart';
import 'package:clinic_management_app/bloc/invoice/invoice_cubit.dart';
import 'package:clinic_management_app/bloc/logged_clinic/logged_clinic_cubit.dart';
import 'package:clinic_management_app/bloc/login/login_cubit.dart';
import 'package:clinic_management_app/bloc/tasks/tasks_cubit.dart';
import 'package:clinic_management_app/screens/splash/splash_screen.dart';
import 'package:clinic_management_app/services/appointment_service.dart';
import 'package:clinic_management_app/services/inventory_service.dart';
import 'package:clinic_management_app/services/invoice_service.dart';
import 'package:clinic_management_app/services/items_service.dart';
import 'package:clinic_management_app/services/task_service.dart';
import 'package:clinic_management_app/themes/app_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['ANON_KEY'] ?? '',
  );

  final itemsRepository = ItemsService();
  final inventoryRepository = InventoryService();
  final appointmentRepository = AppointmentService();
  final invoiceRepository = InvoiceService();
  final taskRepository = TaskService();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ItemsService>.value(value: itemsRepository),
        RepositoryProvider<InventoryService>.value(value: inventoryRepository),
        RepositoryProvider<AppointmentService>.value(
          value: appointmentRepository,
        ),
        RepositoryProvider<InvoiceService>.value(value: invoiceRepository),
        RepositoryProvider<TaskService>.value(value: taskRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => LoggedClinicCubit()),
          BlocProvider(create: (context) => LoginCubit()),
          BlocProvider(
            create: (context) => InvoiceCubit(
              invoiceService: context.read<InvoiceService>(),
              appointmentService: context.read<AppointmentService>(),
            ),
          ),
          BlocProvider(create: (context) => InventoryTxnCubit()),
          BlocProvider(create: (context) => InventoryItemDetailBloc()),
          BlocProvider(create: (context) => PetManagementBloc()),
          BlocProvider(create: (context) => OwnerPetsBloc()),
          BlocProvider(
            create: (context) => InventoryItemsBloc(
              itemsRepository: context.read<ItemsService>(),
            ),
          ),
          BlocProvider(
            create: (context) => TasksCubit(service: context.read<TaskService>()),
          ),
        ],
        child: const VetHubApp(),
      ),
    ),
  );
}

class VetHubApp extends StatelessWidget {
  const VetHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VetHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // darkTheme: AppTheme.dark,
      scrollBehavior: _AppScrollBehavior(),
      home: const SplashScreen(),
    );
  }
}

/// Enables mouse/trackpad drag-scrolling on web and desktop,
/// in addition to the default touch scrolling.
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}
