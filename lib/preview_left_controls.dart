import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'camera_bloc.dart';
import 'camera_state.dart';

class PreviewLeftControls extends StatelessWidget {
  const PreviewLeftControls({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<CameraBloc>(context);

    return BlocBuilder<CameraBloc, CameraState>(
      builder: (context, state) {
        final items = <Widget>[
          IconButton(
            icon: _flashIconBuilder(state.flashMode),
            onLongPress: () {
              HapticFeedback.heavyImpact();
              bloc.updateCameraState(
                flashMode: FlashMode.auto,
              );
            },
            onPressed: () {
              HapticFeedback.heavyImpact();

              // Cycle through flash modes
              switch (state.flashMode) {
                case FlashMode.auto:
                  bloc.updateCameraState(flashMode: FlashMode.always);
                  break;
                case FlashMode.always:
                  bloc.updateCameraState(flashMode: FlashMode.torch);
                  break;
                case FlashMode.torch:
                  bloc.updateCameraState(flashMode: FlashMode.off);
                  break;
                case FlashMode.off:
                  bloc.updateCameraState(flashMode: FlashMode.auto);
                  break;
              }
            },
          ),
          IconButton(
            icon: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.center_focus_weak_outlined),
                Transform.translate(
                  offset: Offset(8, -8),
                  child: Transform.scale(
                    scale: 0.5,
                    child: state.lockFocus
                        ? Icon(Icons.lock,
                            color: Theme.of(context).colorScheme.primary)
                        : const SizedBox(),
                  ),
                ),
              ],
            ),
            onPressed: () {
              HapticFeedback.heavyImpact();

              bloc.updateCameraState(
                lockFocus: !state.lockFocus,
              );
            },
          ),
          Spacer(), // Notch spacer
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              HapticFeedback.heavyImpact();
              // TODO: Implement settings action
            },
          ),
        ];

        return Container(
          padding: const EdgeInsets.all(16.0),
          child: state.isPortrait
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: items.reversed.toList(),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: items,
                ),
        );
      },
    );
  }

  Widget _flashIconBuilder(FlashMode mode) {
    switch (mode) {
      case FlashMode.auto:
        return const Icon(Icons.flash_auto);
      case FlashMode.always:
        return const Icon(Icons.flash_on);
      case FlashMode.off:
        return const Icon(Icons.flash_off);
      case FlashMode.torch:
        return const Icon(Icons.flashlight_on);
    }
  }
}
