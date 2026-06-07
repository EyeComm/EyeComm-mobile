import 'package:flutter/material.dart';

Future<void> push(BuildContext ctx, Widget page) =>
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => page));

Future<void> pushReplacement(BuildContext ctx, Widget page) =>
    Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => page));
