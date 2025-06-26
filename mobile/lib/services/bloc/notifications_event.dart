part of 'notifications_bloc.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object> get props => [];
}

class InitializeNotifications extends NotificationsEvent {}

class RequestPermissions extends NotificationsEvent {}

class TokenReceived extends NotificationsEvent {
  final String token;

  const TokenReceived(this.token);

  @override
  List<Object> get props => [token];
}

class NotificationReceived extends NotificationsEvent {
  final String title;
  final String body;
  final Map<String, dynamic> data;

  const NotificationReceived({
    required this.title,
    required this.body,
    required this.data,
  });

  @override
  List<Object> get props => [title, body, data];
}