import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../util.dart';

/// Container that clips the camera preview to the screen size, discarding any pixels that are off-screen
class PreviewWindow extends StatelessWidget {
  final CameraController controller;

  final double landscapeAspectRatio;
  final double portraitAspectRatio;

  const PreviewWindow({
    super.key,
    required this.controller,
    this.landscapeAspectRatio = 16 / 9,
    this.portraitAspectRatio = 9 / 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the maximum width and height from the parent.
        final double maxWidth = constraints.maxWidth;
        final double maxHeight = constraints.maxHeight;
        // Choose the ratio based on device orientation.
        final double aspectRatio =
            isPortrait(controller) ? portraitAspectRatio : landscapeAspectRatio;

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

  Widget _previewBuilder() {
    // Get the native preview size from the controller.
    final previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return const SizedBox();
    }

    return OverflowBox(
      alignment: Alignment.center,
      child: FittedBox(
        clipBehavior: Clip.hardEdge,
        fit: BoxFit.cover,
        child: SizedBox(
          width:
              isPortrait(controller) ? previewSize.height : previewSize.width,
          height:
              isPortrait(controller) ? previewSize.width : previewSize.height,
          child: controller.buildPreview(),
        ),
      ),
    );
  }
}
