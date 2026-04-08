class SchoolCredential {
  const SchoolCredential({required this.username, required this.password});

  final String username;
  final String password;

  String get maskedUsername {
    if (username.length <= 4) {
      return username;
    }
    return '${username.substring(0, 2)}****${username.substring(username.length - 2)}';
  }
}
