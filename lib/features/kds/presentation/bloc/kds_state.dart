abstract class KdsState {}

class KdsInitial extends KdsState {}

class KdsLoading extends KdsState {}

class KdsLoaded extends KdsState {
  final List<dynamic> tickets;
  final String username;
  final String userRole;
  final bool isBarman;
  final String currentUserId;


  KdsLoaded({
    required this.tickets,
    required this.username,
    required this.userRole,
    this.isBarman = false,
    required this.currentUserId,
  });
}

class KdsError extends KdsState {
  final String message;
  KdsError(this.message);
}