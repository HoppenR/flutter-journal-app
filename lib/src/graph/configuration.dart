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

enum GraphTimespans { week, month, year }

extension GraphTimespan on GraphTimespans {
  static GraphTimespans fromJson(Map<String, dynamic> json) {
    if (json['timeSpan'] == 'week') {
      return GraphTimespans.week;
    } else if (json['timeSpan'] == 'month') {
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
    required this.ids,
    this.timeSpan = GraphTimespans.month,
  });

  factory GraphConfiguration.fromJson(Map<String, dynamic> json) {
    return GraphConfiguration(
      type: GraphType.fromJson(json),
      timeSpan: GraphTimespan.fromJson(json),
      ids: List<int>.from(json['tagIds'] ?? <int>[]),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type.toJson(),
      'timeSpan': timeSpan.toJson(),
      'tagIds': ids,
    };
  }

  final GraphTypes type;
  final GraphTimespans timeSpan;

  // NOTE: should not exceed size 4 atm, since we are indexing into 4 primary
  //       colors
  // NOTE: this is tag IDs for most `GraphType`s
  // NOTE: this is graph IDs for radar chart
  //       which needs at least 3 graph IDs to render, if it ever drops below
  //       then the config should be deleted
  final List<int> ids;
}
