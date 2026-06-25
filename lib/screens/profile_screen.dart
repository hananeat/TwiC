import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:TwiC/providers/user_provider.dart';
import 'package:TwiC/utils/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();

    //Per mostrare i dati dell'utente
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.yellow,
        title: const Text('Profile'),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: user.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _profileTile(Icons.flutter_dash, 'Chick Name', user.chickName),
                    _profileTile(Icons.person, 'First Name', user.firstName),
                    _profileTile(Icons.person_outline, 'Last Name', user.lastName),
                    _profileTile(Icons.wc, 'Sex', user.sex),
                    _profileTile(Icons.cake, 'Age', '${user.age}'),
                    _profileTile(Icons.star, 'Stars', '${user.stars}'),
                  ],
                ),
              ),
            ),
    );
  }

  //creo un widget per ogni informazione
  Widget _profileTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container (
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
                Text(label, style: TextStyle(fontSize: 12 ,
                    color: AppColors.textDark.withOpacity(0.6))),
                Text(value, style: const TextStyle(
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
}
