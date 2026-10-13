import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_f01/core/tools/debounce.dart';
import 'package:prbd_2526_f01/models/reservation.dart';
import 'package:prbd_2526_f01/models/restaurant.dart';
import 'package:prbd_2526_f01/providers/client_state_provider.dart';
import 'package:prbd_2526_f01/providers/simulated_time_provider.dart';
import 'package:prbd_2526_f01/views/widgets/page_app_bar.dart';
import 'package:prbd_2526_f01/views/widgets/reservation_form_fields.dart';
import 'package:prbd_2526_f01/views/widgets/slots_section.dart';

class ClientAddReservationPage extends ConsumerStatefulWidget {
  final Restaurant restaurant;

  const ClientAddReservationPage({super.key, required this.restaurant});

  @override
  ConsumerState<ClientAddReservationPage> createState() =>
      _ClientAddReservationPageState();
}

class _ClientAddReservationPageState
    extends ConsumerState<ClientAddReservationPage> {
  static const int _maxDayLookahead = 30;

  final _guestsDebouncer = Debouncer(delay: const Duration(milliseconds: 400));
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  DateTime selectedDate = DateTime.now();
  String? selectedTime;
  int numberOfGuests = 2;
  List<AvailableSlot> slots = [];
  bool loadingSlots = true;
  String specialRequests = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final nowRef = await ref
        .read(simulatedTimeProvider.future)
        .catchError((_) => DateTime.now());
    if (!mounted) return;
    setState(() => selectedDate = _firstServiceDateFrom(nowRef));
    await loadSlots(autoAdvance: true);
  }

  DateTime _firstServiceDateFrom(DateTime nowRef) {
    final today = DateTime(nowRef.year, nowRef.month, nowRef.day);
    final serviceDays = (widget.restaurant.services ?? [])
        .map((s) => s.dayOfWeek)
        .toSet();
    if (serviceDays.isEmpty) return today;
    var d = today;
    for (var i = 0; i < _maxDayLookahead; i++) {
      if (serviceDays.contains(d.weekday)) return d;
      d = d.add(const Duration(days: 1));
    }
    return today;
  }

  DateTime get _nowRef => ref
      .read(simulatedTimeProvider)
      .maybeWhen(data: (d) => d, orElse: () => DateTime.now());

  EmptySlotsReason _emptyReason() {
    if (slots.isNotEmpty) return EmptySlotsReason.none;

    final restaurantIsOpenThatDay = (widget.restaurant.services ?? []).any(
      (s) => s.dayOfWeek == selectedDate.weekday,
    );
    if (!restaurantIsOpenThatDay) return EmptySlotsReason.closed;

    final userReservations = ref
        .read(clientStateProvider)
        .maybeWhen(data: (s) => s.reservations, orElse: () => const []);
    final userAlreadyBookedThatDay = userReservations.any(
      (r) =>
          r.restaurant.id == widget.restaurant.id &&
          r.datetime.year == selectedDate.year &&
          r.datetime.month == selectedDate.month &&
          r.datetime.day == selectedDate.day &&
          r.status != 'cancelled',
    );

    if (userAlreadyBookedThatDay) return EmptySlotsReason.userBooked;
    return EmptySlotsReason.none;
  }

  @override
  Widget build(BuildContext context) {
    final simulatedTime = ref
        .watch(simulatedTimeProvider)
        .maybeWhen(data: (d) => d, orElse: () => DateTime.now());

    ref.listen(simulatedTimeProvider, (previous, next) {
      if (previous?.value != next.value) loadSlots();
    });

    final selectedSlot = slots.findByTime(selectedTime);
    final overcapacity =
        selectedSlot != null && numberOfGuests > selectedSlot.remainingCapacity;
    final emptyReason = _emptyReason();

    return Scaffold(
      appBar: PageAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: 'Nouvelle réservation',
        onRefreshPressed: loadSlots,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ReservationFormFields(
              restaurantName: widget.restaurant.name,
              selectedDate: selectedDate,
              onPickDate: () => _pickDate(simulatedTime),
              onPrevDay: () => _shiftDay(-1),
              onNextDay: () => _shiftDay(1),
              slotsSection: SlotsSection(
                loading: loadingSlots,
                slots: slots,
                selectedTime: selectedTime,
                emptyReason: emptyReason,
                onSelect: (time) => setState(() => selectedTime = time),
              ),
              numberOfGuests: numberOfGuests,
              onGuestsMinus: numberOfGuests > 1
                  ? () => _changeGuests(-1)
                  : null,
              onGuestsPlus: numberOfGuests < 10 ? () => _changeGuests(1) : null,
              onSpecialRequestsChanged: (value) {
                if (value.isEmpty || value.length >= 10) {
                  setState(() => specialRequests = value);
                }
              },
              canSubmit: selectedTime != null,
              onSubmit: _submit,
              submitLabel: 'Créer la réservation',
              submitIcon: Icons.add,
              showOvercapacityWarning: overcapacity,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(DateTime simulatedTime) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(
        simulatedTime.year,
        simulatedTime.month,
        simulatedTime.day,
      ),
      lastDate: DateTime(
        simulatedTime.year + 1,
        simulatedTime.month,
        simulatedTime.day,
      ),
    );
    if (!context.mounted || picked == null) return;
    setState(() => selectedDate = picked);
    loadSlots();
  }

  void _shiftDay(int days) {
    setState(() => selectedDate = selectedDate.add(Duration(days: days)));
    loadSlots();
  }

  void _changeGuests(int delta) {
    setState(() => numberOfGuests += delta);
    _guestsDebouncer(() {
      if (mounted) loadSlots();
    });
  }

  @override
  void dispose() {
    _guestsDebouncer.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final datetime = slots.findByTime(selectedTime)!.toDateTimeOn(selectedDate);

    try {
      await ref
          .read(clientStateProvider.notifier)
          .saveReservation(
            restaurantId: widget.restaurant.id,
            datetime: datetime,
            numberOfGuests: numberOfGuests,
            specialRequests: specialRequests.isEmpty ? null : specialRequests,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Réservation créée avec succès.')),
      );
      Navigator.of(context).popUntil(
        (route) =>
            route.settings.name == '/client/reservations' || route.isFirst,
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $error'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> loadSlots({bool autoAdvance = false}) async {
    setState(() => loadingSlots = true);

    try {
      await _loadSlotsAutoAdvancing(autoAdvance: autoAdvance);
    } catch (e) {
      setState(() {
        slots = [];
        selectedTime = null;
        loadingSlots = false;
      });
    }
  }

  Future<void> _loadSlotsAutoAdvancing({required bool autoAdvance}) async {
    for (var i = 0; i < _maxDayLookahead; i++) {
      final filtered = await _fetchAndFilterSlotsForCurrentDate();

      if (autoAdvance && filtered.isEmpty) {
        selectedDate = selectedDate.add(const Duration(days: 1));
        continue;
      }

      setState(() {
        slots = filtered;
        selectedTime = _pickSelectedTime(filtered);
        loadingSlots = false;
      });
      return;
    }

    setState(() {
      slots = [];
      selectedTime = null;
      loadingSlots = false;
    });
  }

  Future<List<AvailableSlot>> _fetchAndFilterSlotsForCurrentDate() async {
    final rawSlots = await Reservation.getAvailableSlots(
      restaurantId: widget.restaurant.id,
      date: selectedDate,
      guests: numberOfGuests,
    );
    return _filterPastSlots(rawSlots);
  }

  List<AvailableSlot> _filterPastSlots(List<AvailableSlot> rawSlots) {
    final nowRef = _nowRef;
    return rawSlots
        .where((slot) => !slot.toDateTimeOn(selectedDate).isBefore(nowRef))
        .toList();
  }

  String? _pickSelectedTime(List<AvailableSlot> filtered) {
    final currentSelectionStillAvailable =
        selectedTime != null && filtered.any((s) => s.time == selectedTime);
    if (currentSelectionStillAvailable) return selectedTime;
    if (filtered.isNotEmpty) return filtered.first.time;
    return null;
  }
}
