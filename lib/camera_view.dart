// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget showing a live camera preview.
class CameraView extends StatelessWidget {
  /// Creates a preview widget for the given camera controller.
  const CameraView(this.controller, {super.key});

  /// The controller for the camera that the preview is shown for.
  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CameraValue>(
      valueListenable: controller,
      builder: controller.value.isInitialized
          ? _previewBuilder
          : (_, __, ___) => const SizedBox(),
    );
  }

  // return container that clips the camera preview to the screen size, discarding any pixels that are off-screen
  Widget _previewBuilder(
      BuildContext context, CameraValue value, Widget? child) {
    return OverflowBox(
      alignment: Alignment.center,
      child: FittedBox(
        clipBehavior: Clip.hardEdge,
        fit: BoxFit.cover,
        child: SizedBox(
          width: _isLandscape()
              ? controller.value.previewSize!.width
              : controller.value.previewSize!.height,
          height: _isLandscape()
              ? controller.value.previewSize!.height
              : controller.value.previewSize!.width,
          child: controller.buildPreview(),
        ),
      ),
    );
  }

  bool _isLandscape() {
    return <DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight
    ].contains(_getApplicableOrientation());
  }

  DeviceOrientation _getApplicableOrientation() {
    return controller.value.isRecordingVideo
        ? controller.value.recordingOrientation!
        : (controller.value.previewPauseOrientation ??
            controller.value.lockedCaptureOrientation ??
            controller.value.deviceOrientation);
  }
}
