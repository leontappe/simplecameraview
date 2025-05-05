import 'package:camera/camera.dart' show CameraController;
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:flutter/widgets.dart' show Container, Padding, Widget, Color;

DeviceOrientation getApplicableOrientation(CameraController controller) {
  return controller.value.isRecordingVideo
      ? controller.value.recordingOrientation!
      : (controller.value.lockedCaptureOrientation ??
          controller.value.deviceOrientation);
}

bool isPortrait(CameraController controller) {
  return <DeviceOrientation>[
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp
  ].contains(getApplicableOrientation(controller));
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
