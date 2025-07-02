import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import 'students/student_list_screen.dart';
import 'general/general_invitation_list_screen.dart';
import 'scan/qr_scanner_screen.dart';
import 'location/event_location_screen.dart';
import 'package:share_plus/share_plus.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      context.read<DashboardProvider>().loadStatistics();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Clear focus when app goes to background to prevent keyboard issues
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      FocusManager.instance.primaryFocus?.unfocus();
    }

    // Refresh statistics when app becomes active (returning from other apps)
    if (state == AppLifecycleState.resumed) {
      Future.microtask(() {
        if (mounted) {
          context.read<DashboardProvider>().refreshStatistics();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'share':
                  _shareStatistics();
                  break;
                case 'cleanup':
                  _performDatabaseCleanup();
                  break;
                case 'refresh':
                  context.read<DashboardProvider>().refreshStatistics();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Bagikan Statistik'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'cleanup',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services),
                    SizedBox(width: 8),
                    Text('Bersihkan Database'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Immediately dismiss any keyboards or overlays
              FocusManager.instance.primaryFocus?.unfocus();

              // Close any open dialogs or bottom sheets
              Navigator.of(context).popUntil((route) => route.isFirst);

              // Add a delay to ensure all UI operations complete
              await Future.delayed(const Duration(milliseconds: 200));

              if (!mounted) return;

              try {
                await context.read<AuthProvider>().signOut();
              } catch (e) {
                if (!mounted) return;

                // Use post frame callback to ensure widget is still valid
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Logout gagal: ${e.toString()}'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }
                });
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<DashboardProvider>().refreshStatistics();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Statistik Undangan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Consumer<DashboardProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final stats = provider.statistics;
                  return Column(
                    children: [
                      // Pie Chart Card - Distribution of Invitations
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.pie_chart,
                                        color: Colors.blue[700], size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Distribusi Undangan',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 250,
                                child: Row(
                                  children: [
                                    // Pie Chart
                                    Expanded(
                                      flex: 3,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          PieChart(
                                            PieChartData(
                                              sectionsSpace: 3,
                                              centerSpaceRadius: 50,
                                              startDegreeOffset: 270,
                                              sections:
                                                  _buildPieChartSections(stats),
                                              pieTouchData: PieTouchData(
                                                touchCallback:
                                                    (FlTouchEvent event,
                                                        pieTouchResponse) {
                                                  // Add touch interaction if needed
                                                },
                                              ),
                                            ),
                                          ),
                                          // Center label
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey
                                                      .withOpacity(0.2),
                                                  spreadRadius: 2,
                                                  blurRadius: 5,
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '${stats['total_invitations']}',
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const Text(
                                                  'Total',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Legend
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildEnhancedLegendItem(
                                            'Mahasiswa',
                                            stats['total_students'].toString(),
                                            Colors.blue,
                                            Icons.school,
                                          ),
                                          const SizedBox(height: 16),
                                          _buildEnhancedLegendItem(
                                            'Wali',
                                            stats['total_guardians'].toString(),
                                            Colors.green,
                                            Icons.family_restroom,
                                          ),
                                          const SizedBox(height: 16),
                                          _buildEnhancedLegendItem(
                                            'Umum',
                                            stats['total_general'].toString(),
                                            Colors.orange,
                                            Icons.people,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Attendance Chart Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.purple[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.bar_chart,
                                        color: Colors.purple[700], size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Statistik Kehadiran',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 220,
                                child: BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: stats['total_invitations'].toDouble(),
                                    backgroundColor: Colors.transparent,
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval:
                                          (stats['total_invitations'] / 5)
                                              .toDouble(),
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: Colors.grey[300]!,
                                          strokeWidth: 1,
                                        );
                                      },
                                    ),
                                    barTouchData: BarTouchData(
                                      touchTooltipData: BarTouchTooltipData(
                                        getTooltipColor: (group) => Colors.blueGrey,
                                        tooltipBorder: BorderSide.none,
                                        tooltipBorderRadius: BorderRadius.all(Radius.circular(8)),
                                        getTooltipItem:
                                            (group, groupIndex, rod, rodIndex) {
                                          String label = groupIndex == 0
                                              ? 'Sudah Hadir'
                                              : 'Belum Hadir';
                                          return BarTooltipItem(
                                            '$label\n${rod.toY.round()} orang',
                                            const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            switch (value.toInt()) {
                                              case 0:
                                                return Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.check_circle,
                                                        color: Colors.green,
                                                        size: 16),
                                                    const SizedBox(height: 4),
                                                    const Text('Hadir',
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500)),
                                                  ],
                                                );
                                              case 1:
                                                return Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.pending,
                                                        color: Colors.orange,
                                                        size: 16),
                                                    const SizedBox(height: 4),
                                                    const Text('Belum',
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500)),
                                                  ],
                                                );
                                              default:
                                                return const SizedBox();
                                            }
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                          interval:
                                              (stats['total_invitations'] / 5)
                                                  .toDouble(),
                                          getTitlesWidget: (value, meta) {
                                            return Text(
                                              value.toInt().toString(),
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey),
                                            );
                                          },
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border(
                                        bottom: BorderSide(
                                            color: Colors.grey[300]!, width: 1),
                                        left: BorderSide(
                                            color: Colors.grey[300]!, width: 1),
                                      ),
                                    ),
                                    barGroups: [
                                      BarChartGroupData(
                                        x: 0,
                                        barRods: [
                                          BarChartRodData(
                                            toY: stats['total_checked_in']
                                                .toDouble(),
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.green[300]!,
                                                Colors.green[600]!
                                              ],
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                            ),
                                            width: 50,
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(8),
                                              topRight: Radius.circular(8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      BarChartGroupData(
                                        x: 1,
                                        barRods: [
                                          BarChartRodData(
                                            toY: (stats['total_invitations'] -
                                                    stats['total_checked_in'])
                                                .toDouble(),
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.orange[300]!,
                                                Colors.orange[500]!
                                              ],
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                            ),
                                            width: 50,
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(8),
                                              topRight: Radius.circular(8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Summary Info
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.purple[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          '${stats['check_in_percentage']}%',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.purple[700],
                                          ),
                                        ),
                                        const Text(
                                          'Tingkat Kehadiran',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: Colors.purple[200],
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          '${stats['total_checked_in']}/${stats['total_invitations']}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.purple[700],
                                          ),
                                        ),
                                        const Text(
                                          'Hadir/Total',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Quick Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickStatCard(
                              'Total Undangan',
                              stats['total_invitations'].toString(),
                              Icons.people,
                              Colors.indigo,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickStatCard(
                              'Sudah Hadir',
                              stats['total_checked_in'].toString(),
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text(
                'Menu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildMenuGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuGrid() {
    final menuItems = [
      {
        'title': 'Mahasiswa',
        'icon': Icons.school,
        'color': Colors.blue,
        'screen': const StudentListScreen(),
      },
      {
        'title': 'Undangan Umum',
        'icon': Icons.people,
        'color': Colors.orange,
        'screen': const GeneralInvitationListScreen(),
      },
      {
        'title': 'Scan QR',
        'icon': Icons.qr_code_scanner,
        'color': Colors.green,
        'screen': const QrScannerScreen(),
      },
      {
        'title': 'Lokasi Acara',
        'icon': Icons.location_on,
        'color': Colors.red,
        'screen': const EventLocationScreen(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return InkWell(
          onTap: () async {
            // Navigate to the screen and refresh statistics when returning
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => item['screen'] as Widget),
            );

            // Refresh statistics after returning from any screen
            if (mounted) {
              Future.microtask(() {
                context.read<DashboardProvider>().refreshStatistics();
              });
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: (item['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (item['color'] as Color).withOpacity(0.3),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item['icon'] as IconData,
                  size: 40,
                  color: item['color'] as Color,
                ),
                const SizedBox(height: 8),
                Text(
                  item['title'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: item['color'] as Color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _shareStatistics() {
    final stats = context.read<DashboardProvider>().statistics;
    final message = '''
Statistik Undangan Wisuda

📊 Total Undangan:
• Mahasiswa: ${stats['total_students']}
• Wali: ${stats['total_guardians']}
• Umum: ${stats['total_general']}
• Total: ${stats['total_invitations']}

✅ Kehadiran:
• Sudah Hadir: ${stats['total_checked_in']}
• Persentase: ${stats['check_in_percentage']}%

📅 Tanggal: ${DateTime.now().toString().split(' ')[0]}
    ''';

    Share.share(message, subject: 'Statistik Undangan Wisuda');
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, dynamic> stats) {
    final totalStudents = stats['total_students'] as int;
    final totalGuardians = stats['total_guardians'] as int;
    final totalGeneral = stats['total_general'] as int;
    final total = totalStudents + totalGuardians + totalGeneral;

    if (total == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey[300],
          value: 1,
          title: 'Tidak ada data',
          radius: 60,
          titleStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ];
    }

    return [
      PieChartSectionData(
        color: Colors.blue,
        value: totalStudents.toDouble(),
        title: '${((totalStudents / total) * 100).toInt()}%',
        radius: 70,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: totalStudents > 0
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(Icons.school, color: Colors.blue, size: 16),
              )
            : null,
        badgePositionPercentageOffset: 1.3,
      ),
      PieChartSectionData(
        color: Colors.green,
        value: totalGuardians.toDouble(),
        title: '${((totalGuardians / total) * 100).toInt()}%',
        radius: 70,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: totalGuardians > 0
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child:
                    Icon(Icons.family_restroom, color: Colors.green, size: 16),
              )
            : null,
        badgePositionPercentageOffset: 1.3,
      ),
      PieChartSectionData(
        color: Colors.orange,
        value: totalGeneral.toDouble(),
        title: '${((totalGeneral / total) * 100).toInt()}%',
        radius: 70,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: totalGeneral > 0
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(Icons.people, color: Colors.orange, size: 16),
              )
            : null,
        badgePositionPercentageOffset: 1.3,
      ),
    ];
  }

  Widget _buildEnhancedLegendItem(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: color.withOpacity(0.8),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _performDatabaseCleanup() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text(
          'Apakah Anda yakin ingin membersihkan database?\n\n'
          'Proses ini akan menghapus data undangan yang tidak valid dan memperbaiki inkonsistensi data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya, Bersihkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Membersihkan database...'),
          ],
        ),
      ),
    );

    try {
      await context.read<DashboardProvider>().manualDatabaseCleanup();

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Database berhasil dibersihkan!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membersihkan database: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
