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
      children: [
        if (_showDebugInfo)
          Align(
            alignment: Alignment.bottomLeft,
            child: _debugInfo(),
          ),
        ValueListenableBuilder<CameraValue>(
          valueListenable: widget.controller,
          builder: widget.controller.value.isInitialized
              ? _previewBuilder
              : (_, __, ___) => const SizedBox(),
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
    }
  }

  Widget _debugInfo() {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
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

  bool _isLandscape() {
    return <DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight
    ].contains(_getApplicableOrientation());
  }

  // return container that clips the camera preview to the screen size, discarding any pixels that are off-screen
  Widget _previewBuilder(
      BuildContext context, CameraValue value, Widget? child) {
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
      onDoubleTap: () {
        setState(() {
          _showDebugInfo = !_showDebugInfo;
        });
      },
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          clipBehavior: Clip.hardEdge,
          fit: BoxFit.cover,
          child: SizedBox(
            width: _isLandscape()
                ? widget.controller.value.previewSize!.width
                : widget.controller.value.previewSize!.height,
            height: _isLandscape()
                ? widget.controller.value.previewSize!.height
                : widget.controller.value.previewSize!.width,
            child: widget.controller.buildPreview(),
          ),
        ),
      ),
    );
  }
}
