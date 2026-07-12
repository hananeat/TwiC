// ProfileScreen is a Flutter widget that displays the user's profile information
// and allows the user to edit it. It uses the UserProvider to get the user's data
// and the UserProvider to update it.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:TwiC/providers/user_provider.dart';
import 'package:TwiC/utils/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;

  // Controllers for the text input fields
  late TextEditingController _chickNameController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late String _selectedSex;
  late DateTime? _selectedDateOfBirth;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>();
    _chickNameController = TextEditingController(text: user.chickName);
    _firstNameController = TextEditingController(text: user.firstName);
    _lastNameController = TextEditingController(text: user.lastName);
    _selectedSex = user.sex;
    _selectedDateOfBirth = user.dateOfBirth;
  }

  @override
  void dispose() {
    _chickNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  /// Enters edit mode
  void _startEditing() {
    final user = context.read<UserProvider>();
    setState(() {
      _isEditing = true;
      _chickNameController.text = user.chickName;
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _selectedSex = user.sex;
      _selectedDateOfBirth = user.dateOfBirth;
    });
  }

  /// Cancels the changes and returns to view mode
  void _cancelEditing() {
    setState(() {
      _isEditing = false;
    });
  }

  /// Saves the changes to UserProvider (and therefore to SharedPreferences)
  Future<void> _saveChanges() async {
    final chickName = _chickNameController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    // Validation
    if (chickName.isEmpty || firstName.isEmpty || lastName.isEmpty || _selectedDateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All fields are required.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = context.read<UserProvider>();

    // Save the chick name
    await user.setChickName(chickName);

    // Save the user profile
    await user.setUserProfile(firstName, lastName, _selectedSex, _selectedDateOfBirth!);

    if (mounted) {
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated!'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.yellow,
        title: const Text('Profile'),
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: AppColors.textDark),
              tooltip: 'Edit profile',
              onPressed: _startEditing,
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.textDark),
              tooltip: 'Cancel',
              onPressed: _cancelEditing,
            ),
            IconButton(
              icon: const Icon(Icons.check_rounded, color: AppColors.textDark),
              tooltip: 'Save',
              onPressed: _saveChanges,
            ),
          ],
        ],
      ),
      body: user.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Editable fields ---
                    _isEditing
                        ? _editableTile(Icons.pets_rounded, 'Chick Name', _chickNameController)
                        : _profileTile(Icons.pets_rounded, 'Chick Name', user.chickName),

                    _isEditing
                        ? _editableTile(Icons.person, 'First Name', _firstNameController)
                        : _profileTile(Icons.person, 'First Name', user.firstName),

                    _isEditing
                        ? _editableTile(Icons.person_outline, 'Last Name', _lastNameController)
                        : _profileTile(Icons.person_outline, 'Last Name', user.lastName),

                    _isEditing
                        ? _editableSexTile()
                        : _profileTile(Icons.sentiment_satisfied_alt_rounded, 'Sex', user.sex),

                    _isEditing
                        ? _editableDateTile()
                        : _profileTile(
                            Icons.cake,
                            'Date of Birth',
                            user.dateOfBirth != null
                                ? '${user.dateOfBirth!.day.toString().padLeft(2, '0')}/${user.dateOfBirth!.month.toString().padLeft(2, '0')}/${user.dateOfBirth!.year}'
                                : 'Not set',
                          ),

                    // --- Read-only fields ---
                    _profileTile(Icons.hourglass_bottom_rounded, 'Age', '${user.age} years'),
                    _profileTile(Icons.star, 'Stars', '${user.stars}'),
                  ],
                ),
              ),
            ),
    );
  }

  // Read-only profile tile widget
  Widget _profileTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.textDark.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.yellow),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textDark.withOpacity(0.6))),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Editable profile tile widget (TextField)
  Widget _editableTile(IconData icon, String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.yellow, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.yellow),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textDark.withOpacity(0.6))),
                  TextField(
                    controller: controller,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                      border: InputBorder.none,
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

  // Sex selector (same style as the onboarding screen)
  Widget _editableSexTile() {
    final options = [
      {'id': 'Female', 'label': '♀ Female'},
      {'id': 'Male', 'label': '♂ Male'},
      {'id': 'Other', 'label': '◦ Other'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.yellow, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sentiment_satisfied_alt_rounded, color: AppColors.yellow),
                const SizedBox(width: 14),
                Text('Sex',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textDark.withOpacity(0.6))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: options.map((opt) {
                final isSelected = _selectedSex == opt['id'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSex = opt['id']!;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.yellow.withOpacity(0.25)
                            : AppColors.textDark.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.yellow
                              : Colors.grey.withOpacity(0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          opt['label']!,
                          style: TextStyle(
                            color: isSelected ? AppColors.textDark : AppColors.textDark.withOpacity(0.6),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Date picker for the date of birth
  Widget _editableDateTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _selectedDateOfBirth ?? DateTime(2005, 1, 1),
            firstDate: DateTime(1920),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppColors.yellow,
                    onPrimary: AppColors.textDark,
                    surface: AppColors.background,
                    onSurface: AppColors.textDark,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            setState(() {
              _selectedDateOfBirth = picked;
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.yellow, width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.cake, color: AppColors.yellow),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date of Birth',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textDark.withOpacity(0.6))),
                    const SizedBox(height: 4),
                    Text(
                      _selectedDateOfBirth != null
                          ? '${_selectedDateOfBirth!.day.toString().padLeft(2, '0')}/${_selectedDateOfBirth!.month.toString().padLeft(2, '0')}/${_selectedDateOfBirth!.year}'
                          : 'Tap to select',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark),
                    ),
                  ],
                ),
              ),
              Icon(Icons.calendar_today_rounded,
                  color: AppColors.yellow.withOpacity(0.7), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
