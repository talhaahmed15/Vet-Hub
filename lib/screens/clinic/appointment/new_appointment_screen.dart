import 'package:clinic_management_app/bloc/appointment/appointment_flow_cubit.dart';
import 'package:clinic_management_app/bloc/appointment/owner_pets_bloc.dart';
import 'package:clinic_management_app/models/client.dart';
import 'package:clinic_management_app/models/pet.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/screens/clinic/appointment/condition_screen.dart';
import 'package:clinic_management_app/screens/clinic/appointment/pet_management_screen.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/custom_dropdown_field.dart';
import 'package:clinic_management_app/widgets/custom_textfield.dart';
import 'package:clinic_management_app/widgets/icon_button.dart';
import 'package:clinic_management_app/widgets/search_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NewAppointmentScreen extends StatefulWidget {
  const NewAppointmentScreen({super.key});

  @override
  State<NewAppointmentScreen> createState() => _NewAppointmentScreenState();
}

class _NewAppointmentScreenState extends State<NewAppointmentScreen> {
  static const String _newPetId = 'new_pet';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final OwnerPetsBloc _ownerPetsBloc;
  late final AppointmentFlowCubit _appointmentFlowCubit;

  Client? _selectedOwner;
  String _selectedPetId = _newPetId;
  String _newPetSpecies = 'Dog';

