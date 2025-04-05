enum GraphType { heatmap, weekdayBarChart, lineChart, radar }

enum GraphTimespan { week, month, year }

class GraphConfiguration {
  GraphConfiguration({
    required this.graphType,
    required this.ids,
    this.timeSpanPreset = GraphTimespan.month,
  });

  factory GraphConfiguration.fromJson(Map<String, dynamic> json) {
    return GraphConfiguration(
      graphType: GraphType.values.firstWhere(
        (GraphType e) => e.toString() == json['graphType'],
      ),
      timeSpanPreset: GraphTimespan.values.firstWhere(
        (GraphTimespan e) => e.toString() == json['timeSpanPreset'],
      ),
      ids: List<int>.from(json['tagIds'] ?? <int>[]),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'graphType': graphType.toString(),
      'timeSpanPreset': timeSpanPreset.toString(),
      'tagIds': ids,
    };
  }

  int get minimumItemAmt {
    switch (graphType) {
      case GraphType.heatmap:
      case GraphType.weekdayBarChart:
      case GraphType.lineChart:
        return 1;
      case GraphType.radar:
        return 3;
    }
  }

  final GraphType graphType;
  final GraphTimespan timeSpanPreset;

  // NOTE: should not exceed size 4 atm, since we are indexing into 4 primary
  //       colors
  // NOTE: this is tag IDs for most `GraphType`s
  // NOTE: this is graph IDs for radar chart
  //       which needs at least 3 graph IDs to render, if it ever drops below
  //       then the config should be deleted
  final List<int> ids;
}
