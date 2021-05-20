import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'card_item.dart';

typedef PageChangedCallback = void Function(double page);
typedef PageSelectedCallback = void Function(int index);

class HorizontalCardPager extends StatefulWidget {
  final List<CardItem>? items;
  final PageChangedCallback? onPageChanged;
  final PageSelectedCallback? onSelectedItem;
  // Set initial index
  final int initialPage;
  final double? viewWidth;
  final double? viewHeight;
  final double? cardMaxWidth;
  final double? cardMaxHeight;
  final double horizontalSpacing;
  final EdgeInsets padding;

  HorizontalCardPager(
      {this.items,
      this.onPageChanged,
      this.initialPage = 2,
      this.onSelectedItem,
      this.viewWidth,
      this.viewHeight,
      this.cardMaxWidth,
      this.cardMaxHeight,
      this.padding = const EdgeInsets.all(0),
      this.horizontalSpacing = 1.1});

  @override
  _HorizontalCardPagerState createState() => _HorizontalCardPagerState();
}

class _HorizontalCardPagerState extends State<HorizontalCardPager> {
  bool _isScrolling = false;
  double? _currentPosition;
  PageController? _controller;

  @override
  void initState() {
    super.initState();

    _currentPosition = widget.initialPage.toDouble();
    _controller = PageController(initialPage: widget.initialPage);

    _controller!.addListener(() {
      setState(() {
        _currentPosition = _controller!.page;

        if (widget.onPageChanged != null) {
          Future(() => widget.onPageChanged!(_currentPosition!));
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double viewWidth = widget.viewWidth ?? constraints.maxWidth;
      double viewHeight = widget.viewHeight ?? viewWidth / 5.0;

      double cardMaxWidth =
          widget.cardMaxWidth ?? widget.viewWidth ?? viewHeight;
      double cardMaxHeight =
          widget.cardMaxHeight ?? widget.viewHeight ?? cardMaxWidth;

      return GestureDetector(
          onHorizontalDragEnd: (details) {
            _isScrolling = false;
          },
          onHorizontalDragStart: (details) {
            _isScrolling = true;
          },
          onTapUp: (details) {
            if (_isScrolling == true) {
              return;
            }

            if ((_currentPosition! - _currentPosition!.floor()).abs() <= 0.15) {
              int selectedIndex = _onTapUp(
                  context, viewHeight, viewWidth, _currentPosition, details);

              if (selectedIndex == 2) {
                if (widget.onSelectedItem != null) {
                  Future(
                      () => widget.onSelectedItem!(_currentPosition!.round()));
                }
              } else if (selectedIndex >= 0) {
                int goToPage = _currentPosition!.toInt() + selectedIndex - 2;
                _controller!.animateToPage(goToPage,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOutExpo);
              }
            }
          },
          child: CardListWidget(
            items: widget.items,
            controller: _controller,
            viewWidth: viewWidth,
            selectedIndex: _currentPosition,
            cardMaxHeight: cardMaxHeight,
            cardMaxWidth: cardMaxWidth,
            horizontalSpacing: widget.horizontalSpacing,
            padding: widget.padding,
          ));
    });
  }

  int _onTapUp(context, cardMaxWidth, viewWidth, currentPosition, details) {
    final RenderBox box = context.findRenderObject();
    final Offset localOffset = box.globalToLocal(details.globalPosition);

    double dx = localOffset.dx;

    for (int i = 0; i < 5; i++) {
      double cardWidth = _getCardSize(cardMaxWidth, i, 2.0);
      double left = _getStartPosition(
          cardWidth, cardMaxWidth, viewWidth, i, 2.0, widget.horizontalSpacing);

      if (left <= dx && dx <= left + cardWidth) {
        return i;
      }
    }
    return -1;
  }
}

class CardListWidget extends StatefulWidget {
  final PageController? controller;
  final double? cardMaxWidth;
  final double? cardMaxHeight;
  final double? viewWidth;
  final List<CardItem>? items;
  final double? selectedIndex;
  final double horizontalSpacing;
  final EdgeInsets padding;

  CardListWidget(
      {this.controller,
      this.cardMaxHeight,
      this.cardMaxWidth,
      this.viewWidth,
      this.selectedIndex = 2.0,
      this.horizontalSpacing = 1.1,
      this.padding = const EdgeInsets.all(0),
      this.items});

  @override
  _CardListWidgetState createState() => _CardListWidgetState();
}

class _CardListWidgetState extends State<CardListWidget> {
  double? selectedIndex;

  @override
  void initState() {
    super.initState();

    selectedIndex = widget.selectedIndex;

    widget.controller!.addListener(() {
      setState(() {
        selectedIndex = widget.controller!.page;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> cardList = [];

    for (int i = 0; i < widget.items!.length; i++) {
      double cardWidth = _getCardSize(widget.cardMaxWidth, i, selectedIndex!);
      double cardHeight = cardWidth;

      Widget card = Positioned.directional(
          textDirection: TextDirection.ltr,
          top: _getTopPositon(cardHeight, widget.cardMaxHeight!),
          start: _getStartPosition(cardWidth, widget.cardMaxWidth,
              widget.viewWidth!, i, selectedIndex!, widget.horizontalSpacing),
          child: Opacity(
            opacity: _getOpacity(i),
            child: Container(margin: widget.padding,
              child: Center(
                child: widget.items![i]
                    .buildWidget((i.toDouble() - selectedIndex!).abs()),
              ),
              width: cardWidth,
              height: cardHeight,
            ),
          ));

      cardList.add(card);
    }

    return Stack(children: [
      Container(
        height: widget.cardMaxHeight!*1.1,
        child: Stack(
          children: cardList,
        ),
      ),
      Positioned.fill(
        child: PageView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: widget.items!.length,
          controller: widget.controller,
          itemBuilder: (context, index) {
            return Container();
          },
        ),
      )
    ]);
  }

  double _getOpacity(int cardIndex) {
    double diff = (selectedIndex! - cardIndex);

    if (diff >= -2 && diff <= 2) {
      return 1.0;
    } else if (diff > -3 && diff < -2) {
      return 3 - diff.abs();
    } else if (diff > 2 && diff < 3) {
      return 3 - diff.abs();
    } else {
      return 0;
    }
  }
}

double _getTopPositon(double cardHeigth, double viewHeight) {
  return (viewHeight - cardHeigth) / 2;
}

double _getStartPosition(
  double cardWidth,
  double? cardMaxWidth,
  double viewWidth,
  int cardIndex,
  double selectedIndex,
  double spacing,
) {
  double diff = (selectedIndex - cardIndex);
  double diffAbs = diff.abs();

  double basePosition = (viewWidth / 2) - (cardWidth / 2);

  if (diffAbs == 0) {
    return basePosition;
  }
  if (diffAbs > 0.0 && diffAbs <= 1.0) {
    if (diff >= 0) {
      return basePosition - (cardMaxWidth! * spacing) * diffAbs;
    } else {
      return basePosition + (cardMaxWidth! * spacing) * diffAbs;
    }
  } else if (diffAbs > 1.0 && diffAbs < 2.0) {
    if (diff >= 0) {
      return basePosition -
          (cardMaxWidth! * spacing) -
          cardMaxWidth * 0.9 * (diffAbs - diffAbs.floor()).abs();
    } else {
      return basePosition +
          (cardMaxWidth! * spacing) +
          cardMaxWidth * 0.9 * (diffAbs - diffAbs.floor()).abs();
    }
  } else {
    if (diff >= 0) {
      return basePosition - cardMaxWidth! * 2;
    } else {
      return basePosition + cardMaxWidth! * 2;
    }
  }
}

double _getCardSize(double? cardMaxWidth, int cardIndex, double selectedIndex) {
  double diff = (selectedIndex - cardIndex).abs();

  if (diff >= 0.0 && diff < 1.0) {
    return cardMaxWidth! - cardMaxWidth * (1 / 5) * ((diff - diff.floor()));
  } else if (diff >= 1.0 && diff < 2.0) {
    return cardMaxWidth! -
        cardMaxWidth * (1 / 5) -
        10 * ((diff - diff.floor()));
  } else if (diff >= 2.0 && diff < 3.0) {
    final size = cardMaxWidth! -
        cardMaxWidth * (1 / 5) -
        10 -
        5 * ((diff - diff.floor()));

    return size > 0 ? size : 0;
  } else {
    final size = cardMaxWidth! - cardMaxWidth * (1 / 5) - 15;

    return size > 0 ? size : 0;
  }
}
