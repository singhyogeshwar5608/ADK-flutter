class ApiConfig {
  static const String baseUrl = 'https://www.offerlifetime.com/api/v1';

  /// Send on JSON API calls — especially Flutter **web**.
  ///
  /// Without [Accept]/[X-Requested-With], Laravel may treat the caller as a
  /// browser and redirect to the SPA/root URL (`APP_URL`/localhost). Fetch then
  /// follows that redirect and fails CORS (“No Access-Control-Allow-Origin”).
  static const Map<String, String> jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-Requested-With': 'XMLHttpRequest',
  };
}
