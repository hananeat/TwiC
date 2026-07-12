// GoalReward is a data class that holds the calculated goal results for steps and sleep.
// It contains the target values, earned points, completion status,
// and progress percentage for each metric.

class GoalReward {
  // Steps goal fields
  final int stepsTarget;       // Target number of steps for the day
  final int stepsPoints;       // Points earned based on steps achieved
  final bool stepsDone;        // Whether the minimum step threshold was reached
  final double stepsProgress;  // Progress ratio (0.0 to 1.0) towards the steps target

  // Sleep goal fields
  final int sleepTargetMinutes;  // Target sleep duration in minutes
  final int sleepPoints;         // Points earned based on sleep achieved
  final bool sleepDone;          // Whether the minimum sleep threshold was reached
  final double sleepProgress;    // Progress ratio (0.0 to 1.0) towards the sleep target

  // Total points earned from both steps and sleep combined
  final int totalPoints;

  GoalReward({
    required this.stepsTarget,
    required this.stepsPoints,
    required this.stepsDone,
    required this.stepsProgress,
    required this.sleepTargetMinutes,
    required this.sleepPoints,
    required this.sleepDone,
    required this.sleepProgress,
    required this.totalPoints,
  });
}

// GoalCalculation is a utility class that computes daily goal targets and reward points
// based on the user's age group. Targets and thresholds follow
// age-specific health guidelines for physical activity and sleep.
//
// References:
// - Steps targets: Paluch et al., The Lancet Public Health, 2022
//   https://www.thelancet.com/journals/lanpub/article/PIIS2468-2667(21)00302-9/fulltext
// - Steps targets: Saint-Maurice et al., JAMA Internal Medicine, 2020
//   https://jamanetwork.com/journals/jamainternalmedicine/fullarticle/2734709
// - Sleep targets: Hirshkowitz et al., Sleep Health, 2015
//   https://www.sleephealthjournal.org/article/S2352-7218(15)00015-7/fulltext

class GoalCalculation {
  // Calculates targets and points for steps and sleep based on the user's age.
  // Returns a GoalReward containing all computed values.
  static GoalReward calculate({
    required int age,
    required int steps,
    required int sleepMinutes,
  }) {
    // Default targets (will be overridden by age-specific logic below)
    int stepsTarget = 10000;
    int stepsPoints = 0;
    int stepsMinPartial = 6000; // Minimum steps for partial reward

    int sleepTargetMinutes = 480; // 8 hours
    int sleepPoints = 0;
    int sleepMinPartial = 360;   // 6 hours

    // 1. Set targets based on the user's age group
    if (age <= 17) {
      // Children and adolescents: higher sleep requirement
      stepsTarget = 10000;
      stepsMinPartial = 6000;
      sleepTargetMinutes = 540; // 9 hours
      sleepMinPartial = 420;    // 7 hours
    } 
    else if (age >= 18 && age <= 59) {
      // Adults: standard targets
      stepsTarget = 10000;
      stepsMinPartial = 6000;
      sleepTargetMinutes = 480; // 8 hours
      sleepMinPartial = 360;    // 6 hours
    } 
    else if (age >= 60 && age <= 64) {
      // Early seniors: reduced step target
      stepsTarget = 7500;
      stepsMinPartial = 4500;
      sleepTargetMinutes = 480; // 8 hours
      sleepMinPartial = 360;    // 6 hours
    } 
    else {
      // Seniors (65+): reduced step and sleep targets
      stepsTarget = 7500;
      stepsMinPartial = 4500;
      sleepTargetMinutes = 450; // 7.5 hours
      sleepMinPartial = 330;    // 5.5 hours
    }

    // 2. Calculate points for steps
    // Full reward (7 pts) if target is met, partial reward (3 pts) if minimum threshold is reached
    if (steps >= stepsTarget) {
      stepsPoints = 7;
    } else if (steps >= stepsMinPartial) {
      stepsPoints = 3;
    }

    // 3. Calculate points for sleep
    // Full reward (10 pts) if target is met, partial reward (5 pts) if minimum threshold is reached
    if (sleepMinutes >= sleepTargetMinutes) {
      sleepPoints = 10;
    } else if (sleepMinutes >= sleepMinPartial) {
      sleepPoints = 5;
    }

    // 4. Calculate progress for the UI progress bars (clamped between 0.0 and 1.0)
    double stepsProgress = stepsTarget > 0 ? (steps / stepsTarget).clamp(0.0, 1.0) : 0.0;
    double sleepProgress = sleepTargetMinutes > 0 ? (sleepMinutes / sleepTargetMinutes).clamp(0.0, 1.0) : 0.0;

    return GoalReward(
      stepsTarget: stepsTarget,
      stepsPoints: stepsPoints,
      stepsDone: steps >= stepsMinPartial,       // Goal is "done" if at least the partial threshold is met
      stepsProgress: stepsProgress,
      sleepTargetMinutes: sleepTargetMinutes,
      sleepPoints: sleepPoints,
      sleepDone: sleepMinutes >= sleepMinPartial, // Goal is "done" if at least the partial threshold is met
      sleepProgress: sleepProgress,
      totalPoints: stepsPoints + sleepPoints,     // Sum of steps and sleep points
    );
  }
}