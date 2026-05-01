bool isMentorRole(dynamic roleValue) {
  final normalized = roleValue?.toString().trim().toLowerCase();
  return normalized == 'mentor';
}

bool isStudentRole(dynamic roleValue) {
  final normalized = roleValue?.toString().trim().toLowerCase();
  return normalized == 'student' || normalized == 'user';
}
