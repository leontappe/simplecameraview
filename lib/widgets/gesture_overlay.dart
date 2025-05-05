import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../camera_bloc.dart';

class GestureOverlay extends StatelessWidget {
  const GestureOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<CameraBloc>(context);

    return BlocBuilder<CameraBloc, CameraState>(
      builder: (context, state) {
        return GestureDetector(
          onVerticalDragStart: (details) {
            HapticFeedback.lightImpact();
            bloc.updateUIState(showZoomIndicator: true, isZooming: true);
          },
          onVerticalDragEnd: (details) {
            HapticFeedback.lightImpact();

            bloc.updateUIState(isZooming: false);

            Future.delayed(const Duration(milliseconds: 1000), () {
              bloc.updateUIState(showZoomIndicator: false);
            });
          },
          onVerticalDragUpdate: (details) {
            final delta = details.delta.dy / 60;
            final newZoomLevel = (state.currentZoomLevel + delta).clamp(
              state.minZoomLevel,
              state.maxZoomLevel,
            );
            bloc.updateCameraState(currentZoomLevel: newZoomLevel);
          },
          onDoubleTap: () {
            HapticFeedback.heavyImpact();
            bloc.updateUIState(showControls: !state.uiState.showControls);
          },
          onTap: () {
            HapticFeedback.heavyImpact();
            bloc.updateUIState(showControls: !state.uiState.showControls);
          },
        );
      },
    );
  }
}
