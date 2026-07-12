// MoodScreen: allows the user to log their daily mood (emoji) and select
// detail chips (e.g. "Tired", "Exam stress") for a specific date.
// On first check-in of the day, the user earns +5 stars (coins).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For formatting the date displayed in the header
import '../providers/user_provider.dart';
import 'package:TwiC/utils/app_colors.dart';

// StatefulWidget because the screen holds mutable state (selected mood, chips, saving flag)
class MoodScreen extends StatefulWidget {
  final DateTime? date; // Optional date parameter; if null, defaults to today
  const MoodScreen({super.key, this.date});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  // --- Local state variables ---
  int _selectedMoodIndex = 2; // Currently selected emoji index (0-4). Default: neutral 😐
  List<String> _selectedChips = ['tired']; // Currently selected detail chips. Default: "Tired"
  bool _isSaving = false; // True while the save operation is in progress (disables button)
  bool _isAlreadySaved = false; // True if the user has already saved a check-in for this date
  bool _isLoading = true; // True until provider data has been loaded into local state

  // The 5 mood emojis displayed as selectable circles (index 0 = sad, 4 = very happy)
  final List<String> _emojis = ['😔', '😟', '😐', '🙂', '😄'];
  
  // Detail chips: each chip has a unique id, a display label, a selected border color,
  // and a soft background color. These are toggled on/off by tapping.
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
      'color': AppColors.purple, // Purple
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
    {
      'id': 'worked out',
      'label': 'Worked out',
      'color': const Color(0xFFFBC02D), // Yellow
      'bgColor': const Color(0xFFFFECB3),
      },
    {
      'id': 'relaxed',
      'label': 'Relaxed',
      'color': const Color(0xFFE91E63), // Pink
      'bgColor': const Color(0xFFFCE4EC),
    }
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFromProvider();
    });
  }

  // Initializes local state from the UserProvider.
  // If the provider is still loading data, we register a listener and wait;
  // otherwise we update immediately.
  void _initFromProvider() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.isLoading) {
      userProvider.addListener(_onProviderUpdated); // Wait for data to be ready
    } else {
      _updateLocalState(userProvider); // Data already available, sync now
    }
  }

  // Callback fired when the UserProvider notifies its listeners.
  // Once loading is complete, we remove the listener (one-shot) and sync local state.
  void _onProviderUpdated() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoading) {
      userProvider.removeListener(_onProviderUpdated);
      _updateLocalState(userProvider);
    }
  }

  // Reads the saved mood data for the target date from the provider
  // and updates the local state variables accordingly.
  // If no mood was saved yet (returns -1), defaults to neutral (index 2).
  void _updateLocalState(UserProvider userProvider) {
    if (mounted) {
      final targetDate = widget.date ?? DateTime.now();
      setState(() {
        _selectedMoodIndex = userProvider.getSavedMoodForDate(targetDate) == -1 ? 2 : userProvider.getSavedMoodForDate(targetDate);
        _selectedChips = List<String>.from(userProvider.getSavedChipsForDate(targetDate));
        _isAlreadySaved = userProvider.isMoodDoneForDate(targetDate);
        _isLoading = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant MoodScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
      _initFromProvider();
    }
  }

  @override
  void dispose() {
    try {
      Provider.of<UserProvider>(context, listen: false).removeListener(_onProviderUpdated);
    } catch (_) {}
    super.dispose();
  }

  // Saves the current mood index and selected chips to the UserProvider.
  // If this is the first check-in of the day, the user earns +5 stars (coins).
  // After saving, a success dialog is shown.
  Future<void> _saveCheckIn() async {
    setState(() {
      _isSaving = true; // Disable the button while saving
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final targetDate = widget.date ?? DateTime.now();
    // saveCheckIn returns true if coins were added (first check-in of the day)
    final coinsAdded = await userProvider.saveCheckIn(_selectedMoodIndex, _selectedChips, date: targetDate);

    if (mounted) {
      setState(() {
        _isAlreadySaved = true; // Mark as saved so the button text changes to "Update"
        _isSaving = false;
      });

      // Show a success dialog informing the user about the saved check-in
      showDialog(
        context: context,
        barrierDismissible: false, // User must tap the button to dismiss
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Dialog wraps its content height
                children: [
                  const SizedBox(height: 16),
                  // Title changes based on whether coins were earned or mood was just updated
                  Text(
                    coinsAdded ? 'Check-in Saved! 🎉' : 'Mood Updated!',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtitle: shows reward info on first save, or update confirmation
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
                  // Dismiss button to close the dialog
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD158),
                      foregroundColor: AppColors.textDark,
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
  
  // Generates a personalized insight message based on the selected chips.
  // If no chips are selected, shows a prompt encouraging the user to select some.
  // The message combines chip descriptions into a natural-language sentence
  // and appends motivational advice.
  String _getInsightText(List<String> chips, String chickName) {
    if (chips.isEmpty) {
      return "Select what happened today to get insights from $chickName!";
    }
    
    // Maps each chip ID to a descriptive phrase used to build the insight sentence
    final Map<String, String> descriptions = {
      'studied': ' you put time and effort into your goals',
      'tired': ' it\'s okay to slow down and rest if you need to',
      'slept_well': ' you had a good night\'s sleep, it can make a big difference',
      'exam_stress': ' you are stressed about an exam, but remember that exams doesn\'t define your worth',
      'worked out': ' you took care of your body and mind through exercise',
      'relaxed': ' you took time to relax and recharge, which is important for your well-being',
    };

    // Collect the description phrases for all currently selected chips
    List<String> activePhrases = [];
    for (var chip in chips) {
      if (descriptions.containsKey(chip)) {
        activePhrases.add(descriptions[chip]!);
      }
    }

    // Build the final summary string by joining the phrases with commas.
    // Handles 1, 2, or 3+ phrases with proper grammar.
    String summary = "";
    if (activePhrases.length == 1) {
      summary = "Today${activePhrases[0]}.";
    } else if (activePhrases.length == 2) {
      summary = "Today${activePhrases[0]}, ${activePhrases[1]}.";
    } else {
      String primary = activePhrases.sublist(0, activePhrases.length - 1).join(", ");
      String last = activePhrases.last;
      summary = "Today$primary ;$last.";
    }
    // Append motivational advice at the end of the insight.
    // If the user is stressed about exams, show a specific supportive message.
    String advice = "";
    if (chips.contains('exam_stress')) {
      advice = " Make sure to listen to your body and take breaks when needed."; 
      } else {
        advice = " Keep going! You're making progress, even if it doesn't always feel like it! :)";
      }
      return "$summary$advice";
  }

  @override
  Widget build(BuildContext context) {
    // While provider data is loading, show a centered spinner
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.green),
          ),
        ),
      );
    }

    // Consumer rebuilds the UI whenever UserProvider notifies listeners
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView( // Scrollable to handle small screens / keyboard
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
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Date display
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.purple),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('EEEE, d MMM yyyy').format(widget.date ?? DateTime.now()),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Header subtitle
                  Text(
                    '${userProvider.chickName} wants to know, it only takes a second!',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7A78A0),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Displays 5 emoji circles in a row. The selected one gets a
                  // green border and glow shadow; unselected ones are plain.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_emojis.length, (index) {
                      final isSelected = _selectedMoodIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMoodIndex = index; // Update the selected mood
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
                                    color: AppColors.green, // Green outline color (app branding)
                                    width: 2.5,
                                  )
                                : Border.all(
                                    color: Colors.grey.withOpacity(0.15),
                                    width: 1,
                                  ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.green.withOpacity(0.2),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
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


                  const Text(
                    'Anything in particular?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Uses Wrap to flow chips into multiple rows.
                  // Each chip toggles on/off independently. Selected chips get
                  // a white background with colored border; unselected ones use
                  // a soft pastel background.
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
                          // Toggle chip selection on/off
                          setState(() {
                            if (isSelected) {
                              _selectedChips.remove(chipId);
                            } else {
                              _selectedChips.add(chipId);
                            }
                          });
                        },
                        // AnimatedContainer smoothly transitions colors/borders on selection change
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
                                      color: color.withOpacity(0.15),
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
                  Divider(color: Colors.black.withOpacity(0.06), height: 1),
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
                          _getInsightText(_selectedChips, userProvider.chickName),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2E7D32).withOpacity(0.9), // Matching dark green body
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Disabled while saving (_isSaving). Shows "Save check-in (+5 coins)"
                  // on first save, or "Update check-in" if already saved for this date.
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _saveCheckIn, // Disabled during save
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.green, width: 1.5), // App green border
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.textDark,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Button label changes based on whether a check-in exists
                          Text(
                            _isAlreadySaved
                                ? 'Update check-in'
                                : 'Save check-in (+5 coins)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.north_east_rounded,
                            size: 18,
                            color: AppColors.green, // Green arrow icon
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