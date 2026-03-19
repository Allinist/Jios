import 'package:flutter/material.dart';

class CalendarWidget extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final VoidCallback? onTodayTap;
  final Map<String, List<Color>> dateColorDots;

  const CalendarWidget({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.onTodayTap,
    this.dateColorDots = const {},
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  static const List<String> _weekLabels = ['日', '一', '二', '三', '四', '五', '六'];

  late DateTime _displayAnchor;
  late final PageController _pageController;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _displayAnchor = DateTime(widget.selectedDate.year, widget.selectedDate.month, 1);
    _pageController = PageController(initialPage: 1);
  }

  @override
  void didUpdateWidget(covariant CalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final DateTime target = _isExpanded
        ? DateTime(widget.selectedDate.year, widget.selectedDate.month, 1)
        : _weekStartOf(widget.selectedDate);

    final bool changed = _isExpanded ? !_isSameMonth(target, _displayAnchor) : !_isSameDay(target, _displayAnchor);
    if (changed) {
      _displayAnchor = target;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(1);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double expandedDayCellHeight = 40;
    const double collapsedDayCellHeight = 50;
    final int rowCount = _isExpanded ? 6 : 1;
    final double dayCellHeight = _isExpanded ? expandedDayCellHeight : collapsedDayCellHeight;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _buildTitle(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              IconButton(
                tooltip: '回到今天',
                onPressed: widget.onTodayTap,
                icon: const Icon(Icons.today),
              ),
              IconButton(
                tooltip: _isExpanded ? '折叠日历' : '展开日历',
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                    _displayAnchor = _isExpanded
                        ? DateTime(widget.selectedDate.year, widget.selectedDate.month, 1)
                        : _weekStartOf(widget.selectedDate);
                  });
                  if (_pageController.hasClients) {
                    _pageController.jumpToPage(1);
                  }
                },
                icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: _weekLabels
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: rowCount * dayCellHeight + (rowCount - 1) * 4,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _handlePageChanged,
              itemBuilder: (context, index) {
                if (_isExpanded) {
                  final DateTime month = DateTime(_displayAnchor.year, _displayAnchor.month + (index - 1), 1);
                  return _buildMonthGrid(month);
                }

                final DateTime weekStart = DateTime(
                  _displayAnchor.year,
                  _displayAnchor.month,
                  _displayAnchor.day + (index - 1) * 7,
                );
                return _buildWeekGrid(weekStart);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _buildTitle() {
    if (_isExpanded) {
      return '${_displayAnchor.year}年${_displayAnchor.month}月';
    }

    final DateTime start = _displayAnchor;
    final DateTime end = DateTime(start.year, start.month, start.day + 6);
    return '${start.month}月${start.day}日 - ${end.month}月${end.day}日';
  }

  Widget _buildMonthGrid(DateTime month) {
    final List<DateTime> days = _buildExpandedDays(month);

    return _buildGrid(
      days: days,
      isInDisplayMonth: (date) => date.month == month.month && date.year == month.year,
    );
  }

  Widget _buildWeekGrid(DateTime weekStart) {
    final List<DateTime> days = _buildCollapsedDays(weekStart);
    return _buildGrid(
      days: days,
      isInDisplayMonth: (_) => true,
    );
  }

  Widget _buildGrid({
    required List<DateTime> days,
    required bool Function(DateTime) isInDisplayMonth,
  }) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: days.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        final DateTime date = days[index];
        final bool selected = _isSameDay(date, widget.selectedDate);
        final bool inDisplayMonth = isInDisplayMonth(date);
        final List<Color> dots = widget.dateColorDots[_keyOf(date)] ?? const [];

        return GestureDetector(
          onTap: () {
            widget.onDateSelected(date);
          },
          child: Container(
            decoration: BoxDecoration(
              color: selected ? Colors.blue : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: selected ? Colors.white : (inDisplayMonth ? Colors.black87 : Colors.black38),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (dots.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: dots
                          .take(3)
                          .map(
                            (color) => Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: selected ? Colors.white : color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _keyOf(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  List<DateTime> _buildExpandedDays(DateTime month) {
    final DateTime firstDayOfMonth = DateTime(month.year, month.month, 1);
    final int leadingDays = firstDayOfMonth.weekday % 7;
    final DateTime startDay = firstDayOfMonth.subtract(Duration(days: leadingDays));

    return List.generate(42, (index) {
      return DateTime(startDay.year, startDay.month, startDay.day + index);
    });
  }

  List<DateTime> _buildCollapsedDays(DateTime weekStart) {
    return List.generate(7, (index) {
      return DateTime(weekStart.year, weekStart.month, weekStart.day + index);
    });
  }

  void _handlePageChanged(int index) {
    if (index == 1) {
      return;
    }

    final int offset = index == 0 ? -1 : 1;
    if (_isExpanded) {
      final DateTime nextMonth = DateTime(_displayAnchor.year, _displayAnchor.month + offset, 1);
      final DateTime adjustedSelectedDate = _adjustDateToTargetMonth(widget.selectedDate, nextMonth);

      setState(() {
        _displayAnchor = nextMonth;
      });

      widget.onDateSelected(adjustedSelectedDate);
    } else {
      final DateTime nextSelected = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day + offset * 7,
      );
      setState(() {
        _displayAnchor = _weekStartOf(nextSelected);
      });
      widget.onDateSelected(nextSelected);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(1);
      }
    });
  }

  DateTime _adjustDateToTargetMonth(DateTime baseDate, DateTime targetMonth) {
    final int maxDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
    final int day = baseDate.day > maxDay ? maxDay : baseDate.day;
    return DateTime(targetMonth.year, targetMonth.month, day);
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  DateTime _weekStartOf(DateTime day) {
    final int weekdayFromSunday = day.weekday % 7;
    return day.subtract(Duration(days: weekdayFromSunday));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
