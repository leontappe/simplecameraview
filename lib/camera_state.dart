import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';

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

  CameraUIState uiState;

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
    this.exposurePoint,
    this.focusPoint,
    this.uiState = const CameraUIState(),
  })  : assert(currentZoomLevel >= minZoomLevel &&
            currentZoomLevel <= maxZoomLevel),
        assert(currentExposureOffset >= minExposureOffset &&
            currentExposureOffset <= maxExposureOffset),
        assert(exposureOffsetStep > 0.0);

  CameraState copyWith({
    bool? isPortrait,
    double? currentZoomLevel,
    double? minZoomLevel,
    double? maxZoomLevel,
    double? currentExposureOffset,
    double? minExposureOffset,
    double? maxExposureOffset,
    double? exposureOffsetStep,
    bool? lockExposure,
    FlashMode? flashMode,
    bool? lockFocus,
    Offset? exposurePoint,
    Offset? focusPoint,
    CameraUIState? uiState,
  }) {
    return CameraState(
      isPortrait: isPortrait ?? this.isPortrait,
      currentZoomLevel: currentZoomLevel ?? this.currentZoomLevel,
      minZoomLevel: minZoomLevel ?? this.minZoomLevel,
      maxZoomLevel: maxZoomLevel ?? this.maxZoomLevel,
      currentExposureOffset:
          currentExposureOffset ?? this.currentExposureOffset,
      minExposureOffset: minExposureOffset ?? this.minExposureOffset,
      maxExposureOffset: maxExposureOffset ?? this.maxExposureOffset,
      exposureOffsetStep: exposureOffsetStep ?? this.exposureOffsetStep,
      lockExposure: lockExposure ?? this.lockExposure,
      flashMode: flashMode ?? this.flashMode,
      lockFocus: lockFocus ?? this.lockFocus,
      exposurePoint: exposurePoint ?? this.exposurePoint,
      focusPoint: focusPoint ?? this.focusPoint,
      uiState: uiState ?? this.uiState,
    );
  }
}

class CameraUIState {
  final bool showControls;
  final bool showZoomIndicator;
  final bool isZooming;
  final bool showDebugInfo;
  final bool showSettings;

  const CameraUIState({
    this.showControls = false,
    this.showZoomIndicator = false,
    this.isZooming = false,
    this.showDebugInfo = false,
    this.showSettings = false,
  });

  @override
  int get hashCode {
    return showControls.hashCode ^
        showZoomIndicator.hashCode ^
        isZooming.hashCode ^
        showDebugInfo.hashCode ^
        showSettings.hashCode;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CameraUIState &&
        other.showControls == showControls &&
        other.showZoomIndicator == showZoomIndicator &&
        other.isZooming == isZooming &&
        other.showDebugInfo == showDebugInfo &&
        other.showSettings == showSettings;
  }

  CameraUIState copyWith({
    bool? showControls,
    bool? showZoomIndicator,
    bool? isZooming,
    bool? showDebugInfo,
    bool? showSettings,
  }) {
    return CameraUIState(
      showControls: showControls ?? this.showControls,
      showZoomIndicator: showZoomIndicator ?? this.showZoomIndicator,
      isZooming: isZooming ?? this.isZooming,
      showDebugInfo: showDebugInfo ?? this.showDebugInfo,
      showSettings: showSettings ?? this.showSettings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'showControls': showControls,
      'showZoomIndicator': showZoomIndicator,
      'isZooming': isZooming,
      'showDebugInfo': showDebugInfo,
      'showSettings': showSettings,
    };
  }

  @override
  String toString() {
    return 'CameraUIState(${toJson()})';
  }
}
