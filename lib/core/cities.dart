// Gecureerde stedenlijst voor de stad-picker (LOC-03).
//
// Stond tot 2026-09-19 alleen vol Nederlandse plaatsen, terwijl de gesloten
// test openstaat in Belgie, Italie, het VK en de VS. Een tester daar kon zijn
// eigen stad niet kiezen en bleef dus op Amsterdam staan -- wat hem het
// verkeerde weer op de verkeerde klok gaf.

class City {
  final String name;
  final double lat;
  final double lon;

  final String country;

  const City({
    required this.name,
    required this.lat,
    required this.lon,
    this.country = 'NL',
  });
}

const List<City> kCities = [
  City(name: 'Amsterdam', lat: 52.3676, lon: 4.9041),
  City(name: 'Rotterdam', lat: 51.9225, lon: 4.4792),
  City(name: 'Den Haag', lat: 52.0705, lon: 4.3007),
  City(name: 'Utrecht', lat: 52.0907, lon: 5.1214),
  City(name: 'Eindhoven', lat: 51.4416, lon: 5.4697),
  City(name: 'Groningen', lat: 53.2194, lon: 6.5665),
  City(name: 'Tilburg', lat: 51.5555, lon: 5.0913),
  City(name: 'Almere', lat: 52.3508, lon: 5.2647),
  City(name: 'Breda', lat: 51.5719, lon: 4.7683),
  City(name: 'Nijmegen', lat: 51.8425, lon: 5.8372),
  City(name: 'Leiden', lat: 52.1601, lon: 4.4970),
  City(name: 'Haarlem', lat: 52.3874, lon: 4.6462),

  // De vier andere landen van de gesloten test.
  City(name: 'Brussel', lat: 50.8503, lon: 4.3517, country: 'BE'),
  City(name: 'Antwerpen', lat: 51.2194, lon: 4.4025, country: 'BE'),
  City(name: 'Gent', lat: 51.0543, lon: 3.7174, country: 'BE'),
  City(name: 'Rome', lat: 41.9028, lon: 12.4964, country: 'IT'),
  City(name: 'Milaan', lat: 45.4642, lon: 9.1900, country: 'IT'),
  City(name: 'Bologna', lat: 44.4949, lon: 11.3426, country: 'IT'),
  City(name: 'Londen', lat: 51.5072, lon: -0.1276, country: 'GB'),
  City(name: 'Manchester', lat: 53.4808, lon: -2.2426, country: 'GB'),
  City(name: 'Edinburgh', lat: 55.9533, lon: -3.1883, country: 'GB'),
  City(name: 'New York', lat: 40.7128, lon: -74.0060, country: 'US'),
  City(name: 'San Francisco', lat: 37.7749, lon: -122.4194, country: 'US'),
  City(name: 'Chicago', lat: 41.8781, lon: -87.6298, country: 'US'),
  City(name: 'Austin', lat: 30.2672, lon: -97.7431, country: 'US'),
];
