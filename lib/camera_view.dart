// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CameraState {
  double currentZoomLevel;
  double minZoomLevel;
  double maxZoomLevel;

  CameraState({
    this.currentZoomLevel = 1.0,
    this.minZoomLevel = 1.0,
    this.maxZoomLevel = 1.0,
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
        _gestureDetectorBuilder()
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
    }
  }

  Widget _debugInfoBuilder() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.2,
      width: MediaQuery.of(context).size.width * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Zoom: ${_state.currentZoomLevel}'),
          Text('Min Zoom: ${_state.minZoomLevel}'),
          Text('Max Zoom: ${_state.maxZoomLevel}'),
        ],
      ),
    );
  }

  Widget _gestureDetectorBuilder() {
    return GestureDetector(
      onScaleUpdate: (details) {
        final delta = details.scale - 8.0;
        final newZoomLevel = _state.currentZoomLevel + delta;
        if (newZoomLevel >= _state.minZoomLevel &&
            newZoomLevel <= _state.maxZoomLevel) {
          widget.controller.setZoomLevel(newZoomLevel);
          setState(() {
            _state.currentZoomLevel = newZoomLevel;
          });
        }
      },
      onTap: () {
        HapticFeedback.heavyImpact();
        setState(() {
          _showDebugInfo = !_showDebugInfo;
        });
      },
    );
  }

  DeviceOrientation _getApplicableOrientation() {
    return widget.controller.value.isRecordingVideo
        ? widget.controller.value.recordingOrientation!
        : (widget.controller.value.previewPauseOrientation ??
            widget.controller.value.lockedCaptureOrientation ??
            widget.controller.value.deviceOrientation);
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
}
