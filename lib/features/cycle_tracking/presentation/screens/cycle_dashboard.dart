import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:oummi3/core/themes/app_theme.dart';
import 'package:oummi3/core/widgets/reusable_lottie.dart';
import 'package:oummi3/features/cycle_tracking/presentation/providers/cycle_provider.dart';
import 'package:oummi3/features/cycle_tracking/data/models/cycle_model.dart';

class Event {
  final Widget title;
  final Color? color;
  const Event({required this.title, this.color});
}

class CycleDashboard extends ConsumerStatefulWidget {
  const CycleDashboard({super.key});

  @override
  ConsumerState<CycleDashboard> createState() => _CycleDashboardState();
}

class _CycleDashboardState extends ConsumerState<CycleDashboard> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    
    // Start listening to the cycle records
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cycleStateProvider.notifier).startListening();
    });
  }

  void _onCycleStateChanged(CycleState state) {
    if (state.status == CycleStatus.loaded && state.record != null) {
      final record = state.record!;
      final Map<DateTime, List<Event>> newEvents = {};
      
      for (final entry in record.dailyCheckIns.entries) {
        final date = entry.key;
        final checkIn = entry.value;
        final day = DateTime(date.year, date.month, date.day);
        newEvents.putIfAbsent(day, () => [_buildEventFromCheckIn(checkIn)]);
      }
      
      setState(() {
        _events = newEvents;
      });
    }
  }

  Event _buildEventFromCheckIn(DailyCheckIn checkIn) {
    return Event(
      title: _moodIcon(checkIn.mood),
      color: _moodColor(checkIn.mood),
    );
  }

  Widget _moodIcon(Mood? mood) {
    switch (mood) {
      case Mood.happy:
        return const Icon(Icons.sentiment_very_satisfied, size: 16, color: Colors.green);
      case Mood.stressed:
        return const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange);
      case Mood.sad:
        return const Icon(Icons.sentiment_very_dissatisfied, size: 16, color: Colors.blue);
      default:
        return const Icon(Icons.face, size: 16, color: Colors.grey);
    }
  }

  Color _moodColor(Mood? mood) {
    switch (mood) {
      case Mood.happy:
        return OumiColors.vertSante;
      case Mood.stressed:
        return OumiColors.orangeAlerte;
      case Mood.sad:
        return OumiColors.bleuSante;
      default:
        return OumiColors.grisTexte;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CycleState>(cycleStateProvider, (previous, next) {
      _onCycleStateChanged(next);
      if (next.showPregnancyPrompt && !(previous?.showPregnancyPrompt ?? false)) {
        _showPregnancyTransitionDialog(context);
      }
    });

    final state = ref.watch(cycleStateProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: OumiColors.blanc,
        elevation: 0,
        title: const Text(
          'OUMI Cycle',
          style: TextStyle(color: OumiColors.noirDoux, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: OumiColors.noirDoux),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== HEADER STATS =====
              _buildHeaderStats(state),
              const SizedBox(height: 24),

              // ===== CYCLE OVERVIEW =====
              _buildCycleOverview(state),
              const SizedBox(height: 24),

              // ===== INTERACTIVE CALENDAR =====
              _buildCalendar(),
              const SizedBox(height: 24),

              // ===== DAILY CHECK-IN QUICK ACTIONS =====
              _buildQuickCheckIn(context),
              const SizedBox(height: 24),

              // ===== AI INSIGHT CARD =====
              _buildAiInsightCard(state),
              const SizedBox(height: 32),

              // ===== QUICK ACTIONS BAR =====
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStats(CycleState state) {
    if (state.status != CycleStatus.loaded || state.record == null) {
      return const Center(child: CircularProgressIndicator(color: OumiColors.oumiRose));
    }
    
    final record = state.record!;
    final dayInCycle = DateTime.now().difference(record.startDate).inDays + 1;

    return Row(
      children: [
        _statCard('Jour cycle', '$dayInCycle'),
        const SizedBox(width: 8),
        _statCard('Phase', _phaseLabel(record.phase)),
        const SizedBox(width: 8),
        _statCard('Fertilité', '${(record.fertilityProbability * 100).round()}%'),
      ],
    );
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OumiColors.roseClair,
          borderRadius: BorderRadius.circular(OumiDecorations.defaultRadius),
          boxShadow: [OumiDecorations.cardShadow],
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: OumiColors.grisTexte, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: OumiColors.noirDoux, fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  String _phaseLabel(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstruation: return 'Règles';
      case CyclePhase.follicular: return 'Folliculaire';
      case CyclePhase.ovulation: return 'Ovulation';
      case CyclePhase.luteal: return 'Lutéale';
    }
  }

  Widget _buildCycleOverview(CycleState state) {
    if (state.record == null) return const SizedBox.shrink();
    final record = state.record!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phase actuelle : ${_phaseLabel(record.phase)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: OumiColors.noirDoux),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _progressRing(
              value: record.fertilityProbability,
              label: 'Fenêtre fertile',
              color: OumiColors.vertSante,
            ),
            _progressRing(
              value: record.pregnancyProbability,
              label: 'Probabilité grossesse',
              color: OumiColors.peachCorail,
            ),
          ],
        ),
      ],
    );
  }

  Widget _progressRing({required double value, required String label, required Color color}) {
    final scaledValue = value.clamp(0.0, 1.0);
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: CustomPaint(
            painter: _RingPainter(progress: scaledValue, color: color),
            child: Center(
              child: Text(
                '${(scaledValue * 100).round()}%',
                style: const TextStyle(color: OumiColors.noirDoux, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: OumiColors.grisTexte, fontSize: 12)),
      ],
    );
  }

  Widget _buildCalendar() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar<Event>(
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
          eventLoader: (day) {
            final normalizedDay = DateTime(day.year, day.month, day.day);
            return _events[normalizedDay] ?? [];
          },
          calendarStyle: const CalendarStyle(
            markerDecoration: BoxDecoration(color: OumiColors.oumiRose, shape: BoxShape.circle),
            selectedDecoration: BoxDecoration(color: OumiColors.oumiRose, shape: BoxShape.circle),
            todayDecoration: BoxDecoration(color: OumiColors.violetOumi, shape: BoxShape.circle),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickCheckIn(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Check-in du jour', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: OumiColors.noirDoux)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _showDailyCheckInDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: OumiColors.oumiRose,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              child: const Text('Enregistrer mon check-in'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDailyCheckInDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check-in quotidien'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Symptômes: crampes, maux de tête...'),
              SizedBox(height: 8),
              Text('Humeur: content, calme, triste...'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              ref.read(cycleStateProvider.notifier).submitDailyCheckIn(
                DailyCheckIn(
                  date: DateTime.now(),
                  symptoms: [Symptom.cramps],
                  mood: Mood.happy,
                  sexualActivity: SexualActivity.protected,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showPregnancyTransitionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: OumiColors.oumiRose),
            SizedBox(width: 8),
            Text('Une nouvelle étape ?'),
          ],
        ),
        content: const Text(
            'D\'après vos symptômes et votre cycle, il y a une forte probabilité que vous soyez enceinte. Souhaitez-vous passer au suivi de grossesse ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Pas maintenant', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(cycleStateProvider.notifier).performPregnancyTransition();
              Navigator.pop(ctx);
              context.go('/home/pregnant');
            },
            style: ElevatedButton.styleFrom(backgroundColor: OumiColors.oumiRose),
            child: const Text('Oui, félicitations !'),
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightCard(CycleState state) {
    if (state.record == null) return const SizedBox.shrink();
    return Card(
      color: OumiColors.roseClair,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: OumiColors.bleuSante, size: 20),
                SizedBox(width: 8),
                Text('Insight IA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: OumiColors.noirDoux)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _generateInsight(state.record!),
              style: const TextStyle(color: OumiColors.grisTexte, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  String _generateInsight(CycleRecord record) {
    if (record.ovulationToday) return '❤️ Aujourd’hui est votre jour d’ovulation. Maximum de fertilité !';
    if (record.isFertile) return '🟢 Vous êtes dans votre fenêtre de fertilité. Considérez un test d\'ovulation.';
    if (record.nextPeriodDate != null) {
      final daysUntil = record.nextPeriodDate!.difference(DateTime.now()).inDays;
      if (daysUntil <= 3 && daysUntil >= 0) return '🩸 Vos règles devraient arriver dans $daysUntil jour(s). Préparez-vous.';
    }
    if (record.pregnancyProbability > 0.5) return '🤔 Probabilité de grossesse élevée. Considérez un test de grossesse.';
    return '📅 Suivez votre cycle quotidiennement pour des insights personnalisés.';
  }

  Widget _buildQuickActions() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _quickActionBtn(icon: Icons.calendar_today, label: 'Calendrier', color: OumiColors.bleuSante),
        _quickActionBtn(icon: Icons.favorite, label: 'Fertilité', color: OumiColors.vertSante),
        _quickActionBtn(icon: Icons.medical_services, label: 'Rdv med.', color: OumiColors.oumiRose),
        _quickActionBtn(icon: Icons.notifications, label: 'Rappels', color: OumiColors.orangeAlerte),
      ],
    );
  }

  Widget _quickActionBtn({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // Start from top
      progress * 6.28319, // 2*PI
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}
