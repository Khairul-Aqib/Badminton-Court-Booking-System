import 'package:flutter/material.dart';
import '../database/supabase_service.dart';
import '../models/booking.dart';

class EditBookingScreen extends StatefulWidget {
  final Booking booking;

  const EditBookingScreen({super.key, required this.booking});

  @override
  _EditBookingScreenState createState() => _EditBookingScreenState();
}

class _EditBookingScreenState extends State<EditBookingScreen> {
  DateTime? _bookingDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    // Parse booking_date (YYYY-MM-DD)
    final parts = widget.booking.bookingDate.split('-');
    if (parts.length == 3) {
      _bookingDate = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    }

    // Parse start_time (HH:MM:SS or HH:MM)
    final startParts = widget.booking.startTime.split(':');
    if (startParts.length >= 2) {
      _startTime = TimeOfDay(
          hour: int.parse(startParts[0]),
          minute: int.parse(startParts[1]));
    }

    final endParts = widget.booking.endTime.split(':');
    if (endParts.length >= 2) {
      _endTime = TimeOfDay(
          hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
    }
  }

  double get _durationHours {
    if (_startTime == null || _endTime == null) return 0;
    final start = _startTime!.hour * 60 + _startTime!.minute;
    final end = _endTime!.hour * 60 + _endTime!.minute;
    return end > start ? (end - start) / 60.0 : 0;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _bookingDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.blue[800]!)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _bookingDate = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ??
          const TimeOfDay(hour: 8, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.blue[800]!)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => isStart ? _startTime = picked : _endTime = picked);
    }
  }

  Future<void> _updateBooking() async {
    if (_bookingDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')));
      return;
    }
    if (_durationHours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dateStr =
          '${_bookingDate!.year}-${_bookingDate!.month.toString().padLeft(2, '0')}-${_bookingDate!.day.toString().padLeft(2, '0')}';
      final startStr =
          '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00';
      final endStr =
          '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00';

      await SupabaseService().updateBooking(
          widget.booking.id!, dateStr, startStr, endStr, _durationHours);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 12),
              Text('Booking Updated!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your booking schedule has been updated.'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Updated Schedule:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                        'Date: ${_bookingDate!.day}/${_bookingDate!.month}/${_bookingDate!.year}'),
                    Text(
                        'Time: ${_startTime!.format(context)} – ${_endTime!.format(context)}'),
                    Text(
                        'Duration: ${_durationHours.toStringAsFixed(1)} hours'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Update failed: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Booking',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[800]!, Colors.grey[50]!],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current booking info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[800]),
                        const SizedBox(width: 12),
                        const Text('Current Booking',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.sports_tennis,
                                color: Colors.grey[600], size: 20),
                            const SizedBox(width: 8),
                            Text(
                                'Court: ${widget.booking.courtName ?? '#${widget.booking.courtId}'}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15)),
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [
                            Icon(Icons.attach_money,
                                color: Colors.grey[600], size: 20),
                            const SizedBox(width: 8),
                            Text(
                                'Total: RM ${widget.booking.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15)),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Date & Time pickers
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_calendar, color: Colors.blue[800]),
                        const SizedBox(width: 12),
                        const Text('Update Schedule',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _tile('Date',
                        _bookingDate != null
                            ? '${_bookingDate!.day}/${_bookingDate!.month}/${_bookingDate!.year}'
                            : 'Select Date',
                        _bookingDate != null, _pickDate),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _tile(
                              'Start Time',
                              _startTime != null
                                  ? _startTime!.format(context)
                                  : 'Select',
                              _startTime != null,
                              () => _pickTime(true)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _tile(
                              'End Time',
                              _endTime != null
                                  ? _endTime!.format(context)
                                  : 'Select',
                              _endTime != null,
                              () => _pickTime(false)),
                        ),
                      ],
                    ),
                    if (_durationHours > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            Icon(Icons.timer,
                                color: Colors.orange[800], size: 18),
                            const SizedBox(width: 8),
                            Text(
                                'Duration: ${_durationHours.toStringAsFixed(1)} hours',
                                style: TextStyle(
                                    color: Colors.orange[800],
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white)),
                            SizedBox(width: 12),
                            Text('Updating...'),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save),
                            SizedBox(width: 12),
                            Text('Update Booking',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(String label, String value, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
              color: selected ? Colors.blue[300]! : Colors.grey[300]!,
              width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
          color: selected ? Colors.blue[50] : Colors.grey[50],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.black : Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
