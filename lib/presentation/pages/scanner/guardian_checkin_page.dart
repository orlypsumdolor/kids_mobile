import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../providers/checkin_provider.dart';
import '../../providers/services_provider.dart';
import '../../widgets/child_selection_card.dart';
import '../../widgets/service_selector.dart';
import '../../widgets/app_shell_header.dart';
import '../../widgets/inline_error_banner.dart';
import '../../widgets/motion.dart';
import '../../../domain/entities/guardian.dart';
import '../../../domain/entities/child.dart';
import '../../../domain/entities/attendance_record.dart';
import '../../../domain/entities/service_session.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/printer_service.dart';
import '../../../core/services/hardware_scanner_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/guardian_model.dart';
import '../../../data/models/child_model.dart';

class GuardianCheckinPage extends StatefulWidget {
  const GuardianCheckinPage({super.key});

  @override
  State<GuardianCheckinPage> createState() => _GuardianCheckinPageState();
}

class _GuardianCheckinPageState extends State<GuardianCheckinPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  Guardian? _scannedGuardian;
  List<Child> _linkedChildren = [];
  List<String> _selectedChildIds = [];
  bool _isLoading = false;
  bool _isScanning = false;
  bool _isPrinting = false;
  bool _showSuccess = false;
  List<AttendanceRecord> _checkInResults = [];
  String? _error;
  String? _selectedServiceId;
  Timer? _connectionCheckTimer;
  Timer? _resetTimer;
  int _resetInSeconds = 0;

  // Hardware barcode scanner (M7710) support
  late final FocusNode _scannerFocusNode;
  StreamSubscription<String>? _scannerSubscription;
  final bool _hwScannerActive = true;

  // Idle-scan sweep-line animation
  late final AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadServices());
    WidgetsBinding.instance.addObserver(this);

    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _scannerFocusNode = FocusNode(debugLabel: 'hardwareScanner');

    // Listen for barcodes from the M7710 hardware scanner
    final scannerService = context.read<HardwareScannerService>();
    _scannerSubscription = scannerService.onBarcodeScanned.listen((barcode) {
      if (mounted && !_isLoading && _scannedGuardian == null) {
        print('📡 Hardware scanner input received: "$barcode"');
        _processGuardianQR(barcode);
      }
    });

    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _checkPrinterConnection();
      }
    });
  }

  @override
  void dispose() {
    _connectionCheckTimer?.cancel();
    _resetTimer?.cancel();
    _scannerSubscription?.cancel();
    _scannerFocusNode.dispose();
    _sweepController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check printer connection status when dependencies change (e.g., when navigating back)
    _checkPrinterConnection();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When the app becomes visible again, check printer connection
    if (state == AppLifecycleState.resumed) {
      print('🔄 App resumed - checking printer connection status');
      _checkPrinterConnection();
    }
  }

  Future<void> _loadServices() async {
    try {
      await context.read<ServicesProvider>().loadServices();
    } catch (e) {
      _setError('Failed to load services: $e');
    }
  }

  /// Check printer connection status and update UI accordingly
  void _checkPrinterConnection() async {
    try {
      final printerService = context.read<PrinterService>();
      if (printerService.isConnected &&
          printerService.connectedDevice != null) {
        print('🔍 Checking printer connection status...');
        print('📱 Connected device: ${printerService.connectedDevice!.name}');
        print('🔗 Connection status: ${printerService.isConnected}');
        setState(() {});
      } else {
        print('🔍 No printer currently connected');
        setState(() {});
      }
    } catch (e) {
      print('⚠️ Error checking printer connection: $e');
      setState(() {});
    }
  }

  Future<void> _reconnectPrinter() async {
    final printerService = context.read<PrinterService>();
    final connected = await printerService.reconnect();
    if (mounted) setState(() {});
    if (!connected && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not reconnect to the last printer.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _scanGuardianQR() async {
    setState(() {
      _isScanning = true;
      _error = null;
    });

    try {
      final result = await context.push<String>(
        AppRouter.qrScanner,
        extra: {
          'title': 'Scan Guardian QR Code',
          'onScanComplete': (String qrCode) async {
            await _processGuardianQR(qrCode);
          },
        },
      );

      if (result != null) {
        await _processGuardianQR(result);
      }
    } catch (e) {
      _setError('QR scanning failed: $e');
    } finally {
      setState(() {
        _isScanning = false;
      });
      // Re-grab focus for hardware scanner after camera scan finishes
      _scannerFocusNode.requestFocus();
    }
  }

  Future<void> _processGuardianQR(String qrCode) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final checkinProvider = context.read<CheckinProvider>();

      // Check if QR code is a MongoDB ObjectId (guardian _id)
      if (qrCode.length == 24 && RegExp(r'^[a-fA-F0-9]+$').hasMatch(qrCode)) {
        final guardian = await checkinProvider.getGuardianById(qrCode);
        if (guardian != null) {
          await _fetchGuardianWithChildren(qrCode);
        } else {
          _setError('Guardian not found with this ID');
        }
      } else {
        final guardian = await checkinProvider.getGuardianByQrCode(qrCode);
        if (guardian != null) {
          await _fetchGuardianWithChildren(guardian.id);
        } else {
          _setError('Guardian not found with this QR code');
        }
      }
    } catch (e) {
      print('💥 Error processing guardian QR code: $e');
      _setError('Failed to process guardian QR code: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchGuardianWithChildren(String guardianId) async {
    try {
      final checkinProvider = context.read<CheckinProvider>();
      final result = await checkinProvider.getGuardianWithChildren(guardianId);

      if (result != null) {
        try {
          final guardianData = result['guardian'] as Map<String, dynamic>;
          final guardianModel = GuardianModel.fromJson(guardianData);
          final guardian = guardianModel.toEntity();

          final childrenData = result['children'] as List<dynamic>;
          final children = childrenData.map((childJson) {
            final childModel =
                ChildModel.fromJson(childJson as Map<String, dynamic>);
            return childModel.toEntity();
          }).toList();

          setState(() {
            _scannedGuardian = guardian;
            _linkedChildren = children;
            _selectedChildIds = [];
            _error = null;
          });
        } catch (parseError) {
          print('💥 Error parsing guardian/children data: $parseError');
          _setError('Failed to parse guardian information: $parseError');
        }
      } else {
        _setError('Failed to fetch guardian information');
      }
    } catch (e) {
      _setError('Failed to fetch guardian information: $e');
    }
  }

  void _toggleChildSelection(String childId) {
    setState(() {
      if (_selectedChildIds.contains(childId)) {
        _selectedChildIds.remove(childId);
      } else {
        _selectedChildIds.add(childId);
      }
    });
  }

  void _toggleSelectAll() {
    final selectableIds = _linkedChildren
        .where((c) => !c.currentlyCheckedIn)
        .map((c) => c.id)
        .toList();
    setState(() {
      _selectedChildIds =
          _selectedChildIds.length == selectableIds.length ? [] : selectableIds;
    });
  }

  Future<void> _checkInSelectedChildren() async {
    if (_selectedChildIds.isEmpty) {
      _setError('Please select at least one child to check in');
      return;
    }

    if (_selectedServiceId == null) {
      _setError('Please select a service');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final checkinProvider = context.read<CheckinProvider>();
      final attendanceRecords = await checkinProvider.checkInChildren(
        guardianId: _scannedGuardian!.id,
        serviceId: _selectedServiceId!,
        childIds: _selectedChildIds,
      );

      setState(() {
        _checkInResults = attendanceRecords;
        _selectedChildIds = [];
      });

      await _printStickers(attendanceRecords);

      if (mounted) {
        setState(() => _showSuccess = true);
        _startResetCountdown(5);
      }
    } catch (e) {
      final msg = e.toString().replaceAll(RegExp(r'^Exception:\s*'), '');
      _setError(msg);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _printStickers(List<AttendanceRecord> records) async {
    setState(() {
      _isPrinting = true;
    });

    try {
      final printerService = context.read<PrinterService>();

      if (!printerService.isConnected) {
        final connected = await printerService.reconnect();
        if (!connected) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Failed to reconnect to printer. Please check printer connection in Settings.'),
                backgroundColor: AppTheme.warningTextStrong,
                duration: Duration(seconds: 5),
              ),
            );
          }
          return;
        }
      }

      final servicesProvider = context.read<ServicesProvider>();
      final service = servicesProvider.services.firstWhere(
        (s) => s.id == records.first.serviceId,
        orElse: () => ServiceSession(
          id: records.first.serviceId,
          name: 'Unknown Service',
          startTime: '00:00',
          endTime: '00:00',
          dayOfWeek: 'unknown',
          description: '',
          ageGroups: const [],
          maxCapacity: 0,
          isActive: true,
          createdBy: 'system',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final matchedChildren =
          records.map((record) => _matchChild(record.childId)).toList();
      final childrenNames = matchedChildren.map((c) => c.fullName).toList();
      final ageGroups = matchedChildren.map((c) => c.ageGroup).toList();
      final specialNotes = matchedChildren.map((c) => c.combinedNotes).toList();
      final pickupCodes = records.map((record) => record.pickupCode).toList();
      final childIds = records.map((record) => record.childId).toList();

      final success = await printerService.printGuardianCheckInSticker(
        childIds: childIds,
        children: childrenNames,
        pickupCodes: pickupCodes,
        ageGroups: ageGroups,
        specialNotes: specialNotes,
        guardianQrCode: _scannedGuardian?.id ?? 'Unknown',
        guardianName: _scannedGuardian?.fullName ?? 'Guardian',
        serviceName: service.name,
        checkInTime: records.first.checkInTime,
      );

      if (!success) {
        print('❌ Failed to print sticker');
      }
    } catch (e) {
      print('💥 Error printing sticker: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Sticker printing failed: $e'),
            backgroundColor: AppTheme.warningTextStrong,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isPrinting = false;
      });
    }
  }

  Child _matchChild(String childId) {
    return _linkedChildren.firstWhere(
      (c) => c.id == childId,
      orElse: () => Child(
        id: childId,
        fullName: 'Unknown Child',
        dateOfBirth: DateTime.now(),
        gender: 'unknown',
        ageGroup: 'unknown',
        guardianIds: const [],
        isActive: true,
        currentlyCheckedIn: false,
      ),
    );
  }

  void _startResetCountdown(int seconds) {
    _resetTimer?.cancel();
    setState(() => _resetInSeconds = seconds);
    _resetTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final next = _resetInSeconds - 1;
      if (next <= 0) {
        timer.cancel();
        _resetForm();
      } else {
        setState(() => _resetInSeconds = next);
      }
    });
  }

  void _setError(String error) {
    setState(() {
      _error = error;
      _showSuccess = false;
    });
  }

  void _clearError() {
    setState(() {
      _error = null;
    });
  }

  void _resetForm() {
    _resetTimer?.cancel();
    setState(() {
      _scannedGuardian = null;
      _linkedChildren = [];
      _selectedChildIds = [];
      _selectedServiceId = null;
      _checkInResults = [];
      _showSuccess = false;
      _error = null;
    });
    // Re-grab focus so the hardware scanner keeps receiving input
    _scannerFocusNode.requestFocus();
  }

  /// Route key events from the focus node to the hardware scanner service.
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final scannerService = context.read<HardwareScannerService>();
    return scannerService.handleKeyEvent(event);
  }

  @override
  Widget build(BuildContext context) {
    final printerConnected = context.watch<PrinterService>().isConnected;

    return Focus(
      focusNode: _scannerFocusNode,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: GestureDetector(
        onTap: () => _scannerFocusNode.requestFocus(),
        child: Scaffold(
          backgroundColor: AppTheme.pageBackground,
          body: Column(
            children: [
              AppShellHeader(
                title: 'Check In',
                subtitle: _scannedGuardian?.fullName ?? 'Guardian badge',
                showBackButton: true,
                onBack: () => context.pop(),
                onSettings: () => context.push(AppRouter.settings),
                printerConnected: printerConnected,
              ),
              Expanded(child: _buildBody(printerConnected)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool printerConnected) {
    if (_isLoading && _scannedGuardian == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_scannedGuardian == null) {
      if (!printerConnected) return _buildPrinterGate();
      return _buildIdleScan();
    }

    if (_isPrinting) return _buildPrintingState();
    if (_showSuccess) return _buildSuccessState();

    return _buildGuardianLoaded();
  }

  Widget _buildPrinterGate() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppTheme.warningBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.warningBorder, width: 2),
              ),
              child: const Center(
                child: Icon(Icons.print_disabled,
                    size: 36, color: AppTheme.warningTextStrong),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No printer connected',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Every check-in must print a name tag and a pickup slip. Pair the station printer to continue.',
              style: TextStyle(
                  fontSize: 14.5, color: AppTheme.textTertiary, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => context.push(AppRouter.settings),
                  child: const Text('Open printer settings'),
                ),
                OutlinedButton(
                  onPressed: _reconnectPrinter,
                  child: const Text('Try last printer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdleScan() {
    return Stack(
      children: [
        const Positioned(
          left: 20,
          bottom: 24,
          child: HardwarePointer(label: 'Scanner', color: AppTheme.magenta),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  constraints:
                      const BoxConstraints(maxWidth: 420, minHeight: 320),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    border:
                        Border.all(color: const Color(0xFFB9C6DC), width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.hardEdge,
                    children: [
                      AnimatedBuilder(
                        animation: _sweepController,
                        builder: (context, child) {
                          return Align(
                            alignment: Alignment(
                                0, _sweepController.value * 1.8 - 0.9),
                            child: Container(
                              height: 3,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.magenta.withValues(alpha: 0),
                                    AppTheme.magenta,
                                    AppTheme.magenta.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ScanPulse(
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                color: AppTheme.textPrimary,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: Icon(Icons.qr_code,
                                    color: Colors.white, size: 44),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Scan guardian QR',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _hwScannerActive
                                ? 'Hold the badge under the scanner'
                                : 'Hardware scanner is inactive',
                            style: const TextStyle(
                                fontSize: 13.5, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _isScanning ? null : _scanGuardianQR,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Use camera instead'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 20),
                  InlineErrorBanner(message: _error!, onDismiss: _clearError),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrintingState() {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                    strokeWidth: 4, color: AppTheme.navy),
              ),
              const SizedBox(height: 24),
              Text(
                'Printing ${_checkInResults.length} name '
                '${_checkInResults.length == 1 ? 'tag' : 'tags'} + slip',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const Positioned(
          right: 20,
          bottom: 24,
          child: HardwarePointer(label: 'Printer', color: AppTheme.navy),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Container(
      color: AppTheme.successBg,
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: RiseIn(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: const BoxDecoration(
                            color: AppTheme.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Checked in',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Hand the pickup slip to ${_scannedGuardian?.fullName ?? 'the guardian'}',
                          style: const TextStyle(
                              fontSize: 14.5, color: AppTheme.successText),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            children: _checkInResults.map((record) {
                              final child = _matchChild(record.childId);
                              final badge =
                                  AppTheme.ageGroupBadge(child.ageGroup);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusButton),
                                  border:
                                      Border.all(color: AppTheme.successBorder),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: badge.fg,
                                        borderRadius: BorderRadius.circular(
                                            AppTheme.radiusPill),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        child.fullName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(record.pickupCode,
                                        style: AppTheme.mono(fontSize: 15)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  border:
                      Border(top: BorderSide(color: AppTheme.successBorder)),
                ),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => _printStickers(_checkInResults),
                      child: const Text('Reprint'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _resetForm,
                        child: Text('Next family · ${_resetInSeconds}s'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Positioned(
            right: 20,
            bottom: 96,
            child: HardwarePointer(
                label: 'Tags + slip here', color: AppTheme.navy),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardianLoaded() {
    final selectableCount =
        _linkedChildren.where((c) => !c.currentlyCheckedIn).length;
    final nSel = _selectedChildIds.length;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: RiseIn(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusCardLarge),
                      border: Border.all(color: AppTheme.hairline),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppTheme.navy,
                          child: Text(
                            _scannedGuardian!.firstName.isNotEmpty
                                ? _scannedGuardian!.firstName[0] +
                                    (_scannedGuardian!.lastName.isNotEmpty
                                        ? _scannedGuardian!.lastName[0]
                                        : '')
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _scannedGuardian!.fullName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              Text(
                                '${_scannedGuardian!.relationship} · ${_scannedGuardian!.contactNumber}',
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.pageBackground,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusPill),
                          ),
                          child: Text(
                            _scannedGuardian!.guardianId,
                            style: AppTheme.mono(
                                fontSize: 12.5, color: AppTheme.textTertiary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ServiceSelector(
                    selectedServiceId: _selectedServiceId,
                    onServiceSelected: (value) {
                      setState(() => _selectedServiceId = value);
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'CHILDREN',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (selectableCount > 0)
                        TextButton(
                          onPressed: _toggleSelectAll,
                          child: Text(
                            nSel == selectableCount
                                ? 'Clear all'
                                : 'Select all',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_linkedChildren.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No children linked to this guardian',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textSecondary),
                      ),
                    )
                  else
                    ..._linkedChildren.map((child) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ChildSelectionCard(
                            child: child,
                            isSelected: _selectedChildIds.contains(child.id),
                            onSelectionChanged: () =>
                                _toggleChildSelection(child.id),
                          ),
                        )),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    InlineErrorBanner(message: _error!, onDismiss: _clearError),
                  ],
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(top: BorderSide(color: AppTheme.hairline)),
          ),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: _resetForm,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: nSel > 0 && _selectedServiceId != null
                      ? _checkInSelectedChildren
                      : null,
                  child: Text(
                    nSel > 0
                        ? 'Check in $nSel ${nSel > 1 ? 'children' : 'child'}'
                        : 'Select a child',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
