import 'package:flutter/material.dart';
import 'package:infinite_listview/infinite_listview.dart';

import 'color_with_contrast.dart';
import 'contrast_item.dart';

class ContrastList extends StatelessWidget {
  const ContrastList({
    this.pageKey,
    this.title,
    this.sectionIndex,
    this.listSize,
    this.colorsList,
    this.onColorPressed,
    this.buildWidget,
    this.isInfinite = false,
  });

  final Function(Color) onColorPressed;
  final Function(int) buildWidget;

  final List<ColorWithContrast> colorsList;
  final String title;
  final String pageKey;
  final int sectionIndex;
  final int listSize;
  final bool isInfinite;

  Widget colorCompare(int index) {
    return ContrastItem(
      kind: pageKey,
      color: colorsList[index],
      contrast: colorsList[index].contrast,
      compactText: true,
      category: title,
      onPressed: () => onColorPressed(colorsList[index].color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: isInfinite
          ? InfiniteListView.builder(
              scrollDirection: Axis.horizontal,
              key: PageStorageKey<String>("$pageKey $sectionIndex"),
              itemBuilder: (BuildContext context, int absoluteIndex) {
                final int index = absoluteIndex.abs() % listSize;
                return colorCompare(index);
              },
            )
          : MediaQuery.removePadding(
              // this is necessary on iOS, else there will be a bottom padding.
              removeBottom: true,
              context: context,
              child: ListView.builder(
                itemCount: listSize,
                scrollDirection: Axis.horizontal,
                key: PageStorageKey<String>("$pageKey $sectionIndex"),
                itemBuilder: (BuildContext context, int index) {
                  return colorCompare(index);
                },
              ),
            ),
    );
  }
}