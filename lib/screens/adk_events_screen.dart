import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/adk_event.dart';
import '../services/api_client.dart';

class AdkEventsScreen extends StatefulWidget {
  const AdkEventsScreen({super.key});

  static const routeName = '/adk-events';

  @override
  State<AdkEventsScreen> createState() => _AdkEventsScreenState();
}

class _AdkEventsScreenState extends State<AdkEventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _displayDateFormat = DateFormat('EEEE, dd-MMM-yyyy');
  final ApiClient _apiClient = ApiClient.instance;

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;
  String _searchQuery = '';
  List<AdkEvent> _events = const [];
  AdkEventPaginationMeta? _meta;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _loadEvents(initial: true);
  }

  Future<void> _handleRefresh() async {
    await _loadEvents();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      final query = _searchController.text.trim();
      setState(() => _searchQuery = query);
      _loadEvents();
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? _startDate ?? DateTime.now());
    final firstDate = DateTime(2020);
    final lastDate = DateTime(2030);

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (selected == null) return;

    setState(() {
      if (isStart) {
        _startDate = selected;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
        }
      } else {
        _endDate = selected;
        if (_startDate != null && _endDate!.isBefore(_startDate!)) {
          _startDate = null;
        }
      }
    });
  }

  void _handleApplyFilters() {
    FocusScope.of(context).unfocus();
    setState(() => _searchQuery = _searchController.text.trim());
    _loadEvents();
  }

  Future<void> _loadEvents({bool initial = false}) async {
    if (initial) {
      setState(() {
        _isLoading = true;
        _isError = false;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isError = false;
        _errorMessage = null;
      });
    }

    try {
      final response = await _apiClient.fetchAdkEvents(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        startDate: _startDate,
        endDate: _endDate,
      );
      if (!mounted) return;
      setState(() {
        _events = response.items;
        _meta = response.meta;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = error.toString();
      });
    }
  }

  String _dateLabel(DateTime? date) => date == null ? '' : DateFormat('dd MMM yyyy').format(date);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'ADK Events',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _FilterPanel(
              searchController: _searchController,
              onApplyFilters: _handleApplyFilters,
              onPickStart: () => _pickDate(isStart: true),
              onPickEnd: () => _pickDate(isStart: false),
              startDateLabel: _startDate != null ? _dateLabel(_startDate) : 'Start Date',
              endDateLabel: _endDate != null ? _dateLabel(_endDate) : 'End Date',
            ),
            if (_meta != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 16, left: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Showing ${_events.length} of ${_meta!.total} events',
                    style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                child: _buildList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (_, __) => const _CardSkeleton(),
      );
    }

    if (_isError) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 80),
        children: [
          _ErrorState(
            message: _errorMessage ?? 'Something went wrong while fetching events.',
            onRetry: _loadEvents,
          ),
        ],
      );
    }

    if (_events.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          Center(
            child: Text(
              'No events found',
              style: TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _events.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _EventCard(
          event: _events[index],
          dateFormat: _displayDateFormat,
        ),
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.searchController,
    required this.onApplyFilters,
    required this.onPickStart,
    required this.onPickEnd,
    required this.startDateLabel,
    required this.endDateLabel,
  });

  final TextEditingController searchController;
  final VoidCallback onApplyFilters;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final String startDateLabel;
  final String endDateLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          _InputWrapper(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Search by Leader Name, State & City',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: startDateLabel,
                  onTap: onPickStart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateField(
                  label: endDateLabel,
                  onTap: onPickEnd,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6EFD),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onApplyFilters,
              child: const Text('Apply Filter', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = label == 'Start Date' || label == 'End Date';
    return GestureDetector(
      onTap: onTap,
      child: _InputWrapper(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isPlaceholder ? Colors.grey : Colors.black87,
                  fontWeight: isPlaceholder ? FontWeight.w500 : FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _InputWrapper extends StatelessWidget {
  const _InputWrapper({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: child,
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.dateFormat});

  final AdkEvent event;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(offset: Offset(0, 1), blurRadius: 3, color: Color(0x0D000000)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _EventColumn(entries: _leftColumnData())),
          const SizedBox(width: 16),
          Expanded(child: _EventColumn(entries: _rightColumnData(dateFormat))),
        ],
      ),
    );
  }

  List<_EventEntry> _leftColumnData() => [
        _EventEntry(label: 'Leader Name', value: event.leaderName),
        _EventEntry(label: 'Meeting Time', value: event.meetingTime),
        _EventEntry(label: 'Address', value: event.address),
        _EventEntry(label: 'City', value: event.city),
        _EventEntry(label: 'Store Mobile Number', value: event.storeMobile),
      ];

  List<_EventEntry> _rightColumnData(DateFormat dateFormat) => [
        _EventEntry(label: 'Meeting Date', value: dateFormat.format(event.meetingDate)),
        _EventEntry(label: 'Store Name', value: event.storeName),
        _EventEntry(label: 'State', value: event.state),
        _EventEntry(label: 'Leader Mobile Number', value: event.leaderMobile),
      ];
}

class _EventColumn extends StatelessWidget {
  const _EventColumn({required this.entries});

  final List<_EventEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(entry.value, style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _EventEntry {
  const _EventEntry({required this.label, required this.value});

  final String label;
  final String value;
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D6EFD),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

