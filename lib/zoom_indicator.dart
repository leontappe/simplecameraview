import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'camera_bloc.dart';
import 'util.dart';

class ZoomIndicator extends StatelessWidget {
  const ZoomIndicator({super.key});

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
    return BlocBuilder<CameraBloc, CameraState>(
      builder: (context, state) {
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
                    '${state.minZoomLevel.toStringAsFixed(0)}x',
                    style: TextStyle(color: Colors.white54, fontSize: 10.0),
                  ),
                  Text(
                    '${state.currentZoomLevel.toStringAsFixed(0)}x',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${state.maxZoomLevel.toStringAsFixed(0)}x',
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
                        state.maxZoomLevel *
                        (state.currentZoomLevel - 1)),
                bottom: (constraints.maxHeight - stopperHeight) -
                    (constraints.maxHeight /
                        state.maxZoomLevel *
                        (state.currentZoomLevel - 1)) -
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
      },
    );
  }
}
