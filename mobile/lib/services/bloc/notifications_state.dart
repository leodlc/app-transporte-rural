part of 'notifications_bloc.dart';

abstract class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object> get props => [];
}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsPermissionGranted extends NotificationsState {}

class NotificationsPermissionDenied extends NotificationsState {}

class NotificationsInitialized extends NotificationsState {
  final String? token;

  const NotificationsInitialized({this.token});

  @override
  List<Object> get props => [token ?? ''];
}

class NotificationDisplayed extends NotificationsState {
  final String title;
  final String body;

  const NotificationDisplayed({
    required this.title,
    required this.body,
  });

  @override
  List<Object> get props => [title, body];
}