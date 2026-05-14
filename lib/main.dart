import 'package:flutter/material.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '无名之辈',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueGrey[800],
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final List<Widget> _pages = const [
    SignalListPage(),
    UserAnalysisPage(),
    StockManagePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.black,
        selectedItemColor: Colors.cyan,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bolt), label: '脉冲信号'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: '自选分析'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: '我的自选'),
        ],
      ),
    );
  }
}

class SignalListPage extends StatefulWidget {
  const SignalListPage({super.key});

  @override
  _SignalListPageState createState() => _SignalListPageState();
}

class _SignalListPageState extends State<SignalListPage> {
  List<Map<String, dynamic>> _filteredSignals = [];
  String _filterType = 'all';
  bool _showOnlyToday = true;
  String _moodReport = "今日市场情绪稳定，适合短线操作";

  List<Map<String, dynamic>> localMockData = [
    {"code": "000001", "name": "平安银行", "chg": "2.55", "event": "资金信号", "time": "09:32:10", "mn_wan": "1200", "total_6s_wan": "3500", "cap": "2800"},
    {"code": "600000", "name": "浦发银行", "chg": "1.82", "event": "强势异动", "time": "09:35:22", "mn_wan": "850", "total_6s_wan": "2200", "cap": "1900"},
    {"code": "000002", "name": "万科A", "chg": "-0.33", "event": "超强异动", "time": "09:38:05", "mn_wan": "2100", "total_6s_wan": "5200", "cap": "2100"},
    {"code": "600036", "name": "招商银行", "chg": "3.11", "event": "尾盘异动", "time": "09:40:15", "mn_wan": "1800", "total_6s_wan": "4900", "cap": "7600"},
  ];

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  void _loadLocalData() {
    setState(() {
      _filteredSignals = List.from(localMockData);
    });
  }

  void _applyFilter() {
    setState(() {
      if (_filterType == 'all') {
        _filteredSignals = List.from(localMockData);
      } else if (_filterType == 'pulse') {
        _filteredSignals = localMockData.where((s) => s['event']!.contains('信号')).toList();
      } else {
        _filteredSignals = localMockData.where((s) => s['event']!.contains('异动')).toList();
      }
    });
  }

  Map<String, dynamic> _getStats() {
    if (localMockData.isEmpty) return {'count': 0, 'max_chg': 0, 'win_rate': 0};
    double maxChg = 0;
    int winCount = 0;
    for (var s in localMockData) {
      double chg = double.tryParse(s['chg'].toString()) ?? 0;
      if (chg > maxChg) maxChg = chg;
      if (chg > 0) winCount++;
    }
    return {
      'count': localMockData.length,
      'max_chg': maxChg,
      'win_rate': winCount / localMockData.length * 100,
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _getStats();
    return Scaffold(
      appBar: AppBar(
        title: const Text('资金脉冲', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          Switch(
            value: _showOnlyToday,
            onChanged: (value) {
              setState(() {
                _showOnlyToday = value;
              });
            },
            activeColor: Colors.cyan,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLocalData,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueGrey[900]!, Colors.black],
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(icon: Icons.bolt, value: stats['count'].toString(), label: '信号总数'),
                _StatItem(icon: Icons.trending_up, value: stats['max_chg'].toStringAsFixed(1) + '%', label: '最大涨幅'),
                _StatItem(icon: Icons.insights, value: stats['win_rate'].toStringAsFixed(0) + '%', label: '胜率'),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueGrey[800],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyan, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.cyan, size: 18),
                    SizedBox(width: 6),
                    Text('今日开盘情绪', style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _moodReport,
                  style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.4),
                  softWrap: true,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: '全部',
                  isSelected: _filterType == 'all',
                  onTap: () => setState(() {
                    _filterType = 'all';
                    _applyFilter();
                  }),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: '资金信号',
                  isSelected: _filterType == 'pulse',
                  onTap: () => setState(() {
                    _filterType = 'pulse';
                    _applyFilter();
                  }),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: '异动信号',
                  isSelected: _filterType == 'super',
                  onTap: () => setState(() {
                    _filterType = 'super';
                    _applyFilter();
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredSignals.isEmpty
                ? const Center(child: Text('暂无信号', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: _filteredSignals.length,
                    itemBuilder: (context, i) {
                      final s = _filteredSignals[i];
                      return _SignalCard(signal: s);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.cyan, size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyan : Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SignalCard extends StatelessWidget {
  final Map<String, dynamic> signal;
  const _SignalCard({required this.signal});

  @override
  Widget build(BuildContext context) {
    double chg = double.tryParse(signal['chg'].toString()) ?? 0;
    Color chgColor = chg >= 0 ? Colors.redAccent : Colors.green;
    IconData trendIcon = chg >= 0 ? Icons.trending_up : Icons.trending_down;
    String eventType = signal['event'] ?? '';
    Color eventColor = eventType.contains('超强')
        ? Colors.deepPurple
        : (eventType.contains('强势') ? Colors.orange : (eventType.contains('尾盘') ? Colors.purple : Colors.blue));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetailDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: eventColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      eventType,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${signal['time']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const Spacer(),
                  Icon(trendIcon, color: chgColor, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${chg.toStringAsFixed(2)}%',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: chgColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('${signal['name']}(${signal['code']})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.speed, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('2s: ${signal['mn_wan']}万', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(width: 12),
                  const Icon(Icons.timer, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('6s: ${signal['total_6s_wan']}万', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const Spacer(),
                  Text('${signal['cap']}亿', style: const TextStyle(fontSize: 12, color: Colors.cyan)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('信号详情'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('股票：${signal['name']}(${signal['code']})'),
            const SizedBox(height: 8),
            Text('时间：${signal['time']}'),
            Text('事件：${signal['event']}'),
            Text('市值：${signal['cap']} 亿'),
            Text('涨幅：${signal['chg']}%'),
            Text('2秒净流入：${signal['mn_wan']} 万'),
            Text('6秒净流入：${signal['total_6s_wan']} 万'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

class UserAnalysisPage extends StatelessWidget {
  const UserAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("自选分析"), backgroundColor: Colors.black),
      body: const Center(child: Text("自选分析页面（本地离线版）", style: TextStyle(color: Colors.white))),
    );
  }
}

class StockManagePage extends StatelessWidget {
  const StockManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("我的自选"), backgroundColor: Colors.black),
      body: const Center(child: Text("我的自选页面（本地离线版）", style: TextStyle(color: Colors.white))),
    );
  }
}