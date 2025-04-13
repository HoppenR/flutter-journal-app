import 'package:flutter/material.dart';

import '../utility.dart';
import 'configuration.dart';
import 'dashboard.dart';
import 'graphs.dart';

class ChartDashboardGrid extends StatelessWidget {
  const ChartDashboardGrid({super.key, required this.dashboard});
  static const double gridCellsX = 5.0;
  static const double gridCellsY = 8.0;

  final ChartDashboardData dashboard;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size gridBoxSize = Size(
          constraints.maxWidth / gridCellsX,
          constraints.maxHeight / gridCellsY,
        );
        return SizedBox.expand(
          child: Stack(
            children: dashboard.configurations.map(
              (GraphConfiguration conf) {
                return DraggableResizableGraph(
                  gridSize: gridBoxSize,
                  conf: conf,
                );
              },
            ).toList(growable: false),
          ),
        );
      },
    );
  }
}

class DraggableResizableGraph extends StatefulWidget {
  const DraggableResizableGraph({
    super.key,
    required this.gridSize,
    required this.conf,
  });

  final Size gridSize;
  final GraphConfiguration conf;

  @override
  State<DraggableResizableGraph> createState() =>
      _DraggableResizableGraphState();
}

class _DraggableResizableGraphState extends State<DraggableResizableGraph> {
  bool _isResizing = false;
  bool _resizeMode = false;
  bool _showPreview = false;

  Offset _dragOffset = Offset.zero;

  late Offset _containerPosition;
  late Offset _previewPosition;
  late Size _containerSize;
  late Size _previewSize;

