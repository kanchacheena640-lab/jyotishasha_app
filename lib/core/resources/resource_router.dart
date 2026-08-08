import 'package:flutter/material.dart';

import 'package:jyotishasha_app/core/models/events/event_resource_contracts.dart';
import 'package:jyotishasha_app/features/events/authority_resource_screen.dart';

/// Handles navigating to the screen for one [ResourceDto.type].
typedef ResourceHandler = void Function(
  BuildContext context,
  ResourceDto resource,
);

/// Centralized decision point for "where should this resource open" — the
/// single place every "Know More" tap (and any future resource entry point)
/// routes through, so no feature has to branch on `resource.type` itself.
///
/// Adding support for a new resource type means registering one new entry
/// in [_handlers] — it does not require modifying [open] or any existing
/// handler.
final class ResourceRouter {
  const ResourceRouter._();

  static final Map<String, ResourceHandler> _handlers = {
    'authority': _openAuthority,
  };

  /// Routes [resource] to its screen. Unrecognized/unimplemented types
  /// (`video`, `pdf`, `tool`, `community`, `calculator`, `ai_insight`, or
  /// anything else) never crash — they safely surface "Not implemented"
  /// instead of navigating.
  static void open(BuildContext context, ResourceDto resource) {
    final handler = _handlers[resource.type];
    if (handler == null) {
      _notImplemented(context);
      return;
    }
    handler(context, resource);
  }

  static void _openAuthority(BuildContext context, ResourceDto resource) {
    // TEMP LOG (BUG-011B)
    debugPrint('[BUG-011B][ResourceRouter] URL passed to AuthorityResourceScreen: ${resource.url}');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthorityResourceScreen(resource: resource),
      ),
    );
  }

  static void _notImplemented(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Not implemented')));
  }
}
