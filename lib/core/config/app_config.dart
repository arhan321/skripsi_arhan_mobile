class AppConfig {
  const AppConfig._();

  /// Ganti sesuai domain Laravel kamu.
  /// Mobile sebaiknya call Laravel API, bukan langsung ke FastAPI ML.
  static const String apiBaseUrl = 'https://prediksi.djncloud.my.id/api';

  static const String appName = 'TourHub Bali';
}