  final TextEditingController _ownerSearchController = TextEditingController();
  final TextEditingController _ownerPhoneController = TextEditingController();
  final TextEditingController _newPetNameController = TextEditingController();
  final TextEditingController _newPetAgeController = TextEditingController();
  final TextEditingController _newPetBreedController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heartRateController = TextEditingController();
  final TextEditingController _appointmentReasonController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _ownerPetsBloc = OwnerPetsBloc()..add(const OwnersRequested());
    _appointmentFlowCubit = AppointmentFlowCubit();
  }

  @override
  void dispose() {
    _ownerPetsBloc.close();
    _appointmentFlowCubit.close();
    _ownerSearchController.dispose();
    _ownerPhoneController.dispose();
    _newPetNameController.dispose();
    _newPetAgeController.dispose();
    _newPetBreedController.dispose();
    _temperatureController.dispose();
    _weightController.dispose();
    _heartRateController.dispose();
    _appointmentReasonController.dispose();
    super.dispose();
  }

  bool get _isNewPetSelected => _selectedPetId == _newPetId;

  void _handleOwnerSelected(Client owner) {
    setState(() {
      _selectedOwner = owner;
      _selectedPetId = _newPetId;
      _ownerSearchController.text = owner.fullName;
      _ownerPhoneController.text = owner.phone ?? '';
    });
    _ownerPetsBloc.add(PetsRequested(owner.id));
  }

  Future<void> _openPetManager() async {
    if (_selectedOwner == null) {
      AppToast.error(context, 'Please select a pet owner first.');
      return;
    }

    await NavigatorHelper.push(
      context,
      PetManagementScreen(client: _selectedOwner!),
    );

    if (!mounted) return;
    _ownerPetsBloc.add(PetsRequested(_selectedOwner!.id));
  }

  void _handleSchedule(List<Pet> pets) {
    final ownerName = _ownerSearchController.text.trim().isNotEmpty
        ? _ownerSearchController.text.trim()
        : (_selectedOwner?.fullName ?? '');
    if (ownerName.isEmpty) {
      AppToast.error(context, 'Please select or enter a pet owner name.');
      return;
    }

    Pet? selectedPet;
    for (final pet in pets) {
      if (pet.id == _selectedPetId) {
        selectedPet = pet;
        break;
      }
    }

    if (!_isNewPetSelected && selectedPet == null) {
      AppToast.error(context, 'Please select a pet.');
      return;
    }

    if (_isNewPetSelected && _newPetNameController.text.trim().isEmpty) {
      AppToast.error(context, 'Please enter the pet name.');
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      AppToast.error(context, 'Please fix the highlighted fields.');
      return;
    }

    _appointmentFlowCubit.initializeFromStart(
      clientId: _selectedOwner?.id,
      ownerName: ownerName,
      ownerPhone: _ownerPhoneController.text.trim(),
      isNewPet: _isNewPetSelected,
      petId: _isNewPetSelected ? null : selectedPet?.id,
      petName: _isNewPetSelected
          ? _newPetNameController.text.trim()
          : (selectedPet?.name ?? ''),
      petSpecies: _isNewPetSelected
          ? _newPetSpecies
          : (selectedPet?.species ?? ''),
      petBreed: _isNewPetSelected
          ? _newPetBreedController.text.trim()
          : (selectedPet?.breed ?? ''),
      petAge: _isNewPetSelected ? _newPetAgeController.text.trim() : '',
      temperature: _temperatureController.text.trim(),
      weightKg: _weightController.text.trim(),
      heartRate: _heartRateController.text.trim(),
      appointmentReason: _appointmentReasonController.text.trim(),
    );

    NavigatorHelper.push(
      context,
      BlocProvider.value(
        value: _appointmentFlowCubit,
        child: const ConditionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _ownerPetsBloc),
        BlocProvider.value(value: _appointmentFlowCubit),
      ],
      child: BlocListener<OwnerPetsBloc, OwnerPetsState>(
        listenWhen: (previous, current) =>
            current is OwnerPetsLoaded &&
            !current.petsLoading &&
            current.petsClientId == _selectedOwner?.id,
        listener: (context, state) {
          final loaded = state as OwnerPetsLoaded;
          setState(() {
            if (loaded.pets.isEmpty) {
              _selectedPetId = _newPetId;
            } else {
              _selectedPetId = loaded.pets.first.id;
            }
          });
        },
        child: Scaffold(
          body: Column(
            children: [
              CustomAppBar(title: 'New Appointment'),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    children: [
                      _SectionLabel('PET OWNER INFORMATION'),
                      const SizedBox(height: 16),
                      Text(
                        'Search pet owner',
                        style: AppFonts.medium(
                          fontSize: 14,
                          color: isDark ? AppColors.white : AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      BlocBuilder<OwnerPetsBloc, OwnerPetsState>(
                        builder: (context, state) {
                          final clients = state is OwnerPetsLoaded
                              ? state.clients
                              : const <Client>[];
                          final loading = state is OwnerPetsLoading;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _OwnerTypeAhead(
                                controller: _ownerSearchController,
                                clients: clients,
                                enabled: !loading,
                                onSelected: _handleOwnerSelected,
                              ),
                              if (loading)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: LinearProgressIndicator(),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        hintText: 'Pet owner phone (e.g. 555-123-4567)',
                        keyboardType: TextInputType.phone,
                        onChanged: (_) {},
                        controller: _ownerPhoneController,
                      ),
                      const SizedBox(height: 20),
                      BlocBuilder<OwnerPetsBloc, OwnerPetsState>(
                        builder: (context, state) {
                          final pets = state is OwnerPetsLoaded
                              ? state.pets
                              : const <Pet>[];
                          final petsLoading =
                              state is OwnerPetsLoaded && state.petsLoading;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: .start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  crossAxisAlignment: .start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _SectionLabel('SELECT PET'),
                                    TextButton(
                                      onPressed: _openPetManager,
                                      child: Text(
                                        'Edit List',
                                        style: AppFonts.medium(
                                          fontSize: 14,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (petsLoading)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                _PetCarousel(
                                  pets: pets,
                                  selectedPetId: _selectedPetId,
                                  onSelect: (petId) {
                                    setState(() => _selectedPetId = petId);
                                  },
                                ),
                              const SizedBox(height: 16),
                              if (_isNewPetSelected)
                                _NewPetDetailsCard(
                                  species: _newPetSpecies,
                                  onSpeciesChanged: (value) {
                                    if (value == null) return;
                                    setState(() => _newPetSpecies = value);
                                  },
                                  nameController: _newPetNameController,
                                  ageController: _newPetAgeController,
                                  breedController: _newPetBreedController,
                                  isRequired: _isNewPetSelected,
                                ),
                              const SizedBox(height: 24),
                              _SectionLabel('VITALS'),
                              const SizedBox(height: 8),
                              _VitalsGrid(
                                temperatureController: _temperatureController,
                                weightController: _weightController,
                                heartRateController: _heartRateController,
                              ),
                              const SizedBox(height: 24),
                              _SectionLabel('APPOINTMENT REASON'),
                              const SizedBox(height: 8),
                              CustomTextField(
                                hintText:
                                    'Reason for visit (e.g. limping, annual checkup)',
                                maxLines: 4,
                                onChanged: (_) {},
                                controller: _appointmentReasonController,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Reason for visit is required.';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              BlocBuilder<OwnerPetsBloc, OwnerPetsState>(
                builder: (context, state) {
                  final pets = state is OwnerPetsLoaded
                      ? state.pets
                      : const <Pet>[];
                  return _BottomBar(onSchedule: () => _handleSchedule(pets));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _TopBar({required this.onCancel, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101922) : AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1A2430) : AppColors.divider,
          ),
        ),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: onCancel,
            child: Text(
              'Cancel',
              style: AppFonts.medium(fontSize: 16, color: AppColors.primary),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'New Appointment',
                style: AppFonts.bold(
                  fontSize: 18,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: onSave,
            child: Text(
              'Save',
              style: AppFonts.bold(fontSize: 16, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFonts.semiBold(
        fontSize: 13,
        color: AppColors.darkGrey,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _OwnerTypeAhead extends StatefulWidget {
  final TextEditingController controller;
  final List<Client> clients;
  final ValueChanged<Client> onSelected;
  final bool enabled;

  const _OwnerTypeAhead({
    required this.controller,
    required this.clients,
    required this.onSelected,
    required this.enabled,
  });

  @override
  State<_OwnerTypeAhead> createState() => _OwnerTypeAheadState();
}

class _OwnerTypeAheadState extends State<_OwnerTypeAhead> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  List<Client> get _filteredClients {
    final query = widget.controller.text.trim().toLowerCase();
    if (query.isEmpty) return widget.clients;
    return widget.clients
        .where(
          (client) =>
              client.fullName.toLowerCase().contains(query) ||
              (client.phone ?? '').toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  bool get _showSuggestions =>
      widget.enabled && _focusNode.hasFocus && _filteredClients.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchTextField(
          controller: widget.controller,
          focusNode: _focusNode,
          hint: 'Search pet owners...',
          enabled: widget.enabled,
          onChanged: (_) => setState(() {}),
        ),
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121E2A) : AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF1A2430) : AppColors.divider,
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredClients.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: isDark ? const Color(0xFF1A2430) : AppColors.divider,
              ),
              itemBuilder: (context, index) {
                final client = _filteredClients[index];
                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  title: Text(
                    client.fullName,
                    style: AppFonts.medium(
                      fontSize: 13,
                      color: isDark ? AppColors.white : AppColors.black,
                    ),
                  ),
                  subtitle: client.phone == null || client.phone!.isEmpty
                      ? null
                      : Text(
                          client.phone!,
                          style: AppFonts.regular(
                            fontSize: 11,
                            color: isDark ? AppColors.grey : AppColors.darkGrey,
                          ),
                        ),
                  onTap: () {
                    widget.controller.text = client.fullName;
                    widget.onSelected(client);
                    _focusNode.unfocus();
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _PetCarousel extends StatelessWidget {
  final List<Pet> pets;
  final String selectedPetId;
  final ValueChanged<String> onSelect;

  const _PetCarousel({
    required this.pets,
    required this.selectedPetId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final pet in pets) ...[
            _PetCard(
              selected: selectedPetId == pet.id,
              name: pet.name,
              subtitle: pet.breed,
              emoji: _emojiForSpecies(pet.species),
              onTap: () => onSelect(pet.id),
            ),
            const SizedBox(width: 12),
          ],
          _AddPetCard(
            selected: selectedPetId == _NewAppointmentScreenState._newPetId,
            onTap: () => onSelect(_NewAppointmentScreenState._newPetId),
          ),
        ],
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final bool selected;
  final String name;
  final String subtitle;
  final String emoji;
  final VoidCallback onTap;

  const _PetCard({
    required this.selected,
    required this.name,
    required this.subtitle,
    required this.emoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121E2A) : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark ? const Color(0xFF1A2430) : AppColors.divider),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 64,
                  width: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? const Color(0xFF1A2430)
                        : const Color(0xFFF0F2F5),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
                if (selected)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      height: 22,
                      width: 22,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: AppColors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: AppFonts.bold(
                fontSize: 14,
                color: isDark ? AppColors.white : AppColors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppFonts.regular(
                fontSize: 12,
                color: isDark ? AppColors.grey : AppColors.darkGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPetCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _AddPetCard({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121E2A) : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark ? const Color(0xFF2A3A4C) : AppColors.divider),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF1A2430) : AppColors.white,
                border: Border.all(
                  color: isDark ? const Color(0xFF2A3A4C) : AppColors.divider,
                ),
              ),
              child: const Icon(Icons.add, color: AppColors.primary, size: 30),
            ),
            const SizedBox(height: 10),
            Text(
              'New Pet',
              style: AppFonts.bold(fontSize: 14, color: AppColors.primary),
            ),
            const SizedBox(height: 2),
            Text(
              'Add profile',
              style: AppFonts.regular(
                fontSize: 12,
                color: isDark ? AppColors.grey : AppColors.darkGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewPetDetailsCard extends StatelessWidget {
  final String species;
  final ValueChanged<String?> onSpeciesChanged;
  final TextEditingController nameController;
  final TextEditingController ageController;
  final TextEditingController breedController;
  final bool isRequired;

  const _NewPetDetailsCard({
    required this.species,
    required this.onSpeciesChanged,
    required this.nameController,
    required this.ageController,
    required this.breedController,
    required this.isRequired,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121E2A) : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1A2430) : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pets, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'New Pet Details',
                style: AppFonts.bold(
                  fontSize: 16,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          CustomTextField(
            hintText: 'Pet name (e.g. Max)',
            onChanged: (_) {},
            controller: nameController,
            validator: (value) {
              if (!isRequired) return null;
              if (value == null || value.trim().isEmpty) {
                return 'Pet name is required.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomDropdownField(
                  hintText: 'Dog',
                  items: ['Dog', 'Cat', 'Bird', 'Exotic'],
                  value: species,
                  onChanged: onSpeciesChanged,
                  labelBuilder: (String p1) => p1.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  hintText: 'Age (e.g. 2)',
                  keyboardType: TextInputType.number,
                  onChanged: (_) {},
                  controller: ageController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CustomTextField(
            hintText: 'Breed (e.g. Beagle)',
            onChanged: (_) {},
            controller: breedController,
          ),
        ],
      ),
    );
  }
}

class _VitalsGrid extends StatelessWidget {
  final TextEditingController temperatureController;
  final TextEditingController weightController;
  final TextEditingController heartRateController;

  const _VitalsGrid({
    required this.temperatureController,
    required this.weightController,
    required this.heartRateController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _VitalInputCard(
                icon: Icons.device_thermostat,
                unit: '\u00B0F',
                label: 'TEMPERATURE',
                controller: temperatureController,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _VitalInputCard(
                icon: Icons.favorite,
                unit: 'BPM',
                label: 'HEART RATE',
                controller: heartRateController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _VitalInputCard(
          icon: Icons.monitor_weight,
          unit: 'kg',
          label: 'WEIGHT',
          controller: weightController,
        ),
      ],
    );
  }
}

class _VitalInputCard extends StatelessWidget {
  final IconData icon;
  final String unit;
  final String label;
  final TextEditingController controller;

  const _VitalInputCard({
    required this.icon,
    required this.unit,
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121E2A) : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1A2430) : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: AppColors.primary),
              Text(
                unit,
                style: AppFonts.bold(
                  fontSize: 11,
                  color: isDark ? AppColors.grey : AppColors.darkGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppFonts.bold(
              fontSize: 11,
              color: isDark ? AppColors.grey : AppColors.darkGrey,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: AppFonts.bold(
              fontSize: 24,
              color: isDark ? AppColors.white : AppColors.black,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final VoidCallback onSchedule;
  const _BottomBar({required this.onSchedule});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: PrimaryIconButton(
        text: 'Schedule Appointment',
        icon: Icons.calendar_today,
        onPressed: onSchedule,
      ),
    );
  }
}

String _emojiForSpecies(String species) {
  final normalized = species.toLowerCase();
  if (normalized.contains('dog')) {
    return '\u{1F436}';
  }
  if (normalized.contains('cat')) {
    return '\u{1F431}';
  }
  return '\u2753';
}
