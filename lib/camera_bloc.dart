import 'dart:ui' show Offset;

import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';

import 'camera_state.dart';
import 'util.dart';

export 'package:camera/camera.dart' show FlashMode, ExposureMode, FocusMode;

export 'camera_state.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  final CameraController cameraController;

  CameraBloc({
    required this.cameraController,
    required CameraState initialState,
  }) : super(initialState) {
    if (cameraController.value.isInitialized) {
      cameraController.addListener(_cameraControllerStateListener);
    }

    on<CameraEvent>((event, emit) async {
      if (event is UpdateCameraState) {
        final newState = state.copyWith(
          isPortrait: event.isPortrait,
          currentZoomLevel: event.currentZoomLevel,
          minZoomLevel: event.minZoomLevel,
          maxZoomLevel: event.maxZoomLevel,
          currentExposureOffset: event.currentExposureOffset,
          minExposureOffset: event.minExposureOffset,
          maxExposureOffset: event.maxExposureOffset,
          exposureOffsetStep: event.exposureOffsetStep,
          lockExposure: event.lockExposure,
          flashMode: event.flashMode,
          lockFocus: event.lockFocus,
        );
        _setControllerAttributes(state, newState);
        emit(newState);
      } else if (event is UpdateCameraUIEvent) {
        emit(state.copyWith(
          uiState: state.uiState.copyWith(
            showControls: event.showControls,
            showZoomIndicator: event.showZoomIndicator,
            showDebugInfo: event.showDebugInfo,
          ),
        ));
      }
    });
  }

  @override
  Future<void> close() async {
    super.close();
    cameraController.removeListener(_cameraControllerStateListener);
  }

  void updateCameraState({
    bool? isPortrait,
    double? currentZoomLevel,
    double? minZoomLevel,
    double? maxZoomLevel,
    double? currentExposureOffset,
    double? minExposureOffset,
    double? maxExposureOffset,
    double? exposureOffsetStep,
    bool? lockExposure,
    Offset? exposurePoint,
    bool? lockFocus,
    Offset? focusPoint,
    FlashMode? flashMode,
  }) {
    add(UpdateCameraState(
      isPortrait: isPortrait,
      currentZoomLevel: currentZoomLevel,
      minZoomLevel: minZoomLevel,
      maxZoomLevel: maxZoomLevel,
      currentExposureOffset: currentExposureOffset,
      minExposureOffset: minExposureOffset,
      maxExposureOffset: maxExposureOffset,
      exposureOffsetStep: exposureOffsetStep,
      lockExposure: lockExposure,
      exposurePoint: exposurePoint,
      lockFocus: lockFocus,
      focusPoint: focusPoint,
      flashMode: flashMode,
    ));
  }

  void updateUIState({
    bool? showControls,
    bool? showZoomIndicator,
    bool? isZooming,
    bool? showDebugInfo,
  }) {
    add(UpdateCameraUIEvent(
      showControls: showControls,
      showZoomIndicator: showZoomIndicator,
      isZooming: isZooming,
      showDebugInfo: showDebugInfo,
    ));
  }

  Future<void> _cameraControllerStateListener() async {
    if (cameraController.value.isInitialized) {
      // zooms levels get ridiculously high on some devices
      // so we need to clamp them to a reasonable value
      state.minZoomLevel = await cameraController.getMinZoomLevel();
      state.maxZoomLevel =
          (await cameraController.getMaxZoomLevel()).clamp(1, 10);

      state.minExposureOffset = await cameraController.getMinExposureOffset();
      state.maxExposureOffset = await cameraController.getMaxExposureOffset();

      state.isPortrait = isPortrait(cameraController);
    }
  }

  void _setControllerAttributes(CameraState old, CameraState newState) {
    if (old.currentZoomLevel != newState.currentZoomLevel) {
      cameraController.setZoomLevel(newState.currentZoomLevel);
    }
    if (old.flashMode != newState.flashMode) {
      cameraController.setFlashMode(newState.flashMode);
    }
    if (old.lockFocus != newState.lockFocus) {
      cameraController.setFocusMode(
        newState.lockFocus ? FocusMode.locked : FocusMode.auto,
      );
    }
    if (old.lockExposure != newState.lockExposure) {
      cameraController.setExposureMode(
        newState.lockExposure ? ExposureMode.locked : ExposureMode.auto,
      );
    }
    if (old.currentExposureOffset != newState.currentExposureOffset) {
      cameraController.setExposureOffset(newState.currentExposureOffset);
    }
    if (old.currentZoomLevel != newState.currentZoomLevel) {
      cameraController.setZoomLevel(newState.currentZoomLevel);
    }
    if (old.exposurePoint != newState.exposurePoint) {
      cameraController.setExposurePoint(newState.exposurePoint);
    }
    if (old.focusPoint != newState.focusPoint) {
      cameraController.setFocusPoint(newState.focusPoint);
    }
  }
}

class CameraEvent {}

class UpdateCameraState extends CameraEvent {
  final bool? isPortrait;
  final double? currentZoomLevel;
  final double? minZoomLevel;
  final double? maxZoomLevel;
  final double? currentExposureOffset;
  final double? minExposureOffset;
  final double? maxExposureOffset;
  final double? exposureOffsetStep;
  final bool? lockExposure;
  final Offset? exposurePoint;
  final bool? lockFocus;
  Offset? focusPoint;
  final FlashMode? flashMode;

  UpdateCameraState({
    this.isPortrait,
    this.currentZoomLevel,
    this.minZoomLevel,
    this.maxZoomLevel,
    this.currentExposureOffset,
    this.minExposureOffset,
    this.maxExposureOffset,
    this.exposureOffsetStep,
    this.lockExposure,
    this.exposurePoint,
    this.lockFocus,
    this.focusPoint,
    this.flashMode,
  });

  Map<String, dynamic> toJson() {
    return {
      'isPortrait': isPortrait,
      'currentZoomLevel': currentZoomLevel,
      'minZoomLevel': minZoomLevel,
      'maxZoomLevel': maxZoomLevel,
      'currentExposureOffset': currentExposureOffset,
      'minExposureOffset': minExposureOffset,
      'maxExposureOffset': maxExposureOffset,
      'exposureOffsetStep': exposureOffsetStep,
      'lockExposure': lockExposure,
      'exposurePoint': exposurePoint,
      'lockFocus': lockFocus,
      'focusPoint': focusPoint,
      'flashMode': flashMode?.index,
    };
  }

  @override
  String toString() {
    return 'UpdateCameraState(${toJson()})';
  }
}

class UpdateCameraUIEvent extends CameraEvent {
  final bool? showControls;
  final bool? showZoomIndicator;
  final bool? isZooming;
  final bool? showDebugInfo;

  UpdateCameraUIEvent({
    this.showControls,
    this.showZoomIndicator,
    this.isZooming,
    this.showDebugInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'showControls': showControls,
      'showZoomIndicator': showZoomIndicator,
      'isZooming': isZooming,
      'showDebugInfo': showDebugInfo,
    };
  }

  @override
  String toString() {
    return 'UpdateCameraUIEvent(${toJson()})';
  }
}
