import '../contract_support.dart';

final class NotificationDestination extends ContractValue {
  const NotificationDestination({this.route, this.arguments});
  final String? route;
  final JsonMap? arguments;
  factory NotificationDestination.fromJson(JsonMap json) =>
      NotificationDestination(
        route: asString(json['route']),
        arguments: asJsonMap(json['arguments'] ?? json['extra']),
      );
  JsonMap toJson() => {'route': route, 'arguments': arguments};
  NotificationDestination copyWith({
    Object? route = contractUnchanged,
    Object? arguments = contractUnchanged,
  }) => NotificationDestination(
    route: identical(route, contractUnchanged) ? this.route : route as String?,
    arguments: identical(arguments, contractUnchanged)
        ? this.arguments
        : arguments as JsonMap?,
  );
  @override
  List<Object?> get props => [route, arguments];
}

final class NotificationData extends ContractValue {
  const NotificationData({this.destination, this.payload});
  final NotificationDestination? destination;
  final JsonMap? payload;
  factory NotificationData.fromJson(JsonMap json) => NotificationData(
    destination: NotificationDestination.fromJson(json),
    payload: json,
  );
  JsonMap toJson() => {...?payload, ...?destination?.toJson()};
  NotificationData copyWith({
    Object? destination = contractUnchanged,
    Object? payload = contractUnchanged,
  }) => NotificationData(
    destination: identical(destination, contractUnchanged)
        ? this.destination
        : destination as NotificationDestination?,
    payload: identical(payload, contractUnchanged)
        ? this.payload
        : payload as JsonMap?,
  );
  @override
  List<Object?> get props => [destination, payload];
}

final class AppNotification extends ContractValue {
  const AppNotification({
    this.id,
    this.title,
    this.body,
    this.isRead,
    this.createdAt,
    this.data,
  });
  final int? id;
  final String? title;
  final String? body;
  final bool? isRead;
  final Object? createdAt;
  final NotificationData? data;
  factory AppNotification.fromJson(JsonMap json) => AppNotification(
    id: asInt(json['id'] ?? json['notification_id']),
    title: asString(json['title']),
    body: asString(json['body'] ?? json['message']),
    isRead: asBool(json['is_read'] ?? json['isRead'] ?? json['read']),
    createdAt: json['created_at'] ?? json['createdAt'],
    data: asModel(json['data'], NotificationData.fromJson),
  );
  JsonMap toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'is_read': isRead,
    'created_at': createdAt,
    'data': data?.toJson(),
  };
  AppNotification copyWith({
    Object? id = contractUnchanged,
    Object? title = contractUnchanged,
    Object? body = contractUnchanged,
    Object? isRead = contractUnchanged,
    Object? createdAt = contractUnchanged,
    Object? data = contractUnchanged,
  }) => AppNotification(
    id: identical(id, contractUnchanged) ? this.id : id as int?,
    title: identical(title, contractUnchanged) ? this.title : title as String?,
    body: identical(body, contractUnchanged) ? this.body : body as String?,
    isRead: identical(isRead, contractUnchanged)
        ? this.isRead
        : isRead as bool?,
    createdAt: identical(createdAt, contractUnchanged)
        ? this.createdAt
        : createdAt,
    data: identical(data, contractUnchanged)
        ? this.data
        : data as NotificationData?,
  );
  @override
  List<Object?> get props => [id, title, body, isRead, createdAt, data];
}

final class NotificationListResponse extends ContractValue {
  const NotificationListResponse({this.notifications});
  final List<AppNotification>? notifications;
  factory NotificationListResponse.fromJson(Object? json) {
    final list = json is List
        ? json
        : asJsonMap(json)?['notifications'] as List?;
    return NotificationListResponse(
      notifications: asModelList(list, AppNotification.fromJson),
    );
  }
  JsonMap toJson() => {
    'notifications': modelsToJson(notifications, (item) => item.toJson()),
  };
  NotificationListResponse copyWith({
    Object? notifications = contractUnchanged,
  }) => NotificationListResponse(
    notifications: identical(notifications, contractUnchanged)
        ? this.notifications
        : notifications as List<AppNotification>?,
  );
  @override
  List<Object?> get props => [notifications];
}

final class UnreadCountResponse extends ContractValue {
  const UnreadCountResponse({this.unreadCount});
  final int? unreadCount;
  factory UnreadCountResponse.fromJson(JsonMap json) => UnreadCountResponse(
    unreadCount: asInt(json['unread_count'] ?? json['unreadCount']),
  );
  JsonMap toJson() => {'unread_count': unreadCount};
  UnreadCountResponse copyWith({Object? unreadCount = contractUnchanged}) =>
      UnreadCountResponse(
        unreadCount: identical(unreadCount, contractUnchanged)
            ? this.unreadCount
            : unreadCount as int?,
      );
  @override
  List<Object?> get props => [unreadCount];
}

final class MarkNotificationReadRequest extends ContractValue {
  const MarkNotificationReadRequest({this.notificationId});
  final int? notificationId;
  factory MarkNotificationReadRequest.fromJson(JsonMap json) =>
      MarkNotificationReadRequest(
        notificationId: asInt(
          json['notification_id'] ?? json['notificationId'],
        ),
      );
  JsonMap toJson() => {'notification_id': notificationId};
  MarkNotificationReadRequest copyWith({
    Object? notificationId = contractUnchanged,
  }) => MarkNotificationReadRequest(
    notificationId: identical(notificationId, contractUnchanged)
        ? this.notificationId
        : notificationId as int?,
  );
  @override
  List<Object?> get props => [notificationId];
}
