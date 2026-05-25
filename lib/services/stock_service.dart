class StockService {

  static int remainingDays({
    required int stock,
    required int dailyDose,
  }) {

    if (dailyDose == 0) return 0;

    return (stock / dailyDose).floor();
  }

  static bool isLowStock({
    required int stock,
    required int dailyDose,
  }) {

    int daysLeft =
    remainingDays(
      stock: stock,
      dailyDose: dailyDose,
    );

    return daysLeft <= 3;
  }
}