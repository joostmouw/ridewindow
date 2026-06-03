// Gecureerde lijst van NL steden voor de stad-picker (LOC-03, v1).

class NlCity {
  final String name;
  final double lat;
  final double lon;

  const NlCity({required this.name, required this.lat, required this.lon});
}

const List<NlCity> kNlCities = [
  NlCity(name: 'Amsterdam', lat: 52.3676, lon: 4.9041),
  NlCity(name: 'Rotterdam', lat: 51.9225, lon: 4.4792),
  NlCity(name: 'Den Haag', lat: 52.0705, lon: 4.3007),
  NlCity(name: 'Utrecht', lat: 52.0907, lon: 5.1214),
  NlCity(name: 'Eindhoven', lat: 51.4416, lon: 5.4697),
  NlCity(name: 'Groningen', lat: 53.2194, lon: 6.5665),
  NlCity(name: 'Tilburg', lat: 51.5555, lon: 5.0913),
  NlCity(name: 'Almere', lat: 52.3508, lon: 5.2647),
  NlCity(name: 'Breda', lat: 51.5719, lon: 4.7683),
  NlCity(name: 'Nijmegen', lat: 51.8425, lon: 5.8372),
  NlCity(name: 'Leiden', lat: 52.1601, lon: 4.4970),
  NlCity(name: 'Haarlem', lat: 52.3874, lon: 4.6462),
];
