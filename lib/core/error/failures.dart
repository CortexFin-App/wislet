abstract class AppFailure {
  final String userMessage;
  final dynamic debugDetails;

  AppFailure({required this.userMessage, this.debugDetails});
}

class NetworkFailure extends AppFailure {
  NetworkFailure({String message = 'Помилка мережі. Перевірте з\'єднання.', dynamic details})
  : super(userMessage: message, debugDetails: details);
}

class DatabaseFailure extends AppFailure {
  DatabaseFailure({String message = 'Помилка бази даних.', dynamic details})
  : super(userMessage: message, debugDetails: details);
}

class AuthFailure extends AppFailure {
  AuthFailure({required String message, dynamic details})
  : super(userMessage: message, debugDetails: details);
}

class UnexpectedFailure extends AppFailure {
  UnexpectedFailure({String message = 'Сталася непередбачувана помилка.', dynamic details})
  : super(userMessage: message, debugDetails: details);
}