  @override
  void initState() {
    _containerPosition = Offset(
      widget.conf.offset.dx * widget.gridSize.width,
      widget.conf.offset.dy * widget.gridSize.height,
    );
    _containerSize = Size(
      widget.conf.size.width * widget.gridSize.width,
      widget.conf.size.height * widget.gridSize.height,
    );

    _previewPosition = _containerPosition;
    _previewSize = _containerSize;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Size snappedPreviewSize = _snapToGridSize(_previewSize);
    final List<Color> colors = <Color>[
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.inversePrimary,
      Color.alphaBlend(
        Theme.of(context).colorScheme.primary.withAlpha(108),
        Theme.of(context).colorScheme.inversePrimary,
      ),
      Color.alphaBlend(
        Theme.of(context).colorScheme.primary.withAlpha(150),
        Theme.of(context).colorScheme.inversePrimary,
      ),
    ];
    return Stack(
      children: <Widget>[
        Positioned(
          left: _containerPosition.dx,
          top: _containerPosition.dy,
          child: LongPressDraggable<Offset>(
            data: _containerPosition,
            onDragStarted: () {
              _showPreview = true;
              _previewPosition = _containerPosition;
            },
            onDragUpdate: (DragUpdateDetails details) {
              // While dragging, update the preview position.
              final RenderBox? box = context.findRenderObject() as RenderBox?;
              final Offset localOffset =
                  box!.globalToLocal(details.globalPosition) - _dragOffset;
              setState(() {
                if (_containerSize.width + localOffset.dx <=
                        widget.gridSize.width * ChartDashboardGrid.gridCellsX &&
                    _containerSize.height + localOffset.dy <=
                        widget.gridSize.height *
                            ChartDashboardGrid.gridCellsY &&
                    localOffset.dx >= 0 &&
                    localOffset.dy >= 0) {
                  // TODO: smoother experience if this moves the axis that is
                  //       in bounds even if both aren't
                  _previewPosition = _snapToGridOffset(localOffset);
                }
              });
            },
            onDragEnd: (DraggableDetails details) {
              final RenderBox? box = context.findRenderObject() as RenderBox?;
              final Offset newPos = box!.globalToLocal(details.offset);
              // TODO: newPosGrid might collide, should check collisions
              final Offset newPosGrid = _snapToGridOffset(newPos);
              setState(() {
                if (_containerSize.width + newPosGrid.dx <=
                        widget.gridSize.width * ChartDashboardGrid.gridCellsX &&
                    _containerSize.height + newPosGrid.dy <=
                        widget.gridSize.height *
                            ChartDashboardGrid.gridCellsY &&
                    newPosGrid.dx >= 0 &&
                    newPosGrid.dy >= 0) {
                  _containerPosition = newPosGrid;
                  widget.conf.offset = Offset(
                    newPosGrid.dx / widget.gridSize.width,
                    newPosGrid.dy / widget.gridSize.height,
                  );
                  saveChartDashboardData(context);
                }
                _resizeMode = true;
                _showPreview = false;
              });
            },
            feedback: Container(
              height: _containerSize.height,
              width: _containerSize.width,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.reorder),
            ),
            childWhenDragging: Container(
              height: _containerSize.height,
              width: _containerSize.width,
              color: Theme.of(context).colorScheme.secondaryFixed,
            ),
            child: GestureDetector(
              onPanDown: (DragDownDetails details) {
                setState(() {
                  _dragOffset = details.localPosition;
                  if (_dragOffset.dy >= _containerSize.height - 20.0 &&
                      _dragOffset.dx >= _containerSize.width - 20.0) {
                    _isResizing = true;
                    _showPreview = true;
                    _previewSize = _containerSize;
                  }
                });
              },
              onPanCancel: () {
                setState(() {
                  _resizeMode = false;
                  _isResizing = false;
                  _showPreview = false;
                });
              },
              onPanUpdate: _resizeMode
                  ? (DragUpdateDetails details) {
                      setState(() {
                        if (_isResizing) {
                          _previewSize += details.delta;
                        }
                      });
                    }
                  : null,
              onPanEnd: (DragEndDetails details) {
                setState(() {
                  if (_isResizing) {
                    _containerSize = snappedPreviewSize;
                    //_resizeMode = false;
                    _isResizing = false;
                    _showPreview = false;
                    // TODO: previewSize might become negative, should check
                    //       whether in bounds and positive, and if is colliding
                    //       with other graphs
                    widget.conf.size = Size(
                      snappedPreviewSize.width / widget.gridSize.width,
                      snappedPreviewSize.height / widget.gridSize.height,
                    );
                    saveChartDashboardData(context);
                  }
                });
              },
              child: AbsorbPointer(
                child: Stack(
                  children: <Widget>[
                    Container(
                      height: _containerSize.height,
                      width: _containerSize.width,
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.surfaceContainerHigh,
                        border: _resizeMode
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 4.0,
                              )
                            : Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary,
                                width: 2.0,
                              ),
                      ),
                      child: buildGraph(context, widget.conf, colors),
                    ),
                    if (_resizeMode) _buildDragHandle(_containerSize),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_showPreview)
          Positioned(
            left: _previewPosition.dx,
            top: _previewPosition.dy,
            child: Container(
              width: snappedPreviewSize.width,
              height: snappedPreviewSize.height,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  width: 3,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDragHandle(Size size) {
    return Positioned(
      left: size.width - 15,
      top: size.height - 15,
      width: 30,
      height: 30,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Offset _snapToGridOffset(Offset offset) {
    final double snappedX =
        (offset.dx / widget.gridSize.width).round() * widget.gridSize.width;
    final double snappedY =
        (offset.dy / widget.gridSize.height).round() * widget.gridSize.height;
    return Offset(snappedX, snappedY);
  }

  Size _snapToGridSize(Size offset) {
    final double snappedX =
        (offset.width / widget.gridSize.width).round() * widget.gridSize.width;
    final double snappedY = (offset.height / widget.gridSize.height).round() *
        widget.gridSize.height;
    return Size(snappedX, snappedY);
  }

  Widget buildGraph(
    BuildContext context,
    GraphConfiguration conf,
    List<Color> colors,
  ) {
    final DateTime time = DateTime.now();
    switch (conf.type) {
      case GraphTypes.heatmap:
        switch (conf.timeSpan) {
          case GraphTimespans.month:
            return buildMonthHeatMap(context, conf, time, colors[0]);
          case GraphTimespans.year:
            return buildYearHeatMap(context, conf, time, colors);
        }
      case GraphTypes.weekdayBarChart:
        switch (conf.timeSpan) {
          case GraphTimespans.month:
            return buildMonthBarChart(context, conf, time, colors);
          case GraphTimespans.year:
            // TODO: Handle this case.
            throw UnimplementedError();
        }
      case GraphTypes.lineChart:
        switch (conf.timeSpan) {
          case GraphTimespans.month:
            return buildMonthLineChart(context, conf, time, colors);
          case GraphTimespans.year:
            // TODO: Handle this case.
            throw UnimplementedError();
        }
      case GraphTypes.radar:
        // TODO: can create new types: radarHabit and radarCategory?
        //       alternatively make it an option at tag creation
        switch (conf.timeSpan) {
          case GraphTimespans.month:
            return buildMonthHabitRadar(context, conf, time, colors);
          case GraphTimespans.year:
            return buildYearCategoryRadar(context, conf, time, colors);
        }
    }
  }
}
