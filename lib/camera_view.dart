// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CameraState {
  bool isPortrait;

  double currentZoomLevel;
  double minZoomLevel;
  double maxZoomLevel;

  double currentExposureOffset;
  double minExposureOffset;
  double maxExposureOffset;
  double exposureOffsetStep;
  bool lockExposure;
  Offset? exposurePoint;

  FlashMode flashMode;

  bool lockFocus;
  Offset? focusPoint;

  int fps;
  ResolutionPreset resolutionPreset;
  int? videoBitrate;

  CameraState({
    this.isPortrait = false,
    this.currentZoomLevel = 1.0,
    this.minZoomLevel = 1.0,
    this.maxZoomLevel = 1.0,
    this.currentExposureOffset = 0.0,
    this.minExposureOffset = -1.0,
    this.maxExposureOffset = 1.0,
    this.exposureOffsetStep = 0.1,
    this.lockExposure = false,
    this.flashMode = FlashMode.off,
    this.lockFocus = false,
    this.fps = 60,
    this.resolutionPreset = ResolutionPreset.max,
    this.videoBitrate,
  })  : assert(currentZoomLevel >= minZoomLevel &&
            currentZoomLevel <= maxZoomLevel),
        assert(currentExposureOffset >= minExposureOffset &&
            currentExposureOffset <= maxExposureOffset),
        assert(exposureOffsetStep > 0.0),
        assert(fps > 0);
}

/// A widget showing a live camera preview.
class CameraView extends StatefulWidget {
  /// The controller for the camera that the preview is shown for.
  final CameraController controller;

  /// Creates a preview widget for the given camera controller.
  const CameraView(this.controller, {super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class SettingsTile extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsTile({
    super.key,
    required this.title,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      color: Colors.blueGrey.shade800,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 4.0,
            left: 8.0,
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            top: 26.0,
            left: 8.0,
            right: 8.0,
            bottom: 8.0,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: children),
          )
        ],
      ),
    );
  }
}

class SettingsTitle extends StatelessWidget {
  final String title;

  const SettingsTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.grey,
        fontSize: 12.0,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _CameraViewState extends State<CameraView> {
  final CameraState _state = CameraState();

  CameraController? _editedController;

  bool _showDebugInfo = false;

  bool _showControls = false;
  bool _showSettings = false;
  bool _showZoomIndicator = false;
  bool _zooming = false;
  bool _hideRightControls = false;
  late final List<Offset> _areaOffsets;

  CameraController get _controller => _editedController ?? widget.controller;

  Container get _halfLine => Container(
        height: 2.0,
        width: 16.0,
        color: Colors.white38,
      );

  Container get _line => Container(
        height: 2.0,
        width: 32.0,
        color: Colors.white38,
      );

  Container get _quarterLine => Container(
        height: 2.0,
        width: 8.0,
        color: Colors.white38,
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        ValueListenableBuilder<CameraValue>(
          valueListenable: widget.controller,
          builder: widget.controller.value.isInitialized
              ? (_, __, ___) => _previewWindowBuilder()
              : (_, __, ___) => const SizedBox(),
        ),
        if (_showDebugInfo)
          Align(
            alignment: Alignment.center,
            child: _debugInfoBuilder(),
          ),
        if (_showZoomIndicator)
          Align(
            alignment:
                _state.isPortrait ? Alignment.bottomLeft : Alignment.topRight,
            child: _zoomIndicatorBuilder(),
          ),
        _gestureDetectorBuilder(),
        if (_showControls)
          Align(
            alignment:
                _state.isPortrait ? Alignment.topLeft : Alignment.topLeft,
            child: _controlsLeftBuilder(),
          ),
        if (_showControls)
          Align(
            alignment:
                _state.isPortrait ? Alignment.bottomLeft : Alignment.topRight,
            child: _controlsRightBuilder(),
          ),
        if (_showSettings)
          Align(
            alignment: Alignment.center,
            child: _settingsBuilder(),
          )
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.removeListener(_controllerStateListener);
  }

  @override
  initState() {
    super.initState();

    // wait until controller is ready to get zoom levels
    widget.controller.addListener(_controllerStateListener);

    // offsets of a 3x3 grid
    // offsets should point in the center of each grid cell
    // the value of a point can co from (0,0) to (1,1)
    // (0,0) is the bottom left corner of the preview
    _areaOffsets = List.generate(
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
  }

  void _controllerStateListener() {
    if (widget.controller.value.isInitialized) {
      _getZoomLevels();
      _getExposureOffsets();
      _getOrientation();
    }
  }

  Widget _controlsBuilder({List<Widget> children = const []}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: _state.isPortrait
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: children.reversed.toList(),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: children,
            ),
    );
  }

