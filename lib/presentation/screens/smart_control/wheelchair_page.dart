// ════════════════════════════════════════════════════════════════════════════
// wheelchair_page.dart  (REFACTORED + FIXED)
//
// ✅ Dumb view — listens to WheelchairCubit.
// ✅ FIXED: import path corrected (cubit is in the same folder).
// ✅ No emojis in text.
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/eye_utils.dart';
import '../../core/language_service.dart';
import '../../shared/base_grid_page.dart';
import 'wheelchair_cubit.dart'; // same folder — FIXED path

class WheelchairPage extends StatelessWidget {
  const WheelchairPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';

    return BlocProvider(
      create: (_) => WheelchairCubit(),
      child: BlocConsumer<WheelchairCubit, EyeTrackingState>(
        listenWhen: (prev, curr) =>
            curr.confirmedGesture != null &&
            curr.confirmedGesture != prev.confirmedGesture,
        listener: (context, state) {
          if (state.confirmedGesture == 'closed') {
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          return BaseGridPage(
            title: ar ? 'الكرسي المتحرك' : 'Wheelchair',
            color: const Color(0xFF2E7D32),
            items: [
              {
                'eye': 'left',
                'text': ar ? 'يسار' : 'Left',
                'iconAsset': 'assets/icons/left_arrow.png',
                'color': const Color(0xFF1976D2),
                'is_nav': false,
                'eye_name': eyeName('left'),
              },
              {
                'eye': 'up',
                'text': ar ? 'للأمام' : 'Forward',
                'iconAsset': 'assets/icons/forward.png',
                'color': const Color(0xFF388E3C),
                'is_nav': false,
                'eye_name': eyeName('up'),
              },
              {
                'eye': 'right',
                'text': ar ? 'يمين' : 'Right',
                'iconAsset': 'assets/icons/right_arrow.png',
                'color': const Color(0xFF7B1FA2),
                'is_nav': false,
                'eye_name': eyeName('right'),
              },
              {
                'eye': 'closed',
                'text': ar ? 'رجوع' : 'Back',
                'iconAsset': 'assets/icons/back.png',
                'color': const Color(0xFF455A64),
                'is_nav': false,
                'eye_name': eyeName('closed'),
              },
            ],
            onAction: (eye, ctx) async {
              if (eye == 'closed') {
                Navigator.pop(ctx);
                return;
              }
              if (!ctx.mounted) return;
              // Trigger the cubit manually when a card is tapped.
              ctx.read<WheelchairCubit>().triggerManual(eye);
            },
          );
        },
      ),
    );
  }
}
