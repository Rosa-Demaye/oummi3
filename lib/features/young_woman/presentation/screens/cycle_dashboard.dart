import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:oummi3/core/theme/app_theme.dart';
import 'package:oummi3/core/widgets/oumi_widgets.dart';
import 'package:oummi3/features/young_woman/presentation/providers/cycle_provider.dart';
import 'package:oummi3/shared/models/cycle_model.dart';
import 'package:oummi3/features/auth/presentation/providers/auth_provider.dart';

class Event {
  final String title;
  final Color color;
  const Event(this.title, this.color);
}

class CycleDashboard extends ConsumerStatefulWidget {
  const CycleDashboard({super.key});

  @override
  ConsumerState<CycleDashboard> createState() => _CycleDashboardState();
}

class _CycleDashboardState extends ConsumerState<CycleDashboard> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cycleStateProvider.notifier).startListening();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cycleStateProvider);
    final userProfile = ref.watch(userProfileProvider).value;
    final name = userProfile?.fullName.split(' ').first ?? 'Jeune fille';

    if (state.status == CycleStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.isFirstLaunch) {
      return _buildFirstLaunchOnboarding();
    }

    return Scaffold(
      backgroundColor: OumiColors.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverPadding(
            padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 20),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mardi 12 Août 2025', style: OumiTypography.bodySmall),
                      Text('Bonjour, $name 💜', style: OumiTypography.h1),
                    ],
                  ),
                  _buildNotificationIcon(),
                ],
              ),
            ),
          ),

          // Period Status Card
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: _buildStatusCard(state),
            ),
          ),

          // Calendar Card
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(
              child: _buildCalendarCard(state),
            ),
          ),

          // AI Insight
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: _buildInsightCard(state),
            ),
          ),

          // Quick Actions Grid
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OumiSectionHeader(title: 'Suivi quotidien'),
                  const SizedBox(height: 12),
                  _buildQuickCheckInGrid(),
                ],
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildFirstLaunchOnboarding() {
    return Scaffold(
      backgroundColor: OumiColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_month, size: 80, color: OumiColors.primary),
              const SizedBox(height: 24),
              Text('Commençons par comprendre votre cycle', style: OumiTypography.h1, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(
                'Enregistrez vos dernières règles pour personnaliser votre suivi et vos prédictions.',
                style: OumiTypography.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              OumiButton(
                label: 'Enregistrer mes dernières règles',
                onPressed: () => _showLogPeriodDialog(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogPeriodDialog() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: OumiColors.primary,
              onPrimary: Colors.white,
              onSurface: OumiColors.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final user = ref.read(userProfileProvider).value;
      if (user != null) {
        final newRecord = CycleRecord(
          id: '',
          userId: user.uid,
          startDate: picked,
          phase: CyclePhase.menstruation,
          isFertile: false,
          ovulationToday: false,
          pregnancyProbability: 0.0,
          fertilityProbability: 0.1,
        );
        await ref.read(cycleStateProvider.notifier).saveRecord(newRecord);
        // This will trigger the fertility update automatically via repo/notifier if implemented
      }
    }
  }

  Widget _buildStatusCard(CycleState state) {
    final days = state.daysUntilNextPeriod;
    return OumiCard(
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: OumiColors.redLight, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.water_drop, color: OumiColors.red),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prochaines règles dans', style: OumiTypography.bodySmall),
                Text('$days jours', style: OumiTypography.display.copyWith(fontSize: 22)),
              ],
            ),
          ),
          const OumiBadge(label: 'Cycle régulier ✓', color: OumiColors.green),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(color: OumiColors.primaryLight, borderRadius: BorderRadius.circular(14)),
      child: const Icon(Icons.notifications_outlined, color: OumiColors.primary),
    );
  }

  Widget _buildCalendarCard(CycleState state) {
    return OumiCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          TableCalendar<Event>(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: (day) => _getEventsForDay(day, state),
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(color: OumiColors.primary, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: OumiColors.primaryDark, shape: BoxShape.circle),
              markerDecoration: BoxDecoration(color: OumiColors.red, shape: BoxShape.circle),
              markersMaxCount: 4,
            ),
          ),
          const SizedBox(height: 16),
          _buildCalendarLegend(),
        ],
      ),
    );
  }

  List<Event> _getEventsForDay(DateTime day, CycleState state) {
    final List<Event> events = [];
    final record = state.record;
    if (record == null) return events;

    // Normalize day to midnight for comparison
    final normalizedDay = DateTime(day.year, day.month, day.day);

    // 🔴 Period
    if (record.startDate.isBefore(normalizedDay.add(const Duration(days: 1))) &&
        (record.endDate == null || record.endDate!.isAfter(normalizedDay.subtract(const Duration(days: 1))))) {
      events.add(const Event('Règles', OumiColors.red));
    }

    // 🟣 Ovulation
    if (record.ovulationDate != null && isSameDay(record.ovulationDate, normalizedDay)) {
      events.add(const Event('Ovulation', OumiColors.primary));
    }

    // 🟢 Fertile window (Mock logic for now, should be in record)
    if (record.ovulationDate != null) {
      final fertileStart = record.ovulationDate!.subtract(const Duration(days: 5));
      final fertileEnd = record.ovulationDate!.add(const Duration(days: 1));
      if (normalizedDay.isAfter(fertileStart.subtract(const Duration(days: 1))) &&
          normalizedDay.isBefore(fertileEnd)) {
        events.add(const Event('Fertile', OumiColors.teal));
      }
    }

    return events;
  }

  Widget _buildCalendarLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _legendItem(OumiColors.red, 'Règles'),
        _legendItem(OumiColors.teal, 'Ovulation'),
        _legendItem(OumiColors.tealLight, 'Fertile'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: OumiTypography.caption),
      ],
    );
  }

  Widget _buildInsightCard(CycleState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OumiColors.soft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OumiColors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💡 Insights OUMI', style: OumiTypography.label.copyWith(color: OumiColors.primary)),
          const SizedBox(height: 8),
          Text(
            'Votre cycle est régulier (28 jours en moyenne). Les prochaines règles sont estimées dans 5 jours. Fenêtre fertile prochaine autour du 14 sept.',
            style: OumiTypography.body.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCheckInGrid() {
    final List<Map<String, dynamic>> symptoms = [
      {'icon': '😴', 'label': 'Fatigue', 'type': Symptom.fatigue},
      {'icon': '😰', 'label': 'Crampes', 'type': Symptom.cramps},
      {'icon': '🤕', 'label': 'Mal de tête', 'type': Symptom.headache},
      {'icon': '🤢', 'label': 'Nausées', 'type': Symptom.nausea},
      {'icon': '😤', 'label': 'Ballonnements', 'type': Symptom.bloating},
      {'icon': '💪', 'label': 'Énergie', 'type': null},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: symptoms.length,
      itemBuilder: (context, index) {
        final s = symptoms[index];
        return OumiCard(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          radius: 16,
          onTap: () => _handleQuickLog(s),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(s['icon'], style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 6),
              Text(
                s['label'], 
                textAlign: TextAlign.center,
                style: OumiTypography.label.copyWith(
                  fontSize: 10.5,
                  color: OumiColors.textMuted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleQuickLog(Map<String, dynamic> item) {
    if (item['type'] != null) {
      _logSymptom(item['type'] as Symptom);
    } else {
      _showMoodPicker();
    }
  }

  void _logSymptom(Symptom symptom) async {
    final checkIn = DailyCheckIn(
      date: DateTime.now(),
      symptoms: [symptom],
      sexualActivity: SexualActivity.protected,
    );
    await ref.read(cycleStateProvider.notifier).submitDailyCheckIn(checkIn);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${symptom.name} enregistré ✓'), backgroundColor: OumiColors.primary),
      );
    }
  }

  void _showMoodPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Comment vous sentez-vous ?', style: OumiTypography.h2),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _moodIcon(Mood.happy, '😊'),
                  _moodIcon(Mood.calm, '😌'),
                  _moodIcon(Mood.neutral, '😐'),
                  _moodIcon(Mood.sad, '😢'),
                  _moodIcon(Mood.stressed, '😫'),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _moodIcon(Mood mood, String emoji) {
    return InkWell(
      onTap: () async {
        final checkIn = DailyCheckIn(
          date: DateTime.now(),
          symptoms: [],
          mood: mood,
          sexualActivity: SexualActivity.protected,
        );
        await ref.read(cycleStateProvider.notifier).submitDailyCheckIn(checkIn);
        if (mounted) Navigator.pop(context);
      },
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 4),
          Text(mood.name, style: OumiTypography.caption),
        ],
      ),
    );
  }
}
