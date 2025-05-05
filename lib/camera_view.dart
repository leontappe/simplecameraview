// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simplecameraview/widgets/settings_modal.dart';

import 'camera_bloc.dart';
import 'widgets/debug_info.dart';
import 'widgets/gesture_overlay.dart';
import 'widgets/preview_left_controls.dart';
import 'widgets/preview_window.dart';
import 'widgets/zoom_indicator.dart';

/// A widget showing a live camera preview.
class CameraView extends StatefulWidget {
  /// The controller for the camera that the preview is shown for.
  final CameraController controller;

  const CameraView(this.controller, {super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  late final CameraBloc _bloc;

  CameraController get _controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CameraBloc>.value(
      value: _bloc,
      child: BlocBuilder<CameraBloc, CameraState>(
        builder: _build,
      ),
    );
  }

  @override
  initState() {
    super.initState();

    _bloc = CameraBloc(
      cameraController: _controller,
      initialState: CameraState(),
    );
  }

  Widget _build(BuildContext context, CameraState state) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        ValueListenableBuilder<CameraValue>(
          valueListenable: _controller,
          builder: _controller.value.isInitialized
              ? (_, __, ___) => PreviewWindow(controller: _controller)
              : (_, __, ___) => const SizedBox(),
        ),
        if (state.uiState.showDebugInfo)
          Align(
            alignment: Alignment.center,
            child: DebugInfo(),
          ),
        if (state.uiState.showZoomIndicator)
          Align(
            alignment:
                state.isPortrait ? Alignment.bottomLeft : Alignment.topRight,
            child: ZoomIndicator(),
          ),
        GestureOverlay(),
        if (state.uiState.showControls)
          Align(
            alignment: state.isPortrait ? Alignment.topLeft : Alignment.topLeft,
            child: PreviewLeftControls(),
          ),
        if (state.uiState.showSettings) SettingsModal()
      ],
    );
  }
}
