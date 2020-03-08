import 'package:flutter/material.dart';

class ContainerWithNumber extends StatelessWidget {
  const ContainerWithNumber(this.index, this.backgroundColor, this.indexColor);

  final int index;
  final Color backgroundColor;
  final Color indexColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      margin: const EdgeInsets.only(right: 16),
      child: Center(
        child: Text(
          index.toString(),
          style: Theme.of(context).textTheme.headline5.copyWith(
              fontWeight: FontWeight.w500,
              color: backgroundColor,
              fontSize: (index < 100) ? 24 : 20
            // auto-scale if index has 3 digits.
          ),
        ),
      ),
      decoration: BoxDecoration(
        color: indexColor,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
    );
  }
}
