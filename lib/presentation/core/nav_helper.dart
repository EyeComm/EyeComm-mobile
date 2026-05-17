import 'package:flutter/material.dart';

/// Push a new page and await its result.
Future<void> push(BuildContext ctx, Widget page) =>
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => page));

/// Replace the current route with [page].
Future<void> pushReplacement(BuildContext ctx, Widget page) =>
    Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => page));
