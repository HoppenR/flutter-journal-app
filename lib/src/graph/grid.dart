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
                  dashboard: dashboard,
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
    required this.dashboard,
    required this.gridSize,
    required this.conf,
  });

  final ChartDashboardData dashboard;
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
        _buildGraphContainer(context, colors),
        if (_showPreview) _buildDragPreview(context),
      ],
    );
  }

  Widget _buildGraphContainer(
    BuildContext context,
    List<Color> colors,
  ) {
    return Positioned(
      left: _containerPosition.dx,
      top: _containerPosition.dy,
      child: LongPressDraggable<Offset>(
        onDragStarted: () {
          _showPreview = true;
          _previewPosition = _containerPosition;
        },
        onDragUpdate: (DragUpdateDetails details) {
          // While dragging, update the preview position.
          final RenderBox? box = context.findRenderObject() as RenderBox?;
          final Offset newPreviewOffset =
              box!.globalToLocal(details.globalPosition) - _dragOffset;
          final bool inBoundsX = _containerSize.width + newPreviewOffset.dx <=
                  widget.gridSize.width * ChartDashboardGrid.gridCellsX &&
              newPreviewOffset.dx >= 0;
          final bool inBoundsY = _containerSize.height + newPreviewOffset.dy <=
                  widget.gridSize.height * ChartDashboardGrid.gridCellsY &&
              newPreviewOffset.dy >= 0;
          final Offset snappedPreviewOffset =
              _snapToGridOffset(newPreviewOffset);
          setState(() {
            if (inBoundsX && inBoundsY) {
              _previewPosition = snappedPreviewOffset;
            } else if (inBoundsX) {
              _previewPosition = Offset(
                snappedPreviewOffset.dx,
                _previewPosition.dy,
              );
            } else if (inBoundsY) {
              _previewPosition = Offset(
                _previewPosition.dx,
                snappedPreviewOffset.dy,
              );
            }
          });
        },
        onDragEnd: (DraggableDetails _) {
          final Offset newPosGridNormalized = Offset(
            _previewPosition.dx / widget.gridSize.width,
            _previewPosition.dy / widget.gridSize.height,
          );
          final Size newSizeGridNormalized = Size(
            _previewSize.width / widget.gridSize.width,
            _previewSize.height / widget.gridSize.height,
          );
          final bool collided = _checkCollisions(
            newPosGridNormalized & newSizeGridNormalized,
          );
          setState(() {
            if (!collided) {
              _containerPosition = _previewPosition;
              widget.conf.offset = newPosGridNormalized;
              saveChartDashboardData(context);
            } else {
              _previewPosition = _containerPosition;
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
        child: _buildResizableGraph(colors),
      ),
    );
  }

  Widget _buildDragPreview(BuildContext context) {
    return Positioned(
      left: _previewPosition.dx,
      top: _previewPosition.dy,
      child: Container(
        width: _previewSize.width,
        height: _previewSize.height,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.inversePrimary,
            width: 3,
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Positioned(
      right: -15,
      bottom: -15,
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

  Widget _buildResizableGraph(List<Color> colors) {
    return GestureDetector(
      onPanDown: (DragDownDetails details) {
        setState(() {
          _dragOffset = details.localPosition;
          if (_dragOffset.dy >= _containerSize.height - 20.0 &&
              _dragOffset.dx >= _containerSize.width - 20.0) {
            if (_resizeMode) {
              _isResizing = true;
              _showPreview = true;
              _previewSize = _containerSize;
            }
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
              if (!_isResizing) {
                return;
              }

              final Size newPreviewSize =
                  _containerSize + details.localPosition + (-_dragOffset);
              final bool inBoundsX = newPreviewSize.width +
                          _containerPosition.dx <=
                      widget.gridSize.width * ChartDashboardGrid.gridCellsX &&
                  newPreviewSize.width >= widget.gridSize.width;
              final bool inBoundsY = newPreviewSize.height +
                          _containerPosition.dy <=
                      widget.gridSize.height * ChartDashboardGrid.gridCellsY &&
                  newPreviewSize.height >= widget.gridSize.height;
              final Size snappedPreviewSize = _snapToGridSize(newPreviewSize);
              setState(() {
                if (inBoundsX && inBoundsY) {
                  _previewSize = snappedPreviewSize;
                } else if (inBoundsX) {
                  _previewSize = Size(
                    snappedPreviewSize.width,
                    _previewSize.height,
                  );
                } else if (inBoundsY) {
                  _previewSize = Size(
                    _previewSize.width,
                    snappedPreviewSize.height,
                  );
                }
              });
            }
          : null,
      onPanEnd: (DragEndDetails _) {
        setState(() {
          if (!_isResizing) {
            return;
          }

          final Offset newPosGridNormalized = Offset(
            _previewPosition.dx / widget.gridSize.width,
            _previewPosition.dy / widget.gridSize.height,
          );
          final Size newSizeGridNormalized = Size(
            _previewSize.width / widget.gridSize.width,
            _previewSize.height / widget.gridSize.height,
          );
          final bool collided = _checkCollisions(
            newPosGridNormalized & newSizeGridNormalized,
          );
          if (!collided) {
            _containerSize = _previewSize;
            _resizeMode = false;
            widget.conf.size = newSizeGridNormalized;
            saveChartDashboardData(context);
          } else {
            _previewSize = _containerSize;
          }
          _isResizing = false;
          _showPreview = false;
        });
      },
      child: AbsorbPointer(
        child: Stack(
          children: <Widget>[
            Container(
              height: _containerSize.height,
              width: _containerSize.width,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                border: _resizeMode
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 4.0,
                      )
                    : Border.all(
                        color: Theme.of(context).colorScheme.inversePrimary,
                        width: 2.0,
                      ),
              ),
              child: _buildGraph(context, colors),
            ),
            if (_resizeMode) _buildDragHandle(context),
          ],
        ),
      ),
    );
  }

  Widget _buildGraph(
    BuildContext context,
    List<Color> colors,
  ) {
    // TODO: User should be able to customize time.
    //       perhaps by sliding the graph to the sides, it might inc/dec by month/year
    //       depending on the GraphTimespan?
    final Size graphSize = Size(
      widget.conf.size.width * widget.gridSize.width,
      widget.conf.size.height * widget.gridSize.height,
    );
    final DateTime time = DateTime.now();
    switch (widget.conf.type) {
      case GraphTypes.heatmap:
        switch (widget.conf.timeSpan) {
          case GraphTimespans.month:
            return buildMonthHeatMap(
              context,
              widget.conf,
              graphSize,
              time,
              colors[0],
            );
          case GraphTimespans.year:
            return buildYearHeatMap(
              context,
              widget.conf,
              graphSize,
              time,
              colors,
            );
        }
      case GraphTypes.weekdayBarChart:
        switch (widget.conf.timeSpan) {
          case GraphTimespans.month:
            return buildMonthBarChart(
              context,
              widget.conf,
              graphSize,
              time,
              colors,
            );
          case GraphTimespans.year:
            // TODO: Handle this case.
            throw UnimplementedError();
        }
      case GraphTypes.lineChart:
        switch (widget.conf.timeSpan) {
          case GraphTimespans.month:
            return buildMonthLineChart(context, widget.conf, time, colors);
          case GraphTimespans.year:
            // TODO: Handle this case.
            throw UnimplementedError();
        }
      case GraphTypes.radar:
        // TODO: can create new types: radarHabit and radarCategory?
        //       alternatively make it an option at tag creation
        switch (widget.conf.timeSpan) {
          case GraphTimespans.month:
            return buildMonthHabitRadar(
              context,
              widget.conf,
              time,
              colors[0],
            );
          case GraphTimespans.year:
            return buildYearCategoryRadar(
              context,
              widget.conf,
              time,
              colors,
            );
        }
    }
  }

  bool _checkCollisions(Rect newRect) {
    for (final GraphConfiguration conf in widget.dashboard.configurations) {
      if (conf == widget.conf) {
        continue;
      }
      final Rect oRect = conf.offset & conf.size;
      if (newRect.overlaps(oRect)) {
        return true;
      }
    }
    return false;
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
}
