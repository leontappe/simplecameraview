import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simplecameraview/camera_bloc.dart';

import 'preview_window.dart';
import 'settings_tile.dart';

class SettingsModal extends StatelessWidget {
  static final List<Offset> _areaOffsets = List.generate(
    9,
    (index) {
      final x = index % 3;
      final y = index ~/ 3;
      return Offset(
        (x + 1) / 4,
        (y + 1) / 4,
      );
    },
  );

  const SettingsModal({super.key});

  @override
  Widget build(BuildContext context) {
    final CameraBloc bloc = BlocProvider.of<CameraBloc>(context);

    return BlocBuilder<CameraBloc, CameraState>(
      builder: (context, state) {
        return Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: Colors.blueGrey.shade900,
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              // Grid overlay
              Padding(
                padding:
                    const EdgeInsets.only(top: 42.0, left: 48.0, right: 32.0),
                child: GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4.0,
                  mainAxisSpacing: 4.0,
                  childAspectRatio: state.isPortrait ? 9 / 6 : 16 / 9,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(0.0),
                        color: Colors.blueGrey.shade800,
                      ),
                      margin: const EdgeInsets.all(4.0),
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        alignment: Alignment.center,
                        children: [
                          Transform.scale(
                            scale: 1.05,
                            child: PreviewWindow(
                                controller: bloc.cameraController),
                          ),
                          Positioned(
                            top: 4.0,
                            left: 8.0,
                            child: Text(
                              'Preview',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SettingsTile(
                      title: 'Exposure',
                      children: [
                        SettingsTitle(
                          'Offset: ${state.currentExposureOffset.toStringAsFixed(1)}',
                        ),
                        GestureDetector(
                          onDoubleTap: () {
                            HapticFeedback.heavyImpact();
                            bloc.updateCameraState(currentExposureOffset: 0.0);
                          },
                          child: Slider(
                            padding: const EdgeInsets.only(
                              top: 4.0,
                              left: 8.0,
                              right: 8.0,
                              bottom: 8.0,
                            ),
                            value: state.currentExposureOffset,
                            min: state.minExposureOffset,
                            max: state.maxExposureOffset,
                            divisions: ((state.maxExposureOffset -
                                        state.minExposureOffset) /
                                    state.exposureOffsetStep)
                                .round(),
                            onChangeEnd: (value) {
                              HapticFeedback.heavyImpact();
                              bloc.updateCameraState(
                                currentExposureOffset: value,
                              );
                            },
                            onChanged: (value) {
                              bloc.updateCameraState(
                                currentExposureOffset: value,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    SettingsTile(
                      title: 'Stream Info',
                      children: [
                        SettingsTitle(
                          'FPS: ${bloc.cameraController.mediaSettings.fps}',
                        ),
                        if (bloc.cameraController.value.previewSize != null)
                          SettingsTitle(
                            'Resolution: ${bloc.cameraController.value.previewSize!.width.round()} x ${bloc.cameraController.value.previewSize!.height.round()}',
                          ),
                        SettingsTitle(
                          'Aspect Ratio: ${bloc.cameraController.value.aspectRatio.toStringAsFixed(2)}',
                        ),
                        if (bloc.cameraController.mediaSettings.videoBitrate !=
                            null)
                          SettingsTitle(
                            'Bitrate: ${(bloc.cameraController.mediaSettings.videoBitrate ?? 0 / 1000).round()} kbps',
                          ),
                        SettingsTitle(
                          'Orientation: ${bloc.cameraController.value.deviceOrientation.name}',
                        ),
                      ],
                    ),
                    SettingsTile(
                      title: 'Locks',
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SettingsTitle('Lock Exposure'),
                                Switch(
                                  value: state.lockExposure,
                                  onChanged: (value) {
                                    HapticFeedback.heavyImpact();
                                    bloc.updateCameraState(
                                      lockExposure: value,
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(width: 8.0),
                            const VerticalDivider(),
                            const SizedBox(width: 8.0),
                            Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SettingsTitle('Lock Focus'),
                                Switch(
                                  value: state.lockFocus,
                                  onChanged: (value) {
                                    HapticFeedback.heavyImpact();
                                    bloc.updateCameraState(
                                      lockFocus: value,
                                    );

                                    if (!value) {
                                      bloc.updateCameraState(
                                        focusPoint: null,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    SettingsTile(
                      title: 'Focus Point',
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) => SizedBox(
                            width: constraints.maxWidth,
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                SizedBox(
                                  height: 96.0,
                                  width: 128.0,
                                  child: GridView.builder(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 2.0,
                                      mainAxisSpacing: 2.0,
                                      childAspectRatio: 1.6,
                                    ),
                                    itemCount: 9,
                                    itemBuilder: (context, index) {
                                      return InkWell(
                                        onTap: () {
                                          HapticFeedback.heavyImpact();

                                          if (state.focusPoint ==
                                              _areaOffsets[index]) {
                                            // If the focus point is already set to this area, reset it to null
                                            return bloc.updateCameraState(
                                              lockFocus: false,
                                              focusPoint: null,
                                            );
                                          }

                                          bloc.updateCameraState(
                                            lockFocus: true,
                                            focusPoint: _areaOffsets[index],
                                          );
                                        },
                                        child: Container(
                                          color: state.focusPoint ==
                                                  _areaOffsets[index]
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .secondary
                                                  .withAlpha(192)
                                              : Colors.white10,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  bottom: 8.0,
                                  right: 8.0,
                                  child: TextButton(
                                    onPressed: () {
                                      HapticFeedback.heavyImpact();
                                      bloc.updateCameraState(
                                        lockFocus: false,
                                        focusPoint: null,
                                      );
                                    },
                                    child: Text('Clear'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SettingsTile(
                      title: 'Exposure Point',
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) => SizedBox(
                            width: constraints.maxWidth,
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                SizedBox(
                                  height: 96.0,
                                  width: 128.0,
                                  child: GridView.builder(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 2.0,
                                      mainAxisSpacing: 2.0,
                                      childAspectRatio: 1.6,
                                    ),
                                    itemCount: 9,
                                    itemBuilder: (context, index) {
                                      return InkWell(
                                        onTap: () {
                                          HapticFeedback.heavyImpact();
                                          bloc.updateCameraState(
                                            exposurePoint: _areaOffsets[index],
                                          );
                                        },
                                        child: Container(
                                          color: state.exposurePoint ==
                                                  _areaOffsets[index]
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .secondary
                                                  .withAlpha(192)
                                              : Colors.white10,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  bottom: 8.0,
                                  right: 8.0,
                                  child: TextButton(
                                    onPressed: () {
                                      HapticFeedback.heavyImpact();
                                      bloc.updateCameraState(
                                        lockExposure: false,
                                        exposurePoint: null,
                                      );
                                    },
                                    child: Text('Clear'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Settings text
              Align(
                alignment: Alignment.topLeft,
                child: Transform.translate(
                  offset: Offset(42.0, 0),
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white54,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
