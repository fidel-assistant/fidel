import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/premium.dart';
import '../../../core/ui/app_toast.dart';
import '../../../l10n/app_localizations.dart';
import '../application/home_controller.dart';
import '../domain/aidant_models.dart';
import '../domain/constante_models.dart';
import '../domain/dashboard_models.dart';
import 'profile_voix_record_sheet.dart';
import 'widgets/constante_card.dart' show constanteLabel;
import 'widgets/dose_timeline.dart';
import 'widgets/home_skeleton.dart';

class AidantPatientDetailScreen extends ConsumerStatefulWidget {
  const AidantPatientDetailScreen({
    super.key,
    required this.patientId,
    this.patient,
    this.prenomHint,
  });

  final String patientId;
  final AidantPatient? patient;
  final String? prenomHint;

  @override
  ConsumerState<AidantPatientDetailScreen> createState() =>
      _AidantPatientDetailScreenState();
}

class _AidantPatientDetailScreenState
    extends ConsumerState<AidantPatientDetailScreen> {
  AidantPatient? _patient;
  AidantObservance? _today;
  AidantObservance? _observance;
  List<PriseDuJour> _prises = const [];
  List<Constante> _constantes = const [];
  AidantNotificationPrefs _notifPrefs = const AidantNotificationPrefs();
  String? _error;
  bool _loading = true;
  bool _voixBusy = false;
  bool _prefsBusy = false;

  static const _maxVoixBytes = 2 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(homeRepositoryProvider);
      var patient = widget.patient;
      if (patient == null || patient.id != widget.patientId) {
        final list = await repo.listAccompaniedPatients();
        AidantPatient? found;
        for (final item in list) {
          if (item.id == widget.patientId) {
            found = item;
            break;
          }
        }
        patient = found;
      }
      if (patient == null) {
        if (!mounted) return;
        setState(() {
          _patient = null;
          _today = null;
          _observance = null;
          _prises = const [];
          _constantes = const [];
          _loading = false;
          _error = AppLocalizations.of(context).cerclePatientUnavailable;
        });
        return;
      }

      final now = DateTime.now();
      final day = DateTime(now.year, now.month, now.day);
      final canSeeDoses = patient.permissions.observance;
      AidantObservance? today;
      AidantObservance? week;
      List<PriseDuJour> prises = const [];
      if (canSeeDoses) {
        final results = await Future.wait([
          repo.fetchPatientObservance(
            widget.patientId,
            depuis: day,
            jusquA: day,
          ),
          repo.fetchPatientObservance(widget.patientId),
          repo.listAidantPrises(widget.patientId, date: day),
        ]);
        today = results[0] as AidantObservance;
        week = results[1] as AidantObservance;
        prises = results[2] as List<PriseDuJour>;
      }
      final constantes = patient.permissions.constantes
          ? await repo.listAidantConstantes(widget.patientId)
          : const <Constante>[];
      AidantNotificationPrefs prefs = const AidantNotificationPrefs();
      try {
        prefs = await repo.fetchAidantNotificationPrefs(widget.patientId);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _patient = patient;
        _today = today;
        _observance = week;
        _prises = prises;
        _constantes = constantes;
        _notifPrefs = prefs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateFmt = DateFormat.MMMd(locale);
    final patient = _patient;
    final hint = widget.prenomHint?.trim();
    final title = patient?.displayName ??
        widget.patient?.displayName ??
        ((hint != null && hint.isNotEmpty) ? hint : 'Patient');

    return DawnBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(title),
        ),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (_loading)
                const ProfilePageSkeleton(rows: 4)
              else if (_error != null)
                PremiumCard(
                  child: Text(
                    _error!,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: tokens.textSecondary,
                    ),
                  ),
                )
              else if (patient != null) ...[
                _PatientHero(patient: patient),
                const SizedBox(height: 18),
                _SectionLabel(label: l10n.cercleTodaySection),
                const SizedBox(height: 8),
                if (!patient.permissions.observance)
                  PremiumCard(
                    child: Text(
                      l10n.cerclePermissionLocked,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: tokens.textSecondary,
                      ),
                    ),
                  )
                else if (_today != null)
                  PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _MetricTile(
                                value: '${_today!.confirmees}',
                                label: l10n.cercleAdherenceConfirmed,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MetricTile(
                                value: '${_today!.enAttente}',
                                label: l10n.cercleAdherencePending,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MetricTile(
                                value: '${_today!.manquees}',
                                label: l10n.cercleAdherenceMissed,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        DoseTimeline(
                          prises: _prises,
                          now: DateTime.now(),
                          busy: false,
                          readOnly: true,
                          embedded: true,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                _SectionLabel(label: l10n.cercleDetailAdherence),
                const SizedBox(height: 8),
                if (!patient.permissions.observance)
                  PremiumCard(
                    child: Text(
                      l10n.cerclePermissionLocked,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: tokens.textSecondary,
                      ),
                    ),
                  )
                else if (_observance != null)
                  PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.cercleAdherenceWindow(
                            dateFmt.format(_observance!.depuis),
                            dateFmt.format(_observance!.jusquA),
                          ),
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13,
                            color: tokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricTile(
                                value: '${_observance!.percent}%',
                                label: l10n.cercleAdherenceRate,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MetricTile(
                                value: '${_observance!.confirmees}',
                                label: l10n.cercleAdherenceConfirmed,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricTile(
                                value: '${_observance!.manquees}',
                                label: l10n.cercleAdherenceMissed,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MetricTile(
                                value: '${_observance!.enAttente}',
                                label: l10n.cercleAdherencePending,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                _SectionLabel(label: l10n.cercleDetailVitals),
                const SizedBox(height: 8),
                if (!patient.permissions.constantes)
                  PremiumCard(
                    child: Text(
                      l10n.cerclePermissionLocked,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: tokens.textSecondary,
                      ),
                    ),
                  )
                else if (_constantes.isEmpty)
                  PremiumCard(
                    child: Text(
                      l10n.cercleNoVitals,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: tokens.textSecondary,
                      ),
                    ),
                  )
                else
                  PremiumCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < _constantes.length; i++) ...[
                          ListTile(
                            leading: Icon(
                              IconsaxPlusLinear.activity,
                              color: AppColors.primary.withValues(alpha: 0.9),
                            ),
                            title: Text(
                              constanteLabel(l10n, _constantes[i].type),
                            ),
                            subtitle: Text(
                              dateFmt.format(_constantes[i].mesureAt),
                            ),
                            trailing: Text(
                              _formatConstante(_constantes[i]),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontWeight: FontWeight.w700,
                                color: tokens.textPrimary,
                              ),
                            ),
                          ),
                          if (i < _constantes.length - 1)
                            Divider(height: 1, color: tokens.border),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                _SectionLabel(label: l10n.aidantNotifSection),
                const SizedBox(height: 8),
                PremiumCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text(l10n.aidantMutePriseConfirmee),
                        value: _notifPrefs.mutePriseConfirmee,
                        onChanged: _prefsBusy
                            ? null
                            : (v) => _patchPref(mutePriseConfirmee: v),
                      ),
                      Divider(height: 1, color: tokens.border),
                      SwitchListTile(
                        title: Text(l10n.aidantMutePriseNonConfirmee),
                        value: _notifPrefs.mutePriseNonConfirmee,
                        onChanged: _prefsBusy
                            ? null
                            : (v) => _patchPref(mutePriseNonConfirmee: v),
                      ),
                      Divider(height: 1, color: tokens.border),
                      SwitchListTile(
                        title: Text(l10n.aidantMuteSos),
                        subtitle: Text(l10n.aidantMuteSosHint),
                        value: _notifPrefs.muteSos,
                        onChanged: _prefsBusy
                            ? null
                            : (v) => _patchPref(muteSos: v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionLabel(label: l10n.aidantVoixSection),
                const SizedBox(height: 8),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.aidantVoixBody,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13,
                          height: 1.4,
                          color: tokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _voixBusy ? null : _chooseVoixSource,
                        icon: _voixBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(IconsaxPlusLinear.microphone_2),
                        label: Text(l10n.aidantVoixCta),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatConstante(Constante c) {
    if (c.type.isPaired && c.diastolique != null) {
      return '${c.systolique.toInt()}/${c.diastolique!.toInt()} ${c.unite}';
    }
    final digits = c.type.decimals;
    return '${c.systolique.toStringAsFixed(digits)} ${c.unite}';
  }

  Future<void> _patchPref({
    bool? mutePriseConfirmee,
    bool? mutePriseNonConfirmee,
    bool? muteSos,
  }) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _prefsBusy = true);
    try {
      final prefs =
          await ref.read(homeRepositoryProvider).patchAidantNotificationPrefs(
                widget.patientId,
                mutePriseConfirmee: mutePriseConfirmee,
                mutePriseNonConfirmee: mutePriseNonConfirmee,
                muteSos: muteSos,
              );
      if (!mounted) return;
      setState(() => _notifPrefs = prefs);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        e is ApiException ? e.message : l10n.genericError,
      );
    } finally {
      if (mounted) setState(() => _prefsBusy = false);
    }
  }

  Future<void> _chooseVoixSource() async {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: tokens.elevated,
          borderRadius: BorderRadius.circular(Premium.radius),
          border: Border.all(color: tokens.border),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l10n.profileVoixChooseTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  IconsaxPlusLinear.microphone_2,
                  color: AppColors.primary,
                ),
                title: Text(l10n.profileVoixRecord),
                subtitle: Text(l10n.profileVoixRecordHint),
                onTap: () => Navigator.pop(ctx, 'record'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  IconsaxPlusLinear.document_upload,
                  color: AppColors.primary,
                ),
                title: Text(l10n.profileVoixImport),
                subtitle: Text(l10n.profileVoixImportHint),
                onTap: () => Navigator.pop(ctx, 'import'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'record') {
      await _recordVoix();
    } else {
      await _pickVoix();
    }
  }

  Future<void> _recordVoix() async {
    final result = await ProfileVoixRecordSheet.show(context);
    if (result == null || !mounted) return;
    final l10n = AppLocalizations.of(context);
    if (result.bytesLength > _maxVoixBytes) {
      AppToast.error(context, l10n.profileVoixTooLarge);
      return;
    }
    await _uploadVoix(filename: result.filename, filePath: result.path);
  }

  Future<void> _pickVoix() async {
    final l10n = AppLocalizations.of(context);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'm4a', 'aac', 'ogg', 'opus'],
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;

    final file = result.files.single;
    final bytes = file.bytes;
    final path = file.path;
    final name = file.name;

    if ((bytes == null || bytes.isEmpty) && (path == null || path.isEmpty)) {
      AppToast.error(context, l10n.profileVoixPickFailed);
      return;
    }
    final size = bytes?.length ?? file.size;
    if (size > _maxVoixBytes) {
      AppToast.error(context, l10n.profileVoixTooLarge);
      return;
    }
    await _uploadVoix(
      filename: name,
      bytes: bytes,
      filePath: path,
    );
  }

  Future<void> _uploadVoix({
    required String filename,
    List<int>? bytes,
    String? filePath,
  }) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _voixBusy = true);
    try {
      await ref.read(homeRepositoryProvider).uploadAidantVoixRappel(
            patientId: widget.patientId,
            filename: filename,
            bytes: bytes ?? const <int>[],
            filePath: filePath,
          );
      if (!mounted) return;
      AppToast.success(context, l10n.aidantVoixUploaded);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        e is ApiException ? e.message : l10n.genericError,
      );
    } finally {
      if (mounted) setState(() => _voixBusy = false);
    }
  }
}

class _PatientHero extends StatelessWidget {
  const _PatientHero({required this.patient});

  final AidantPatient patient;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);

    return PremiumCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(
                alpha: tokens.isDark ? 0.2 : 0.1,
              ),
            ),
            child: Text(
              patient.initial,
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.displayName,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _visibleAccess(l10n, patient.permissions),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Premium.radiusSm),
        color: tokens.isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF7FAFC),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
        color: tokens.textSecondary,
      ),
    );
  }
}

String _visibleAccess(AppLocalizations l10n, AidantPermissions permissions) {
  if (permissions.observance && permissions.constantes) {
    return l10n.homeAidantsPermBoth;
  }
  if (permissions.observance) return l10n.homeAidantsPermObservanceOnly;
  if (permissions.constantes) return l10n.homeAidantsPermConstantes;
  return l10n.cerclePermissionLimited;
}