  Widget _controlsLeftBuilder() {
    return _controlsBuilder(
      children: [
        IconButton(
          icon: _flashIconBuilder(_state.flashMode),
          onLongPress: () {
            HapticFeedback.heavyImpact();
            setState(() {
              _state.flashMode = FlashMode.off;
            });
            widget.controller.setFlashMode(_state.flashMode);
          },
          onPressed: () {
            HapticFeedback.heavyImpact();

            // Cycle through flash modes
            setState(() {
              switch (_state.flashMode) {
                case FlashMode.auto:
                  _state.flashMode = FlashMode.always;
                  break;
                case FlashMode.always:
                  _state.flashMode = FlashMode.torch;
                  break;
                case FlashMode.torch:
                  _state.flashMode = FlashMode.off;
                  break;
                case FlashMode.off:
                  _state.flashMode = FlashMode.auto;
                  break;
              }
            });

            widget.controller.setFlashMode(_state.flashMode);
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
                  child: _state.lockFocus
                      ? Icon(Icons.lock, color: Theme.of(context).colorScheme.primary)
                      : const SizedBox(),
                ),
              ),
            ],
          ),
          onPressed: () {
            HapticFeedback.heavyImpact();
            setState(() {
              _state.lockFocus = !_state.lockFocus;
            });
            widget.controller.setFocusMode(
              _state.lockFocus ? FocusMode.locked : FocusMode.auto,
            );
          },
        ),
        Spacer(), // Notch spacer
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () {
            HapticFeedback.heavyImpact();
            setState(() {
              _showSettings = !_showSettings;
            });
          },
        ),
      ],
    );
  }

  /// Right side controls
  ///
  /// This is where more nitty gritty controls like exposure, framerate, white balance, etc. live
  Widget _controlsRightBuilder() {
    if (_hideRightControls) {
      return const SizedBox();
    }

    return _controlsBuilder(
      children: [],
    );
  }

  Widget _debugInfoBuilder() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Zoom: ${_state.currentZoomLevel}'),
          Text('Min zoom: ${_state.minZoomLevel}'),
          Text('Max zoom: ${_state.maxZoomLevel}'),
          Text('Exposure offset: ${_state.currentExposureOffset}'),
          Text('Min exposure offset: ${_state.minExposureOffset}'),
          Text('Max exposure offset: ${_state.maxExposureOffset}'),
          Text('Exposure offset step: ${_state.exposureOffsetStep}'),
          Text('Lock Exposure: ${_state.lockExposure}'),
          Text('Exposure Point: ${_state.exposurePoint}'),
          Text('Flash Mode: ${_flashModeToString(_state.flashMode)}'),
          Text('Focus Mode: ${_state.lockFocus ? "Locked" : "Auto"}'),
          Text('Focus Point: ${_state.focusPoint}'),
          Text('Orientation: ${_getApplicableOrientation()}'),
          Text('Preview size: ${widget.controller.value.previewSize}'),
        ],
      ),
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

  Widget _gestureDetectorBuilder() {
    return GestureDetector(
      onVerticalDragStart: (details) {
        HapticFeedback.lightImpact();
        setState(() {
          _showZoomIndicator = true;
          _zooming = true;
          _hideRightControls = true;
        });
      },
      onVerticalDragEnd: (details) {
        HapticFeedback.lightImpact();

        setState(() {
          _zooming = false;
        });

        Future.delayed(const Duration(milliseconds: 1000), () {
          setState(() {
            if (!_zooming) {
              _showZoomIndicator = false;
              _hideRightControls = false;
            }
          });
        });
      },
      onVerticalDragUpdate: (details) {
        final delta = details.delta.dy / 60;
        final newZoomLevel = (_state.currentZoomLevel + delta).clamp(
          _state.minZoomLevel,
          _state.maxZoomLevel,
        );
        widget.controller.setZoomLevel(newZoomLevel);
        setState(() {
          _state.currentZoomLevel = newZoomLevel;
        });
      },
      onDoubleTap: () {
        HapticFeedback.heavyImpact();
        setState(() {
          _showDebugInfo = !_showDebugInfo;
        });
      },
      onTap: () {
        HapticFeedback.heavyImpact();
        setState(() {
          _showControls = !_showControls;
        });
      },
    );
  }

  DeviceOrientation _getApplicableOrientation() {
    return widget.controller.value.isRecordingVideo
        ? widget.controller.value.recordingOrientation!
        : (widget.controller.value.lockedCaptureOrientation ??
            widget.controller.value.deviceOrientation);
  }

  void _getExposureOffsets() {
    widget.controller.getMinExposureOffset().then((value) {
      _state.minExposureOffset = value;
    });
    widget.controller.getMaxExposureOffset().then((value) {
      _state.maxExposureOffset = value;
    });
  }

  void _getOrientation() {
    setState(() {
      _state.isPortrait = _isPortrait();
    });
  }

  void _getZoomLevels() {
    widget.controller.getMinZoomLevel().then((value) {
      _state.minZoomLevel = value;
    });
    widget.controller.getMaxZoomLevel().then((value) {
      // zooms levels get ridiculously high on some devices
      // so we need to clamp them to a reasonable value
      _state.maxZoomLevel = value.clamp(1, 10);
    });
  }

  bool _isPortrait() {
    return <DeviceOrientation>[
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp
    ].contains(_getApplicableOrientation());
  }

  Widget _previewBuilder() {
    // Get the native preview size from the controller.
    final previewSize = _controller.value.previewSize;
    if (previewSize == null) {
      return const SizedBox();
    }

    return OverflowBox(
      alignment: Alignment.center,
      child: FittedBox(
        clipBehavior: Clip.hardEdge,
        fit: BoxFit.cover,
        child: SizedBox(
          width: _isPortrait() ? previewSize.height : previewSize.width,
          height: _isPortrait() ? previewSize.width : previewSize.height,
          child: widget.controller.buildPreview(),
        ),
      ),
    );
  }

  // return container that clips the camera preview to the screen size, discarding any pixels that are off-screen
  Widget _previewWindowBuilder(
      {double landscapeAspectRatio = 16 / 9,
      double portraitAspectRatio = 9 / 16}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the maximum width and height from the parent.
        final double maxWidth = constraints.maxWidth;
        final double maxHeight = constraints.maxHeight;
        // Choose the ratio based on device orientation.
        final double aspectRatio =
            _isPortrait() ? portraitAspectRatio : landscapeAspectRatio;

        // Determine the ideal width and height keeping our desired aspect ratio.
        double previewWidth;
        double previewHeight;
        if (maxWidth / maxHeight < aspectRatio) {
          // the available width is the limiting factor
          previewWidth = maxWidth;
          previewHeight = previewWidth / aspectRatio;
        } else {
          // the available height is the limiting factor
          previewHeight = maxHeight;
          previewWidth = previewHeight * aspectRatio;
        }

        return Center(
          child: SizedBox(
            width: previewWidth,
            height: previewHeight,
            child: _previewBuilder(),
          ),
        );
      },
    );
  }

  Widget _settingsBuilder() {
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
            padding: const EdgeInsets.only(top: 42.0, left: 48.0, right: 32.0),
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 4.0,
              mainAxisSpacing: 4.0,
              childAspectRatio: _state.isPortrait ? 9 / 6 : 16 / 9,
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
                        child: _previewWindowBuilder(),
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
                      'Offset: ${_state.currentExposureOffset.toStringAsFixed(1)}',
                    ),
                    GestureDetector(
                      onDoubleTap: () {
                        HapticFeedback.heavyImpact();
                        setState(() {
                          _state.currentExposureOffset = 0.0;
                        });
                        widget.controller.setExposureOffset(0.0);
                      },
                      child: Slider(
                        padding: const EdgeInsets.only(
                          top: 4.0,
                          left: 8.0,
                          right: 8.0,
                          bottom: 8.0,
                        ),
                        value: _state.currentExposureOffset,
                        min: _state.minExposureOffset,
                        max: _state.maxExposureOffset,
                        divisions: ((_state.maxExposureOffset -
                                    _state.minExposureOffset) /
                                _state.exposureOffsetStep)
                            .round(),
                        onChangeEnd: (value) {
                          HapticFeedback.heavyImpact();
                          setState(() {
                            _state.currentExposureOffset = value;
                          });
                          widget.controller.setExposureOffset(value);
                        },
                        onChanged: (value) {
                          setState(() {
                            _state.currentExposureOffset = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SettingsTile(
                  title: 'Stream Info',
                  children: [
                    SettingsTitle(
                      'FPS: ${_controller.mediaSettings.fps}',
                    ),
                    if (_controller.value.previewSize != null)
                      SettingsTitle(
                        'Resolution: ${_controller.value.previewSize!.width.round()} x ${_controller.value.previewSize!.height.round()}',
                      ),
                    SettingsTitle(
                      'Aspect Ratio: ${_controller.value.aspectRatio.toStringAsFixed(2)}',
                    ),
                    if (_controller.mediaSettings.videoBitrate != null)
                      SettingsTitle(
                        'Bitrate: ${(_controller.mediaSettings.videoBitrate ?? 0 / 1000).round()} kbps',
                      ),
                    SettingsTitle(
                      'Orientation: ${_controller.value.deviceOrientation.name}',
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
                              value: _state.lockExposure,
                              onChanged: (value) {
                                HapticFeedback.heavyImpact();
                                setState(() {
                                  _state.lockExposure = value;
                                });
                                widget.controller.setExposureMode(
                                  value
                                      ? ExposureMode.locked
                                      : ExposureMode.auto,
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
                              value: _state.lockFocus,
                              onChanged: (value) {
                                HapticFeedback.heavyImpact();
                                setState(() {
                                  _state.lockFocus = value;
                                });
                                widget.controller.setFocusMode(
                                  value ? FocusMode.locked : FocusMode.auto,
                                );

                                if (!value) {
                                  setState(() {
                                    _state.focusPoint = null;
                                  });
                                  widget.controller.setFocusPoint(null);
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

                                      if (_state.focusPoint ==
                                          _areaOffsets[index]) {
                                        // If the focus point is already set to this area, reset it to null
                                        setState(() {
                                          _state.focusPoint = null;
                                        });
                                        widget.controller.setFocusPoint(null);
                                        return;
                                      }

                                      setState(() {
                                        _state.lockFocus = true;
                                        _state.focusPoint = _areaOffsets[index];
                                      });
                                      widget.controller.setFocusMode(
                                        FocusMode.locked,
                                      );
                                      widget.controller
                                          .setFocusPoint(_state.focusPoint);
                                    },
                                    child: Container(
                                      color: _state.focusPoint ==
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
                                  setState(() {
                                    _state.focusPoint = null;
                                    _state.lockFocus = false;
                                  });
                                  widget.controller.setFocusPoint(null);
                                  widget.controller.setFocusMode(
                                    FocusMode.auto,
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

                                      setState(() {
                                        _state.exposurePoint =
                                            _areaOffsets[index];
                                      });
                                      widget.controller.setExposurePoint(
                                          _state.exposurePoint);
                                    },
                                    child: Container(
                                      color: _state.exposurePoint ==
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
                                  setState(() {
                                    _state.exposurePoint = null;
                                    _state.lockExposure = false;
                                  });
                                  widget.controller.setExposurePoint(null);
                                  widget.controller.setExposureMode(
                                    ExposureMode.auto,
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
                setState(() {
                  _showSettings = false;
                });
              },
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoomIndicatorBuilder() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const stopperHeight = 16.0;
        const indicatorWidth = 32.0;
        const totalWidth = 56.0;

        final text = Container(
          width: totalWidth,
          height: constraints.maxHeight,
          padding: const EdgeInsets.only(top: 10.0, bottom: 14.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_state.minZoomLevel.toStringAsFixed(0)}x',
                style: TextStyle(color: Colors.white54, fontSize: 10.0),
              ),
              Text(
                '${_state.currentZoomLevel.toStringAsFixed(0)}x',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_state.maxZoomLevel.toStringAsFixed(0)}x',
                style: TextStyle(color: Colors.white54, fontSize: 10.0),
              ),
            ],
          ),
        );

        final markings = Container(
          padding: EdgeInsets.only(
            top: stopperHeight,
            bottom: stopperHeight + 2.0,
          ),
          height: constraints.maxHeight,
          width: indicatorWidth,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _line,
              _quarterLine,
              _quarterLine,
              _halfLine,
              _quarterLine,
              _quarterLine,
              _line,
            ],
          ),
        );

        final indicator = Container(
          height: constraints.maxHeight,
          padding: EdgeInsets.only(
            top: stopperHeight +
                (constraints.maxHeight /
                    _state.maxZoomLevel *
                    (_state.currentZoomLevel - 1)),
            bottom: (constraints.maxHeight - stopperHeight) -
                (constraints.maxHeight /
                    _state.maxZoomLevel *
                    (_state.currentZoomLevel - 1)) -
                4.0,
          ),
          width: indicatorWidth,
          child: _halfLine.copyWith(
              color: Colors.blueAccent, height: 2.0, width: 8.0),
        );

        return Stack(
          alignment: Alignment.centerRight,
          children: [
            text,
            markings,
            indicator,
          ],
        );
      },
    );
  }
}

extension CopyableContainer on Container {
  /// Creates a copy of this container with the given properties.
  Container copyWith({
    double? height,
    double? width,
    Color? color,
    Padding? padding,
    Widget? child,
  }) {
    return Container(
      height: height ?? constraints?.maxHeight,
      width: width ?? constraints?.maxWidth,
      color: color ?? this.color,
      padding: padding?.padding ?? this.padding,
      child: child ?? this.child,
    );
  }
}
