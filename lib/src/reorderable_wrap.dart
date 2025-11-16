import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'tag/manager.dart';
import 'tag/tag.dart';

class ReorderableWrap extends StatefulWidget {
  const ReorderableWrap({super.key, required this.tag});

  final TagWithList tag;

  @override
  State<ReorderableWrap> createState() => _ReorderableWrapState();
}

class _ReorderableWrapState extends State<ReorderableWrap> {
  @override
  Widget build(BuildContext context) {
    return Wrap(children: _buildReorderableTagOptions(context));
  }

  List<Widget> _buildReorderableTagOptions(BuildContext context) {
    final TagManager tagManager = context.read<TagManager>();

    final List<Icon> targets = List<Icon>.generate(widget.tag.list.length + 1, (
      _,
    ) {
      return Icon(
        Icons.arrow_drop_down,
        color: Theme.of(context).colorScheme.onInverseSurface,
        size: 40.0,
      );
    });

    return List<Widget>.generate(widget.tag.list.length * 2 + 1, (int index) {
      if (index.isEven) {
        return DragTarget<int>(
          onWillAcceptWithDetails: (DragTargetDetails<int> details) {
            final int dropIndex = index ~/ 2;
            targets[dropIndex] = Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).colorScheme.primary,
              size: 40.0,
            );
            return true;
          },
          onLeave: (_) {
            final int dropIndex = index ~/ 2;
            targets[dropIndex] = Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).colorScheme.onInverseSurface,
              size: 40.0,
            );
          },
          onAcceptWithDetails: (DragTargetDetails<int> details) {
            int dropIndex = index ~/ 2;
            if (details.data < dropIndex) {
              dropIndex--;
            }
            tagManager.swapListOptions(widget.tag, details.data, dropIndex);
          },
          builder:
              (
                BuildContext context,
                List<int?> accepted,
                List<dynamic> rejected,
              ) {
                return targets[index ~/ 2];
              },
        );
      } else {
        return Draggable<int>(
          childWhenDragging: ChoiceChip(
            label: Text(widget.tag.list[index ~/ 2]),
            selected: false,
          ),
          data: index ~/ 2,
          feedback: Material(
            child: ChoiceChip(
              label: Text(widget.tag.list[index ~/ 2]),
              selected: false,
              onSelected: (_) {},
            ),
          ),
          child: ChoiceChip(
            label: Text(widget.tag.list[index ~/ 2]),
            selected: false,
            onSelected: (_) {},
          ),
        );
      }
    });
  }
}
