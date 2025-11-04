class HouseData {
  final int house; // 1..12
  final String sign; // e.g., "Aries"
  final List<String> planets; // e.g., ["Su","Me","Ke"]

  HouseData({required this.house, required this.sign, this.planets = const []});
}

class KundaliData {
  // 12 houses in order; house=1 is Lagna
  final List<HouseData> houses;

  KundaliData({required this.houses}) : assert(houses.length == 12);

  HouseData byHouse(int n) => houses.firstWhere((h) => h.house == n);
}
