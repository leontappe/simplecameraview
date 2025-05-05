import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'camera_bloc.dart';

class DebugInfo extends StatelessWidget {
  const DebugInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CameraBloc, CameraState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Zoom: ${state.currentZoomLevel}'),
              Text('Min zoom: ${state.minZoomLevel}'),
              Text('Max zoom: ${state.maxZoomLevel}'),
              Text('Exposure offset: ${state.currentExposureOffset}'),
              Text('Min exposure offset: ${state.minExposureOffset}'),
              Text('Max exposure offset: ${state.maxExposureOffset}'),
              Text('Exposure offset step: ${state.exposureOffsetStep}'),
              Text('Lock Exposure: ${state.lockExposure}'),
              Text('Exposure Point: ${state.exposurePoint}'),
              Text('Flash Mode: ${_flashModeToString(state.flashMode)}'),
              Text('Focus Mode: ${state.lockFocus ? "Locked" : "Auto"}'),
              Text('Focus Point: ${state.focusPoint}'),
              Text(
                  'Orientation: ${state.isPortrait ? "Portrait" : "Landscape"}'),
              Text(
                  'Preview size: ${BlocProvider.of<CameraBloc>(context).cameraController.value.previewSize}'),
              Text(
                  'Sensor Orientation: ${BlocProvider.of<CameraBloc>(context).cameraController.value.aspectRatio}'),
            ],
          ),
        );
      },
    );
  }

  String _flashModeToString(FlashMode mode) {
    switch (mode) {
      case FlashMode.auto:
        return 'Auto';
      case FlashMode.always:
        return 'Always';
      case FlashMode.off:
        return 'Off';
      case FlashMode.torch:
        return 'Torch';
    }
  }
}
