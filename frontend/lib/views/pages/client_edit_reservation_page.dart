import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_f01/core/tools/debounce.dart';
import 'package:prbd_2526_f01/models/reservation.dart';
import 'package:prbd_2526_f01/providers/client_state_provider.dart';
import 'package:prbd_2526_f01/providers/simulated_time_provider.dart';
import 'package:prbd_2526_f01/views/widgets/page_app_bar.dart';
import 'package:prbd_2526_f01/views/widgets/reservation_form_fields.dart';
import 'package:prbd_2526_f01/views/widgets/slots_section.dart';

class ClientEditReservationPage extends ConsumerStatefulWidget {
  final Reservation reservation;

  const ClientEditReservationPage({super.key, required this.reservation});

  @override
  ConsumerState<ClientEditReservationPage> createState() =>
      _ClientEditReservationPageState();
}

class _ClientEditReservationPageState
    extends ConsumerState<ClientEditReservationPage> {
  final Debouncer _guestsDebouncer = Debouncer();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late DateTime selectedDate;
  String? selectedTime;
  late int numberOfGuests;
  List<AvailableSlot> slots = [];
  bool loadingSlots = false;
  String specialRequests = '';

  @override
  void initState() {
    super.initState();
    final dt = widget.reservation.datetime;
    selectedDate = DateTime(dt.year, dt.month, dt.day);
    selectedTime = _formatTime(dt);
    numberOfGuests = widget.reservation.numberOfGuests;
    specialRequests = widget.reservation.specialRequests ?? '';
    loadSlots();
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  DateTime get _nowRef => ref
      .read(simulatedTimeProvider)
      .maybeWhen(data: (d) => d, orElse: () => DateTime.now());

  EmptySlotsReason _emptyReason() {
    if (slots.isNotEmpty) return EmptySlotsReason.none;

    final restaurantIsOpenThatDay =
        (widget.reservation.restaurant.services ?? []).any(
          (s) => s.dayOfWeek == selectedDate.weekday,
        );
    if (!restaurantIsOpenThatDay) return EmptySlotsReason.closed;

    final userReservations = ref
        .read(clientStateProvider)
        .maybeWhen(data: (s) => s.reservations, orElse: () => const []);
    final userAlreadyBookedThatDay = userReservations.any(
      (r) =>
          r.id != widget.reservation.id &&
          r.restaurant.id == widget.reservation.restaurant.id &&
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
        title: 'Modifier la réservation',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ReservationFormFields(
              restaurantName: widget.reservation.restaurant.name,
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
              initialSpecialRequests: specialRequests,
              onSpecialRequestsChanged: (value) {
                if (value.isEmpty || value.length >= 10) {
                  setState(() => specialRequests = value);
                }
              },
              canSubmit: selectedTime != null,
              onSubmit: _submit,
              submitLabel: 'Modifier la réservation',
              submitIcon: Icons.edit,
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

  Future<bool> _confirmDowngradeDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la modification'),
        content: const Text(
          'Cette réservation est confirmée. La modifier la remettra en attente '
          'et libérera les tables éventuellement attribuées. Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final datetime = slots.findByTime(selectedTime)!.toDateTimeOn(selectedDate);

    if (widget.reservation.status == 'confirmed' &&
        widget.reservation.datetime.isAfter(_nowRef)) {
      final confirmed = await _confirmDowngradeDialog();
      if (!confirmed) return;
      if (!mounted) return;
    }

    try {
      await ref
          .read(clientStateProvider.notifier)
          .saveReservation(
            id: widget.reservation.id,
            restaurantId: widget.reservation.restaurant.id,
            datetime: datetime,
            numberOfGuests: numberOfGuests,
            specialRequests: specialRequests.isEmpty ? null : specialRequests,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Réservation modifiée avec succès.')),
      );

      Navigator.of(context).pop();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $error'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> loadSlots() async {
    setState(() => loadingSlots = true);

    try {
      final rawSlots = await Reservation.getAvailableSlots(
        restaurantId: widget.reservation.restaurant.id,
        date: selectedDate,
        guests: numberOfGuests,
        excludeReservationId: widget.reservation.id,
      );

      final filtered = _filterPastSlots(rawSlots);

      setState(() {
        slots = filtered;
        selectedTime = _pickSelectedTime(filtered);
        loadingSlots = false;
      });
    } catch (e) {
      setState(() {
        slots = [];
        selectedTime = null;
        loadingSlots = false;
      });
    }
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
