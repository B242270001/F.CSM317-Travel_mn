// lib/screens/premium_screen.dart
import 'package:flutter/material.dart';

import '../state/subscription.dart';
import '../widgets/premium_gate.dart';

/// «Premium»: төлбөртэй захиалга. Багц, төлбөрийн хэрэгсэл сонгож төлнө;
/// идэвхтэй бол хугацаа, цуцлах товч харагдана.
///
/// Анхаар: сургалтын хувилбарт төлбөрийг дуурайлгасан — бодит мөнгө
/// шилжихгүй.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  PremiumPlan _plan = PremiumPlan.yearly;
  PaymentMethod _method = PaymentMethod.qpay;
  bool _paying = false;

  static const _benefits = [
    (Icons.route, 'Бүх Premium маршрут', 'Говь, Хөвсгөлийн бэлэн маршрутууд'),
    (
      Icons.download_for_offline,
      'Хязгааргүй офлайн газрын зураг',
      'Үнэгүйд $freeOfflineRegions бүс',
    ),
    (
      Icons.edit_location_alt,
      'Хязгааргүй замын тэмдэглэгээ',
      'Үнэгүйд маршрут бүрт $freeRoadMarksPerRoute',
    ),
    (
      Icons.support_agent,
      'Аяллын тусламж 24/7',
      'Замд гарсан асуудалд зөвлөгөө',
    ),
  ];

  Future<void> _pay() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Төлбөр баталгаажуулах'),
        content: Text(
          '${_plan.label} багц · ${formatPrice(_plan.price)}\n'
          'Төлбөрийн хэрэгсэл: ${_method.label}\n\n'
          'Сургалтын хувилбар: бодит төлбөр хийгдэхгүй.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Болих'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Төлөх'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _paying = true);
    await subscription.purchase(_plan, _method);
    if (!mounted) return;
    setState(() => _paying = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Premium амжилттай идэвхжлээ!')),
    );
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Захиалга цуцлах уу?'),
        content: const Text('Premium боломжууд шууд хаагдана.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Үгүй'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Цуцлах'),
          ),
        ],
      ),
    );
    if (ok == true) await subscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: ListenableBuilder(
        listenable: subscription,
        builder: (context, _) {
          final premium = subscription.isPremium;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF26323F), Color(0xFF00695C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PremiumBadge(),
                    const SizedBox(height: 10),
                    Text(
                      premium
                          ? 'Та Premium хэрэглэгч'
                          : 'Аяллаа бүрэн боломжоор',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      premium
                          ? '${subscription.plan?.label ?? ''} багц · '
                                '${_date(subscription.expires!)} хүртэл '
                                '(${subscription.daysLeft} өдөр үлдсэн)'
                          : 'Бүх маршрут, офлайн газрын зураг, замын '
                                'тэмдэглэгээг хязгааргүй ашигла.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (final (icon, title, subtitle) in _benefits)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: colors.primaryContainer,
                    child: Icon(icon, color: colors.onPrimaryContainer),
                  ),
                  title: Text(title),
                  subtitle: Text(subtitle),
                  trailing: Icon(
                    premium ? Icons.check_circle : Icons.lock_outline,
                    color: premium ? colors.primary : colors.outline,
                  ),
                ),
              const Divider(height: 28),
              Text(
                premium ? 'Хугацаа сунгах' : 'Багц сонгох',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final p in PremiumPlan.values)
                    Expanded(
                      child: _PlanCard(
                        plan: p,
                        selected: _plan == p,
                        onTap: () => setState(() => _plan = p),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text('Төлбөрийн хэрэгсэл', style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (final m in PaymentMethod.values)
                    ChoiceChip(
                      label: Text(m.label),
                      selected: _method == m,
                      onSelected: (_) => setState(() => _method = m),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _paying ? null : _pay,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: _paying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_open),
                label: Text(
                  _paying
                      ? 'Төлбөр шалгаж байна...'
                      : '${formatPrice(_plan.price)} төлөх',
                ),
              ),
              if (premium) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _paying ? null : _cancel,
                  style: TextButton.styleFrom(foregroundColor: colors.error),
                  child: const Text('Захиалга цуцлах'),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Сургалтын хувилбар: төлбөрийг дуурайлгасан бөгөөд бодит '
                'мөнгө шилжихгүй.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _date(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.'
      '${d.day.toString().padLeft(2, '0')}';
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final PremiumPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final saving = plan == PremiumPlan.yearly
        ? 100 - (plan.perMonth * 100 ~/ PremiumPlan.monthly.price)
        : 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(plan.label, style: theme.textTheme.titleSmall),
                  const Spacer(),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 20,
                    color: selected ? colors.primary : colors.outline,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                formatPrice(plan.price),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                plan == PremiumPlan.monthly
                    ? '30 хоног'
                    : 'Сард ${formatPrice(plan.perMonth)}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              if (saving > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.tertiaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$saving% хэмнэлт',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onTertiaryContainer,
                    ),
                  ),
                )
              else
                const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
