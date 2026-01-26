import 'package:clinic_management_app/bloc/logged_clinic/logged_clinic_cubit.dart';
import 'package:clinic_management_app/bloc/logged_clinic/logged_clinic_states.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/screens/auth/clinic_choice_screen.dart';
import 'package:clinic_management_app/screens/auth/login_screen.dart';
import 'package:clinic_management_app/services/storage.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppStartScreen extends StatefulWidget {
  const AppStartScreen({super.key});

  @override
  State<AppStartScreen> createState() => _AppStartScreenState();
}

class _AppStartScreenState extends State<AppStartScreen> {
  bool _checkedStorage = false;

  @override
  void initState() {
    super.initState();
    _restoreClinic();
  }

  Future<void> _restoreClinic() async {
    final clinicCode = await Storage.getClinicCode();
    if (!mounted) return;

    setState(() {
      _checkedStorage = true;
    });

    if (clinicCode != null) {
      context.read<LoggedClinicCubit>().getClinicByCode(clinicCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoggedClinicCubit, LoggedClinicState>(
      listener: (context, state) {
        if (state is LoggedClinicSuccess) {
          NavigatorHelper.replace(
            context,
            LoginScreen(clinic: state.clinic),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Center(
          child: _checkedStorage
              ? BlocBuilder<LoggedClinicCubit, LoggedClinicState>(
                  builder: (context, state) {
                    if (state is LoggedClinicLoading) {
                      return const CircularProgressIndicator();
                    }
                    if (state is LoggedClinicFailure) {
                      return const ClinicChoiceScreen();
                    }
                    return const ClinicChoiceScreen();
                  },
                )
              : const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
