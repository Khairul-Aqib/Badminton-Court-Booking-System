import 'package:flutter/material.dart';
import '../database/supabase_service.dart';
import '../models/user.dart';
import '../models/court.dart';
import '../models/addon.dart';
import '../models/booking.dart';

class BookingScreen extends StatefulWidget {
  final User user;
  final Court? selectedCourt;

  const BookingScreen({super.key, required this.user, this.selectedCourt});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  List<Court> _courts = [];
  Court? _selectedCourt;
  List<Addon> _addons = [];
  Map<int, bool> _selectedAddons = {};
  DateTime? _bookingDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;
  bool _isDataLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedCourt = widget.selectedCourt;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results =
          await Future.wait([SupabaseService().getCourts(), SupabaseService().getAddons()]);
      final courts = results[0] as List<Court>;
      final addons = results[1] as List<Addon>;
      setState(() {
        _courts = courts;
        _addons = addons;
        _selectedAddons = {for (final a in addons) a.id: false};
        // Match by ID so the dropdown value is the exact same instance as the item
        final preselectedId = widget.selectedCourt?.id;
        if (preselectedId != null) {
          _selectedCourt = courts.firstWhere(
            (c) => c.id == preselectedId,
            orElse: () => courts.isNotEmpty ? courts.first : _selectedCourt!,
          );
        } else if (_selectedCourt == null && courts.isNotEmpty) {
          _selectedCourt = courts.first;
        }
        _isDataLoading = false;
      });
    } catch (e) {
      setState(() => _isDataLoading = false);
      _showSnackBar('Failed to load data: $e', Colors.red);
    }
  }

  double get _durationHours {
    if (_startTime == null || _endTime == null) return 0;
    final start = _startTime!.hour * 60 + _startTime!.minute;
    final end = _endTime!.hour * 60 + _endTime!.minute;
    return end > start ? (end - start) / 60.0 : 0;
  }

  double get _basePrice =>
      (_selectedCourt?.pricePerHour ?? 0) * _durationHours;

  double get _addonsTotal => _addons
      .where((a) => _selectedAddons[a.id] == true)
      .fold(0.0, (sum, a) => sum + a.price);

  double get _totalPrice => _basePrice + _addonsTotal;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
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
      initialTime: isStart
          ? const TimeOfDay(hour: 8, minute: 0)
          : const TimeOfDay(hour: 9, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.blue[800]!)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedCourt == null) {
      _showSnackBar('Please select a court', Colors.red);
      return;
    }
    if (_bookingDate == null) {
      _showSnackBar('Please select a date', Colors.red);
      return;
    }
    if (_startTime == null || _endTime == null) {
      _showSnackBar('Please select start and end time', Colors.red);
      return;
    }
    if (_durationHours <= 0) {
      _showSnackBar('End time must be after start time', Colors.red);
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

      final booking = Booking(
        userId: widget.user.id!,
        courtId: _selectedCourt!.id,
        bookingDate: dateStr,
        startTime: startStr,
        endTime: endStr,
        durationHours: _durationHours,
        basePrice: _basePrice,
        addonsTotal: _addonsTotal,
        totalAmount: _totalPrice,
      );

      final addonRows = _addons
          .where((a) => _selectedAddons[a.id] == true)
          .map((a) => {
                'addon_id': a.id,
                'price_each': a.price,
                'subtotal': a.price,
              })
          .toList();

      await SupabaseService().insertBooking(booking, addonRows);
      _showConfirmation();
    } catch (e) {
      _showSnackBar('Booking failed: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showConfirmation() {
    final selectedAddonNames = _addons
        .where((a) => _selectedAddons[a.id] == true)
        .map((a) => a.addonName)
        .join(', ');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.green[100], shape: BoxShape.circle),
              child: const Icon(Icons.check_circle,
                  color: Colors.green, size: 30),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Booking Confirmed!',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your court has been successfully booked.',
                style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Booking Details',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue[800])),
                  const SizedBox(height: 12),
                  _detailRow('Court', _selectedCourt!.courtName),
                  _detailRow(
                      'Date',
                      '${_bookingDate!.day}/${_bookingDate!.month}/${_bookingDate!.year}'),
                  _detailRow('Time',
                      '${_startTime!.format(context)} – ${_endTime!.format(context)}'),
                  _detailRow(
                      'Duration', '${_durationHours.toStringAsFixed(1)} hours'),
                  if (selectedAddonNames.isNotEmpty)
                    _detailRow('Add-ons', selectedAddonNames),
                  const Divider(),
                  _detailRow(
                      'Total', 'RM ${_totalPrice.toStringAsFixed(2)}',
                      isTotal: true),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back),
                  SizedBox(width: 8),
                  Text('Back to Dashboard',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:',
              style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: isTotal ? 16 : 14,
                  fontWeight:
                      isTotal ? FontWeight.bold : FontWeight.normal)),
          Flexible(
            child: Text(value,
                style: TextStyle(
                    color: isTotal ? Colors.green[700] : Colors.grey[800],
                    fontSize: isTotal ? 16 : 14,
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.w600),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Court',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isDataLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
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
                    // Court Selection
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                              Icons.sports_tennis, 'Select Court', Colors.blue),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<Court>(
                            value: _selectedCourt,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            items: _courts
                                .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                        '${c.courtName} – RM${c.pricePerHour.toStringAsFixed(0)}/hr')))
                                .toList(),
                            onChanged: (c) =>
                                setState(() => _selectedCourt = c),
                          ),
                          if (_selectedCourt != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: Colors.blue[200]!)),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: Colors.blue[800], size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${_selectedCourt!.courtType ?? 'Badminton Court'} · ${_selectedCourt!.capacity} players · RM${_selectedCourt!.pricePerHour.toStringAsFixed(0)}/hr',
                                      style: TextStyle(
                                          color: Colors.blue[800],
                                          fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date & Time
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(Icons.calendar_today,
                              'Date & Time', Colors.orange),
                          const SizedBox(height: 16),
                          _timeTile(
                            icon: Icons.date_range,
                            label: 'Booking Date',
                            value: _bookingDate != null
                                ? '${_bookingDate!.day}/${_bookingDate!.month}/${_bookingDate!.year}'
                                : 'Select Date',
                            selected: _bookingDate != null,
                            onTap: _pickDate,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _timeTile(
                                  icon: Icons.access_time,
                                  label: 'Start Time',
                                  value: _startTime != null
                                      ? _startTime!.format(context)
                                      : 'Select',
                                  selected: _startTime != null,
                                  onTap: () => _pickTime(true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _timeTile(
                                  icon: Icons.access_time_filled,
                                  label: 'End Time',
                                  value: _endTime != null
                                      ? _endTime!.format(context)
                                      : 'Select',
                                  selected: _endTime != null,
                                  onTap: () => _pickTime(false),
                                ),
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
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Add-ons
                    if (_addons.isNotEmpty)
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader(Icons.add_circle_outline,
                                'Add-ons', Colors.purple),
                            const SizedBox(height: 12),
                            ..._addons.map((addon) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color:
                                        (_selectedAddons[addon.id] ?? false)
                                            ? Colors.blue[50]
                                            : Colors.transparent,
                                    border: Border.all(
                                      color:
                                          (_selectedAddons[addon.id] ?? false)
                                              ? Colors.blue[200]!
                                              : Colors.transparent,
                                    ),
                                  ),
                                  child: CheckboxListTile(
                                    title: Text(addon.addonName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    subtitle: addon.description != null
                                        ? Text(addon.description!,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600]))
                                        : null,
                                    secondary: Text(
                                      'RM ${addon.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          color: Colors.green[600],
                                          fontWeight: FontWeight.w600),
                                    ),
                                    value:
                                        _selectedAddons[addon.id] ?? false,
                                    onChanged: (v) => setState(
                                        () => _selectedAddons[addon.id] = v!),
                                    activeColor: Colors.blue[800],
                                    checkColor: Colors.white,
                                  ),
                                )),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Price Summary
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [Colors.green[400]!, Colors.green[600]!]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.receipt,
                                  color: Colors.white, size: 24),
                              SizedBox(width: 12),
                              Text('Price Summary',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _priceRow('Court (${_durationHours.toStringAsFixed(1)} hrs)',
                              _basePrice),
                          if (_addonsTotal > 0)
                            _priceRow('Add-ons', _addonsTotal),
                          const Divider(color: Colors.white54),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total:',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                'RM ${_totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 18),
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
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Processing...'),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.payment, size: 24),
                                  SizedBox(width: 12),
                                  Text('Confirm Booking',
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

  Widget _card({required Widget child}) => Container(
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
        child: child,
      );

  Widget _sectionHeader(IconData icon, String title, Color color) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      );

  Widget _timeTile({
    required IconData icon,
    required String label,
    required String value,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
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
              Row(
                children: [
                  Icon(icon, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 4),
                  Text(label,
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ],
              ),
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

  Widget _priceRow(String label, double amount) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(color: Colors.white, fontSize: 15)),
            Text('RM ${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
