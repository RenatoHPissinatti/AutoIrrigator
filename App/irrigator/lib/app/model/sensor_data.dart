class SensorData {
  final double solo;
  final double temperatura;
  final double umidadeAr;

  const SensorData({
    required this.solo,
    required this.temperatura,
    required this.umidadeAr,
  });

  factory SensorData.empty() =>
      const SensorData(solo: 0, temperatura: 0, umidadeAr: 0);

  factory SensorData.fromJson(Map<String, dynamic> json) => SensorData(
        solo: (json['solo'] as num).toDouble(),
        temperatura: (json['temperatura'] as num).toDouble(),
        umidadeAr: (json['umidadeAr'] as num).toDouble(),
      );

  String get soloFormatted => '${solo.round()}%';
  String get temperaturaFormatted => '${temperatura.toStringAsFixed(1)}°C';
  String get umidadeArFormatted => '${umidadeAr.round()}%';
}
