/// Simple date range type for domain logic, avoiding Flutter dependencies.
class DateRange {
  final DateTime? start;
  final DateTime? end;

  DateRange({this.start, this.end}) {
    if (start != null && end != null) {
      assert(!end!.isBefore(start!), 'end must be on/after start');
    }
  }

  bool contains(DateTime value) {
    final afterStart = start == null || !value.isBefore(start!);
    final beforeEnd = end == null || !value.isAfter(end!);
    return afterStart && beforeEnd;
  }
}