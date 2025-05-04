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

  FlashMode flashMode;

  bool lockFocus;

  CameraState({
    this.isPortrait = false,
    this.currentZoomLevel = 1.0,
    this.minZoomLevel = 1.0,
    this.maxZoomLevel = 1.0,
    this.currentExposureOffset = 0.0,
    this.minExposureOffset = -1.0,
    this.maxExposureOffset = 1.0,
    this.exposureOffsetStep = 0.1,
    this.flashMode = FlashMode.off,
    this.lockFocus = false,
  });
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

class _CameraViewState extends State<CameraView> {
  final CameraState _state = CameraState();

  bool _showDebugInfo = false;
  bool _showControls = false;
  bool _showSettings = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        ValueListenableBuilder<CameraValue>(
          valueListenable: widget.controller,
          builder: widget.controller.value.isInitialized
              ? _previewWindowBuilder
              : (_, __, ___) => const SizedBox(),
        ),
        if (_showDebugInfo)
          Align(
            alignment: Alignment.center,
            child: _debugInfoBuilder(),
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
    return _controlsBuilder(
      children: [
        IconButton(
          icon: const Icon(Icons.center_focus_weak),
          onPressed: () {
            HapticFeedback.heavyImpact();

            widget.controller.setFocusPoint(null);
          },
        ),
        IconButton(
          icon: _state.lockFocus
              ? const Icon(Icons.lock)
              : const Icon(Icons.lock_open),
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
        IconButton(
          icon: const Icon(Icons.exposure),
          onPressed: () {
            HapticFeedback.heavyImpact();
            setState(() {
              _state.currentExposureOffset =
                  (_state.currentExposureOffset + _state.exposureOffsetStep)
                      .clamp(
                _state.minExposureOffset,
                _state.maxExposureOffset,
              );
            });
            widget.controller.setExposureOffset(_state.currentExposureOffset);
          },
          onLongPress: () {
            HapticFeedback.heavyImpact();
            setState(() {
              _state.currentExposureOffset = 0;
            });
            widget.controller.setExposureOffset(_state.currentExposureOffset);
          },
        ),
      ],
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
          Text('Exposure: ${_state.currentExposureOffset}'),
          Text('Min exposure offset: ${_state.minExposureOffset}'),
          Text('Max exposure offset: ${_state.maxExposureOffset}'),
          Text('Exposure offset step: ${_state.exposureOffsetStep}'),
          Text('Flash Mode: ${_flashModeToString(_state.flashMode)}'),
          Text('Focus Mode: ${_state.lockFocus ? "Locked" : "Auto"}'),
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
      onVerticalDragUpdate: (details) {
        final delta = details.delta.dy / 100;
        final newZoomLevel = _state.currentZoomLevel + delta;
        if (newZoomLevel >= _state.minZoomLevel &&
            newZoomLevel <= _state.maxZoomLevel) {
          widget.controller.setZoomLevel(newZoomLevel);
          setState(() {
            _state.currentZoomLevel = newZoomLevel;
          });
        }
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
      _state.maxZoomLevel = value;
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
    final previewSize = widget.controller.value.previewSize!;

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
      BuildContext context, CameraValue value, Widget? child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the maximum width and height from the parent.
        final double maxWidth = constraints.maxWidth;
        final double maxHeight = constraints.maxHeight;
        // Choose the ratio based on device orientation.
        final double aspectRatio = _isPortrait() ? 9 / 16 : 16 / 9;

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
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4.0,
                mainAxisExtent: MediaQuery.of(context).size.height * 0.4,
              ),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  color: Colors.blueGrey.shade800,
                );
              },
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
}
