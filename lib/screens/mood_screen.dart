import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  int _selectedMoodIndex = 2; // Default to neutral 😐 
  List<String> _selectedChips = ['tired']; // Default to "Tired" 
  bool _isSaving = false;
  bool _isAlreadySaved = false;
  bool _isLoading = true;

  final List<String> _emojis = ['😔', '😟', '😐', '🙂', '😄'];
  
  final List<Map<String, dynamic>> _chipData = [
    {
      'id': 'studied',
      'label': 'I studied',
      'color': const Color(0xFF3DBF7A), // Mint green
      'bgColor': const Color(0xFFE8F5E9),
    },
    {
      'id': 'tired',
      'label': 'Tired',
      'color': const Color(0xFF5D59B5), // Purple
      'bgColor': const Color(0xFFEDE7F6),
    },
    {
      'id': 'slept_well',
      'label': 'Slept well',
      'color': const Color(0xFF3BAEE8), // Blue
      'bgColor': const Color(0xFFE3F2FD),
    },
    {
      'id': 'exam_stress',
      'label': 'Exam stress',
      'color': const Color(0xFFE85C3B), // Red-orange
      'bgColor': const Color(0xFFFBE9E7),
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFromProvider();
    });
  }

  void _initFromProvider() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.isLoading) {
      userProvider.addListener(_onProviderUpdated);
    } else {
      _updateLocalState(userProvider);
    }
  }

  void _onProviderUpdated() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoading) {
      userProvider.removeListener(_onProviderUpdated);
      _updateLocalState(userProvider);
    }
  }

  void _updateLocalState(UserProvider userProvider) {
    if (mounted) {
      setState(() {
        _selectedMoodIndex = userProvider.savedMood == -1 ? 2 : userProvider.savedMood;
        _selectedChips = List<String>.from(userProvider.savedChips);
        _isAlreadySaved = userProvider.moodDone;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    try {
      Provider.of<UserProvider>(context, listen: false).removeListener(_onProviderUpdated);
    } catch (_) {}
    super.dispose();
  }

  Future<void> _saveCheckIn() async {
    setState(() {
      _isSaving = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final coinsAdded = await userProvider.saveCheckIn(_selectedMoodIndex, _selectedChips);

    if (mounted) {
      setState(() {
        _isAlreadySaved = true;
        _isSaving = false;
      });

      // Show a premium Success Dialog with the hatching chick Lottie animation!
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    coinsAdded ? 'Check-in Saved! 🎉' : 'Mood Updated!',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2A2859),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    coinsAdded
                        ? 'You earned +5 stars! ${userProvider.chickName} is super happy!'
                        : 'Your mood details have been updated successfully!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD158),
                      foregroundColor: const Color(0xFF2A2859),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                    ),
                    child: const Text(
                      'Awesome!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFFDE7),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
          ),
        ),
      );
    }

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFFFFDE7),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // Header title
                  const Text(
                    'How do you feel now?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2A2859),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Header subtitle
                  Text(
                    '${userProvider.chickName} wants to know, it only takes a second!',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7A78A0),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mood selector Emojis
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_emojis.length, (index) {
                      final isSelected = _selectedMoodIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMoodIndex = index;
                          });
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: const Color(0xFF4CAF50), // Green outline color (app branding)
                                    width: 2.5,
                                  )
                                : Border.all(
                                    color: Colors.grey.withValues(alpha: 0.15),
                                    width: 1,
                                  ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _emojis[index],
                            style: const TextStyle(
                              fontSize: 30,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),

                  // "Anything in particular?"
                  const Text(
                    'Anything in particular?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2A2859),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Detail Chips Wrap
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _chipData.map((chip) {
                      final String chipId = chip['id'] as String;
                      final String label = chip['label'] as String;
                      final Color color = chip['color'] as Color;
                      final Color bgColor = chip['bgColor'] as Color;
                      final bool isSelected = _selectedChips.contains(chipId);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedChips.remove(chipId);
                            } else {
                              _selectedChips.add(chipId);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : bgColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected ? color : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.15),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Divider
                  Divider(color: Colors.black.withValues(alpha: 0.06), height: 1),
                  const SizedBox(height: 24),

                  // Insight Card (styled in light green with dark green text to align with the app's yellow/green theme)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9), // Light green background
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFC8E6C9),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${userProvider.chickName}'s Insight",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32), // Dark green title
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "coming soon!",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2E7D32).withValues(alpha: 0.9), // Matching dark green body
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save check-in Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _saveCheckIn,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF4CAF50), width: 1.5), // App green border
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2A2859),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isAlreadySaved
                                ? 'Update check-in'
                                : 'Save check-in (+5 coins)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2A2859),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.north_east_rounded,
                            size: 18,
                            color: Color(0xFF4CAF50), // Green arrow icon
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}