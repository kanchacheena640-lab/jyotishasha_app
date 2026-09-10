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

/// N6 -- Campaign C's frozen N3/N4 navigation action, as carried by a Bell
/// item's own `campaign_action` key (`{type, target, parameters}`).
/// Deliberately a SEPARATE type from [NotificationDestination] (A/B's own
/// `route`/`arguments` shape) -- the two are not interchangeable, and
/// nothing here widens the frozen action registry; it only carries
/// whatever the backend already validated at composer-save time.
final class CampaignBellAction extends ContractValue {
  const CampaignBellAction({this.type, this.target, this.parameters});
  final String? type;
  final String? target;
  final JsonMap? parameters;
  factory CampaignBellAction.fromJson(JsonMap json) => CampaignBellAction(
    type: asString(json['type']),
    target: asString(json['target']),
    parameters: asJsonMap(json['parameters']),
  );
  JsonMap toJson() => {'type': type, 'target': target, 'parameters': parameters};
  @override
  List<Object?> get props => [type, target, parameters];
}

final class AppNotification extends ContractValue {
  const AppNotification({
    this.id,
    this.itemId,
    this.source,
    this.title,
    this.body,
    this.isRead,
    this.createdAt,
    this.data,
    this.campaignAction,
    this.campaignId,
    this.executionId,
  });
  /// Legacy best-effort integer id -- null for every row under the N6
  /// unified list response (composite string ids only, see [itemId]).
  /// Kept only so any old call site that still reads `.id` fails safe
  /// (null) rather than throwing.
  final int? id;
  /// N6 -- the backend-supplied composite Bell identity (`"ab:<int>"` /
  /// `"cc:<uuid>"`), used verbatim for mark-read/dismiss. Never
  /// reconstructed client-side.
  final String? itemId;
  /// N6 -- "AB" or "ADMIN_CAMPAIGN". Null for a pre-N6 backend response
  /// shape (treated as "AB" by every call site below, matching the only
  /// behavior that existed before this field did).
  final String? source;
  final String? title;
  final String? body;
  final bool? isRead;
  final Object? createdAt;
  final NotificationData? data;
  /// N6 -- present only for a Campaign C ("ADMIN_CAMPAIGN") row.
  final CampaignBellAction? campaignAction;
  final String? campaignId;
  final String? executionId;
  factory AppNotification.fromJson(JsonMap json) => AppNotification(
    id: asInt(json['id'] ?? json['notification_id']),
    itemId: asString(json['id']),
    source: asString(json['source']),
    title: asString(json['title']),
    body: asString(json['body'] ?? json['message']),
    isRead: asBool(json['is_read'] ?? json['isRead'] ?? json['read']),
    createdAt: json['created_at'] ?? json['createdAt'],
    data: asModel(json['data'], NotificationData.fromJson),
    campaignAction: asModel(json['campaign_action'], CampaignBellAction.fromJson),
    campaignId: asString(json['campaign_id']),
    executionId: asString(json['execution_id']),
  );
  JsonMap toJson() => {
    'id': id,
    'item_id': itemId,
    'source': source,
    'title': title,
    'body': body,
    'is_read': isRead,
    'created_at': createdAt,
    'data': data?.toJson(),
    'campaign_action': campaignAction?.toJson(),
    'campaign_id': campaignId,
    'execution_id': executionId,
  };
  AppNotification copyWith({
    Object? id = contractUnchanged,
    Object? itemId = contractUnchanged,
    Object? source = contractUnchanged,
    Object? title = contractUnchanged,
    Object? body = contractUnchanged,
    Object? isRead = contractUnchanged,
    Object? createdAt = contractUnchanged,
    Object? data = contractUnchanged,
    Object? campaignAction = contractUnchanged,
    Object? campaignId = contractUnchanged,
    Object? executionId = contractUnchanged,
  }) => AppNotification(
    id: identical(id, contractUnchanged) ? this.id : id as int?,
    itemId: identical(itemId, contractUnchanged) ? this.itemId : itemId as String?,
    source: identical(source, contractUnchanged) ? this.source : source as String?,
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
    campaignAction: identical(campaignAction, contractUnchanged)
        ? this.campaignAction
        : campaignAction as CampaignBellAction?,
    campaignId: identical(campaignId, contractUnchanged)
        ? this.campaignId
        : campaignId as String?,
    executionId: identical(executionId, contractUnchanged)
        ? this.executionId
        : executionId as String?,
  );
  @override
  List<Object?> get props => [
    id, itemId, source, title, body, isRead, createdAt, data,
    campaignAction, campaignId, executionId,
  ];
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
  const MarkNotificationReadRequest({this.notificationId, this.itemId});
  /// Legacy pre-N6 shape -- kept for backward compatibility; unused by
  /// any current call site (the Bell now always has a composite [itemId]).
  final int? notificationId;
  /// N6 -- preferred: the exact composite id the unified list returned
  /// (`"ab:<int>"` / `"cc:<uuid>"`), sent verbatim, never reconstructed.
  final String? itemId;
  factory MarkNotificationReadRequest.fromJson(JsonMap json) =>
      MarkNotificationReadRequest(
        notificationId: asInt(
          json['notification_id'] ?? json['notificationId'],
        ),
        itemId: asString(json['item_id'] ?? json['itemId']),
      );
  /// `item_id` wins when present (N6 backend prefers it); `notification_id`
  /// is included only as the legacy fallback the backend still accepts.
  JsonMap toJson() => itemId != null
      ? {'item_id': itemId}
      : {'notification_id': notificationId};
  MarkNotificationReadRequest copyWith({
    Object? notificationId = contractUnchanged,
    Object? itemId = contractUnchanged,
  }) => MarkNotificationReadRequest(
    notificationId: identical(notificationId, contractUnchanged)
        ? this.notificationId
        : notificationId as int?,
    itemId: identical(itemId, contractUnchanged)
        ? this.itemId
        : itemId as String?,
  );
  @override
  List<Object?> get props => [notificationId, itemId];
}
