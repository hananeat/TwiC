import 'dart:math';

class GoalReward {
  final int stepsTarget;
  final int stepsPoints;
  final bool stepsDone;
  final double stepsProgress;

  final int sleepTargetMinutes;
  final int sleepPoints;
  final bool sleepDone;
  final double sleepProgress;

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

class GoalCalculation {
  /// Calcola i target e i punti per passi e sonno in base all'età dell'utente
  static GoalReward calculate({
    required int age,
    required int steps,
    required int sleepMinutes,
  }) {
    int stepsTarget = 10000;
    int stepsPoints = 0;
    int stepsMinPartial = 6000;

    int sleepTargetMinutes = 480; 
    int sleepPoints = 0;
    int sleepMinPartial = 360; 

    // 1. Logica in base alla Fascia d'Età
    if (age <= 17) {
      stepsTarget = 10000;
      stepsMinPartial = 6000;
      sleepTargetMinutes = 540; // 9 ore
      sleepMinPartial = 420;    // 7 ore
    } 
    else if (age >= 18 && age <= 59) {
      stepsTarget = 10000;
      stepsMinPartial = 6000;
      sleepTargetMinutes = 480; // 8 ore
      sleepMinPartial = 360;    // 6 ore
    } 
    else if (age >= 60 && age <= 64) {
      stepsTarget = 7500;
      stepsMinPartial = 4500;
      sleepTargetMinutes = 480; // 8 ore
      sleepMinPartial = 360;    // 6 ore
    } 
    else {
      stepsTarget = 7500;
      stepsMinPartial = 4500;
      sleepTargetMinutes = 450; // 7.5 ore
      sleepMinPartial = 330;    // 5.5 ore
    }

    // 2. Calcolo dei punti per i Passi
    if (steps >= stepsTarget) {
      stepsPoints = 7;
    } else if (steps >= stepsMinPartial) {
      stepsPoints = 3;
    }

    // 3. Calcolo dei punti per il Sonno
    if (sleepMinutes >= sleepTargetMinutes) {
      sleepPoints = 10;
    } else if (sleepMinutes >= sleepMinPartial) {
      sleepPoints = 5;
    }

    // 4. Calcolo progresso grafico (clamp tra 0.0 e 1.0)
    double stepsProgress = stepsTarget > 0 ? (steps / stepsTarget).clamp(0.0, 1.0) : 0.0;
    double sleepProgress = sleepTargetMinutes > 0 ? (sleepMinutes / sleepTargetMinutes).clamp(0.0, 1.0) : 0.0;

    return GoalReward(
      stepsTarget: stepsTarget,
      stepsPoints: stepsPoints,
      stepsDone: steps >= stepsMinPartial,
      stepsProgress: stepsProgress,
      sleepTargetMinutes: sleepTargetMinutes,
      sleepPoints: sleepPoints,
      sleepDone: sleepMinutes >= sleepMinPartial,
      sleepProgress: sleepProgress,
      totalPoints: stepsPoints + sleepPoints,
    );
  }
}