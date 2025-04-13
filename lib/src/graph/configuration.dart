import 'dart:ui';

enum GraphTypes { heatmap, weekdayBarChart, lineChart, radar }

extension GraphType on GraphTypes {
  int get minimumItemAmt {
    switch (this) {
      case GraphTypes.heatmap:
      case GraphTypes.weekdayBarChart:
      case GraphTypes.lineChart:
        return 1;
      case GraphTypes.radar:
        return 3;
    }
  }

  int get maximumItemAmt {
    switch (this) {
      case GraphTypes.heatmap:
        return 1;
      case GraphTypes.weekdayBarChart:
      case GraphTypes.lineChart:
      case GraphTypes.radar:
        return 9;
    }
  }

  static GraphTypes fromJson(Map<String, dynamic> json) {
    if (json['type'] == 'heatmap') {
      return GraphTypes.heatmap;
    } else if (json['type'] == 'weekdayBarChart') {
      return GraphTypes.weekdayBarChart;
    } else if (json['type'] == 'lineChart') {
      return GraphTypes.lineChart;
    } else if (json['type'] == 'radar') {
      return GraphTypes.radar;
    } else {
      throw AssertionError('invalid type in json');
    }
  }

  String toJson() {
    return toString().split('.').last;
  }
}

enum GraphTimespans { month, year }

extension GraphTimespan on GraphTimespans {
  static GraphTimespans fromJson(Map<String, dynamic> json) {
    if (json['timeSpan'] == 'month') {
      return GraphTimespans.month;
    } else if (json['timeSpan'] == 'year') {
      return GraphTimespans.year;
    } else {
      throw AssertionError('invalid type in json');
    }
  }

  String toJson() {
    return toString().split('.').last;
  }
}

class GraphConfiguration {
  GraphConfiguration({
    required this.type,
    this.timeSpan = GraphTimespans.month,
    required this.ids,
    this.size = const Size(1.0, 1.0),
    required this.offset,
  });

  factory GraphConfiguration.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> size = json['size'];
    final Map<String, dynamic> offset = json['offset'];
    return GraphConfiguration(
      type: GraphType.fromJson(json),
      timeSpan: GraphTimespan.fromJson(json),
      ids: List<int>.from(json['ids']),
      size: Size(size['width']!, size['height']!),
      offset: Offset(offset['dx']!, offset['dy']!),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type.toJson(),
      'timeSpan': timeSpan.toJson(),
      'ids': ids,
      'size': <String, double>{'width': size.width, 'height': size.height},
      'offset': <String, double>{'dx': offset.dx, 'dy': offset.dy},
    };
  }

  final GraphTypes type;
  final GraphTimespans timeSpan;
  final List<int> ids;
  Size size;
  Offset offset;
}
