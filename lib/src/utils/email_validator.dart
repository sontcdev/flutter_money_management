final _emailPattern = RegExp(r'^[\w\-.+]+@([\w-]+\.)+[\w-]{2,}$');

bool isValidEmail(String email) => _emailPattern.hasMatch(email.trim());
