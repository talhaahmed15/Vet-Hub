import 'package:clinic_management_app/bloc/appointment/pet_management_bloc.dart';
import 'package:clinic_management_app/models/client.dart';
import 'package:clinic_management_app/models/pet.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_dialogs.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/custom_dropdown_field.dart';
import 'package:clinic_management_app/widgets/custom_textfield.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PetManagementScreen extends StatelessWidget {
  const PetManagementScreen({super.key, required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PetManagementBloc()..add(PetManagementLoad(client.id)),
      child: _PetManagementView(client: client),
    );
  }
}

class _PetManagementView extends StatelessWidget {
  const _PetManagementView({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: CustomAppBar(title: 'Manage Pets'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openPetSheet(context, clientId: client.id),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: SafeArea(
        child: BlocConsumer<PetManagementBloc, PetManagementState>(
          listener: (context, state) {
            if (state is PetManagementFailure) {
              AppToast.error(context, state.message);
            }
            if (state is PetManagementLoaded && state.error != null) {
              AppToast.error(context, state.error!);
            }
          },
          builder: (context, state) {
            if (state is PetManagementLoading ||
                state is PetManagementInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is PetManagementFailure) {
              return _EmptyState(
                title: 'Unable to load pets',
                subtitle: state.message,
                actionText: 'Retry',
                onAction: () => context
                    .read<PetManagementBloc>()
                    .add(PetManagementLoad(client.id)),
              );
            }

            final loaded = state as PetManagementLoaded;
            if (loaded.pets.isEmpty) {
              return _EmptyState(
                title: 'No pets yet',
                subtitle: 'Add a pet for ${client.fullName}.',
                actionText: 'Add Pet',
                onAction: () => _openPetSheet(context, clientId: client.id),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Text(
                    'Swipe right to edit. Swipe left to delete.',
                    style: AppFonts.regular(
                      fontSize: 12,
                      color: AppColors.darkGrey,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...loaded.pets.map(
                  (pet) => _PetRow(
                    pet: pet,
                    onEdit: () => _openPetSheet(
                      context,
                      clientId: client.id,
                      pet: pet,
                    ),
                    onDelete: () => _confirmDelete(context, pet),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Pet pet) {
    AppDialog.confirmDelete(
      context: context,
      title: 'Delete pet?',
      message: 'Delete ${pet.name}? This cannot be undone.',
    ).then((confirmed) {
      if (confirmed != true) return;
      context.read<PetManagementBloc>().add(PetManagementDelete(pet.id));
    });
  }
}

class _PetRow extends StatelessWidget {
  const _PetRow({
    required this.pet,
    required this.onEdit,
    required this.onDelete,
  });

  final Pet pet;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(pet.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit();
          return false;
        }
        if (direction == DismissDirection.endToStart) {
          onDelete();
          return false;
        }
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.edit, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Edit',
              style: AppFonts.semiBold(fontSize: 12, color: AppColors.primary),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: AppFonts.semiBold(fontSize: 12, color: AppColors.error),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.delete_outline, color: AppColors.error),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.pets, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pet.name, style: AppFonts.semiBold(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    [pet.species, pet.breed]
                        .where((p) => p.trim().isNotEmpty)
                        .join(' • '),
                    style: AppFonts.regular(
                      fontSize: 12,
                      color: AppColors.darkGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _openPetSheet(
  BuildContext context, {
  required String clientId,
  Pet? pet,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return _PetFormSheet(clientId: clientId, pet: pet);
    },
  );
}

class _PetFormSheet extends StatefulWidget {
  const _PetFormSheet({required this.clientId, this.pet});

  final String clientId;
  final Pet? pet;

  @override
  State<_PetFormSheet> createState() => _PetFormSheetState();
}

class _PetFormSheetState extends State<_PetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _breedController;
  String _species = 'Dog';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pet?.name ?? '');
    _breedController = TextEditingController(text: widget.pet?.breed ?? '');
    if (widget.pet?.species.isNotEmpty == true) {
      _species = widget.pet!.species;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.pet != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Pet' : 'Add Pet',
                style: AppFonts.bold(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text('Name', style: AppFonts.semiBold(fontSize: 12)),
              CustomTextField(
                controller: _nameController,
                hintText: 'Pet name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Pet name is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text('Species', style: AppFonts.semiBold(fontSize: 12)),
              CustomDropdownField<String>(
                items: const ['Dog', 'Cat', 'Bird', 'Exotic'],
                value: _species,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _species = value);
                },
                hintText: '',
                labelBuilder: (value) => value,
              ),
              const SizedBox(height: 12),
              Text('Breed', style: AppFonts.semiBold(fontSize: 12)),
              CustomTextField(
                controller: _breedController,
                hintText: 'Optional',
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: isEditing ? 'Save Changes' : 'Add Pet',
                onPressed: () {
                  if (!(_formKey.currentState?.validate() ?? false)) {
                    return;
                  }
                  final name = _nameController.text.trim();
                  final breed = _breedController.text.trim();
                  if (isEditing) {
                    context.read<PetManagementBloc>().add(
                      PetManagementUpdate(
                        petId: widget.pet!.id,
                        name: name,
                        species: _species,
                        breed: breed.isEmpty ? null : breed,
                      ),
                    );
                  } else {
                    context.read<PetManagementBloc>().add(
                      PetManagementCreate(
                        clientId: widget.clientId,
                        name: name,
                        species: _species,
                        breed: breed.isEmpty ? null : breed,
                      ),
                    );
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onAction;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets, size: 46, color: AppColors.grey),
            const SizedBox(height: 12),
            Text(title, style: AppFonts.semiBold(fontSize: 18)),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppFonts.regular(fontSize: 12, color: AppColors.darkGrey),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionText)),
          ],
        ),
      ),
    );
  }
}
