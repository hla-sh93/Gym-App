import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/localization/app_localizations.dart';
import '../../../app/theme.dart';
import '../../common/presentation/common_widgets.dart';
import '../../workout/domain/models.dart';

/// Monthly training report: every completed workout in the chosen month with
/// its exercises, weights, and reps.
class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  Future<List<SessionReport>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<List<SessionReport>> _load() {
    final start = _month;
    final end = DateTime(_month.year, _month.month + 1);
    return GymScope.of(context).repository.sessionsBetween(start, end);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _future = _load();
    });
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.t('monthlyReport')),
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: NotebookCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          tooltip: context.l10n.t('moveDown'),
                          onPressed: () => _shiftMonth(-1),
                          icon: Icon(
                            Directionality.of(context) == TextDirection.rtl
                                ? Icons.chevron_right
                                : Icons.chevron_left,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            context.l10n.month(_month),
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          tooltip: context.l10n.t('moveUp'),
                          onPressed: _isCurrentMonth
                              ? null
                              : () => _shiftMonth(1),
                          icon: Icon(
                            Directionality.of(context) == TextDirection.rtl
                                ? Icons.chevron_left
                                : Icons.chevron_right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<SessionReport>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      final reports =
                          snapshot.data ?? const <SessionReport>[];
                      if (reports.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: EmptyState(
                            message: context.l10n.t('noWorkoutsThisMonth'),
                            icon: Icons.calendar_month_outlined,
                          ),
                        );
                      }
                      final totalSets = reports.fold<int>(
                        0,
                        (sum, r) => sum + r.completedSetCount,
                      );
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: InlineStat(
                                  label: context.l10n.t('workoutsCount'),
                                  value: reports.length.toString(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InlineStat(
                                  label: context.l10n.t('completedSets'),
                                  value: totalSets.toString(),
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          for (final report in reports)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _SessionReportCard(report: report),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionReportCard extends StatelessWidget {
  const _SessionReportCard({required this.report});

  final SessionReport report;

  @override
  Widget build(BuildContext context) {
    return NotebookCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const IconBadge(icon: Icons.event_available, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      report.dayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      context.l10n.date(report.session.sessionDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                '${report.completedSetCount} ${context.l10n.t('set')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final exercise in report.exercises) ...<Widget>[
            Text(
              exercise.exercise.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 2),
            for (final set in exercise.sets)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 8, bottom: 2),
                child: Text(
                  formatSetLine(context, set, exercise.exercise.type),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}
