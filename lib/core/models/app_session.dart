class AppSession {
  final String token;
  final String username;
  final DateTime authenticatedAt;

  const AppSession({
    required this.token,
    required this.username,
    required this.authenticatedAt,
  });
}
