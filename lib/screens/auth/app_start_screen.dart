import 'package:clinic_management_app/bloc/logged_clinic/logged_clinic_cubit.dart';
import 'package:clinic_management_app/bloc/logged_clinic/logged_clinic_states.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/screens/auth/clinic_choice_screen.dart';
import 'package:clinic_management_app/screens/auth/login_screen.dart';
import 'package:clinic_management_app/screens/clinic/clinic_root.dart';
import 'package:clinic_management_app/services/auth_service.dart';
import 'package:clinic_management_app/services/storage.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/widgets/page_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppStartScreen extends StatefulWidget {
  const AppStartScreen({super.key});

  @override
  State<AppStartScreen> createState() => _AppStartScreenState();
}

class _AppStartScreenState extends State<AppStartScreen> {
  bool _checkedStorage = false;
  bool _hasSession = false;
  bool _navigated = false;
  bool _restoring = false;
  bool _clinicFetchRequested = false;

  @override
  void initState() {
    super.initState();
    _restoreClinic();
  }

  Future<void> _restoreClinic() async {
    if (_restoring) return;
    _restoring = true;
    try {
      var clinicData = await Storage.getClinicData();
      var clinicCode = clinicData?['clinic_code']?.toString();
      final restoredSession = await AuthService().restoreSession();
      final clinicUserId = await Storage.getClinicUserId();

      var hasSession = restoredSession;
      if (clinicCode == null && hasSession) {
        await AuthService().signOutAndClear(clearClinic: true);
        hasSession = false;
      }
      if (hasSession && (clinicUserId == null || clinicUserId.isEmpty)) {
        final fetchedClinicUserId = await AuthService().fetchClinicUserId(
          clinicId: clinicData?['clinic_id']?.toString(),
        );
        if (fetchedClinicUserId != null && fetchedClinicUserId.isNotEmpty) {
          await Storage.saveClinicUserId(fetchedClinicUserId);
        } else {
          await AuthService().signOutAndClear(clearClinic: true);
          hasSession = false;
          clinicCode = null;
          clinicData = null;
        }
      }

      if (!mounted) return;

      setState(() {
        _checkedStorage = true;
        _hasSession = hasSession;
      });

      if (clinicCode == null || clinicCode.isEmpty) {
        if (!_navigated) {
          _navigated = true;
          if (_hasSession) {
            await AuthService().signOutAndClear(clearClinic: true);
          }
          NavigatorHelper.replace(context, const ClinicChoiceScreen());
        }
        return;
      }

      if (!_clinicFetchRequested) {
        _clinicFetchRequested = true;
        context.read<LoggedClinicCubit>().getClinicByCode(clinicCode);
      }
    } finally {
      _restoring = false;
    }
  }

  Future<void> _clearClinicCache() async {
    await Storage.clearAllAuthAndClinic();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoggedClinicCubit, LoggedClinicState>(
      listener: (context, state) {
        if (state is LoggedClinicSuccess) {
          if (_navigated) return;
          _navigated = true;
          if (_hasSession) {
            NavigatorHelper.replace(context, const ClinicRootScreen());
          } else {
            NavigatorHelper.replace(context, LoginScreen(clinic: state.clinic));
          }
          return;
        }
        if (state is LoggedClinicFailure && _hasSession) {
          if (_navigated) return;
          _navigated = true;
          AuthService().signOutAndClear(clearClinic: true);
          NavigatorHelper.replace(context, const ClinicChoiceScreen());
          return;
        }
        if (state is LoggedClinicFailure && !_hasSession) {
          if (_navigated) return;
          _navigated = true;
          _clearClinicCache();
          NavigatorHelper.replace(context, const ClinicChoiceScreen());
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: PageContent(
          maxWidth: 480,
          child: Center(
            child: const CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}
