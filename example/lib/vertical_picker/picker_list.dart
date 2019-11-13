import 'package:flutter/material.dart';
import 'package:hsluvsample/util/constants.dart';
import 'package:hsluvsample/vertical_picker/picker_item.dart';
import 'package:infinite_listview/infinite_listview.dart';

import '../color_with_inter.dart';

class ExpandableColorBar extends StatelessWidget {
  const ExpandableColorBar({
    this.pageKey,
    this.title,
    this.expanded,
    this.sectionIndex,
    this.listSize,
    this.colorsList,
    this.onTitlePressed,
    this.onColorPressed,
    this.isInfinite = false,
  });

  final Function onTitlePressed;
  final Function(Color) onColorPressed;
  final List<ColorWithInter> colorsList;
  final String title;
  final String pageKey;
  final int expanded;
  final int sectionIndex;
  final int listSize;
  final bool isInfinite;

  Widget colorCompare(int index) {
    return ColorCompareWidgetDetails(
      kind: pageKey,
      color: colorsList[index],
      compactText: expanded == sectionIndex,
      category: title,
      onPressed: () => onColorPressed(colorsList[index].color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      _ExpandableTitle(
        title: title,
        index: sectionIndex,
        expanded: expanded,
        onTitlePressed: onTitlePressed,
      ),
      Expanded(
        child: Card(
          child: isInfinite
              ? InfiniteListView.builder(
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
                    physics: const BouncingScrollPhysics(),
                    itemCount: listSize,
                    key: PageStorageKey<String>("$pageKey $sectionIndex"),
                    itemBuilder: (BuildContext context, int index) {
                      return colorCompare(index);
                    },
                  ),
                ),
        ),
      ),
    ]);
  }
}

class _ExpandableTitle extends StatelessWidget {
  const _ExpandableTitle({
    this.title,
    this.expanded,
    this.index,
    this.onTitlePressed,
  });

  final Function onTitlePressed;
  final String title;
  final int expanded;
  final int index;

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      onPressed: onTitlePressed,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(defaultRadius)),
      child: Text(
        expanded == index ? title : title[0],
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
