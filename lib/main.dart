import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'stock_manage_page.dart';
import 'user_analysis_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fauonauftypzhommweep.supabase.co',
    anonKey: 'sb_publishable_Khy15_H_VMH7YDi3R8twoQ_hNjHn8e9',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '无名之辈',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueGrey[800],
        scaffoldBackgroundColor: Colors.black,
      ),
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      return MainPage();
    } else {
      return LoginPage();
    }
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
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

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String _error = '';

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } catch (e) {
      setState(() => _error = "登录失败：${e.toString()}");
    }
    setState(() => _loading = false);
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = "请输入邮箱和密码";
      });
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        setState(() {
          _error = "✅ 注册成功！请登录";
        });
      }
    } catch (e) {
      setState(() {
        _error = "❌ 注册失败：${e.toString()}";
      });
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blueGrey[900]!, Colors.black],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('无名之辈', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text('资金脉冲实时监控', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    SizedBox(height: 30),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: '邮箱',
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: '密码',
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                    SizedBox(height: 24),
                    if (_error.isNotEmpty)
                      Text(
                        _error,
                        style: TextStyle(color: Colors.red, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    if (_loading)
                      CircularProgressIndicator(),
                    if (!_loading)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: _signIn,
                            child: Text('登录'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                            ),
                          ),
                          OutlinedButton(
                            onPressed: _signUp,
                            child: Text('注册'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SignalListPage extends StatefulWidget {
  @override
  _SignalListPageState createState() => _SignalListPageState();
}

class _SignalListPageState extends State<SignalListPage> {
  List<Map<String, dynamic>> _signals = [];
  List<Map<String, dynamic>> _filteredSignals = [];
  String _filterType = 'all';
  bool _loading = true;
  bool _showOnlyToday = true;
  String _moodReport = '';
  bool _loadingMood = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _subscribeRealtime();
    _fetchMoodReport();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _loading = true);
    try {
      var query = Supabase.instance.client.from('signals').select();
      if (_showOnlyToday) {
        final today = DateTime.now().toIso8601String().split('T')[0];
        query = query.gte('created_at', today);
      }
      final response = await query.order('created_at', ascending: false).limit(500);
      setState(() {
        _signals = List<Map<String, dynamic>>.from(response);
      });
      _applyFilter();
      setState(() => _loading = false);
    } catch (e) {
      print("数据获取失败: $e");
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchMoodReport() async {
    setState(() => _loadingMood = true);
    try {
      final response = await Supabase.instance.client
          .from('signals')
          .select()
          .eq('event', '开盘情绪洞察')
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        setState(() {
          _moodReport = response[0]['name'] ?? '';
        });
      }
    } catch (e) {
      print("获取情绪报告失败: $e");
    }
    setState(() => _loadingMood = false);
  }

  void _subscribeRealtime() {
    Supabase.instance.client
        .channel('public:signals')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'signals',
          callback: (payload) {
            final newSignal = payload.newRecord as Map<String, dynamic>;
            setState(() {
              _signals.insert(0, newSignal);
              _applyFilter();
            });
          },
        )
        .subscribe();
  }

  void _applyFilter() {
    if (_filterType == 'all') {
      _filteredSignals = List.from(_signals);
    } else if (_filterType == 'pulse') {
      _filteredSignals = _signals.where((s) => s['event'] != null && s['event'].contains('资金信号')).toList();
    } else {
      _filteredSignals = _signals.where((s) => s['event'] != null && (s['event'].contains('超强异动') || s['event'].contains('强势异动') || s['event'].contains('尾盘异动'))).toList();
    }
  }

  Map<String, dynamic> _getStats() {
    if (_signals.isEmpty) return {'count': 0, 'max_chg': 0, 'win_rate': 0};
    double maxChg = 0;
    int winCount = 0;
    for (var s in _signals) {
      double chg = double.tryParse(s['chg'].toString()) ?? 0;
      if (chg > maxChg) maxChg = chg;
      if (chg > 0) winCount++;
    }
    return {
      'count': _signals.length,
      'max_chg': maxChg,
      'win_rate': winCount / _signals.length * 100,
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _getStats();
    return Scaffold(
      appBar: AppBar(
        title: Text('资金脉冲', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          Switch(
            value: _showOnlyToday,
            onChanged: (value) {
              setState(() {
                _showOnlyToday = value;
                _fetchInitialData();
              });
            },
            activeColor: Colors.cyan,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchInitialData,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueGrey[900]!, Colors.black],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
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
          if (_moodReport.isNotEmpty)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey[800],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyan, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology, color: Colors.cyan, size: 18),
                      SizedBox(width: 6),
                      Text('今日开盘情绪', style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    _moodReport,
                    style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.4),
                    softWrap: true,
                  ),
                ],
              ),
            ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                SizedBox(width: 8),
                _FilterChip(
                  label: '资金信号',
                  isSelected: _filterType == 'pulse',
                  onTap: () => setState(() {
                    _filterType = 'pulse';
                    _applyFilter();
                  }),
                ),
                SizedBox(width: 8),
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
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : _filteredSignals.isEmpty
                    ? Center(child: Text('暂无信号，等待数据...', style: TextStyle(color: Colors.grey)))
                    : RefreshIndicator(
                        onRefresh: _fetchInitialData,
                        child: ListView.builder(
                          itemCount: _filteredSignals.length,
                          itemBuilder: (context, i) {
                            final s = _filteredSignals[i];
                            return _SignalCard(signal: s);
                          },
                        ),
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
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
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
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetailDialog(context),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: eventColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      eventType,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('${signal['time']}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Spacer(),
                  Icon(trendIcon, color: chgColor, size: 18),
                  SizedBox(width: 4),
                  Text(
                    '${chg.toStringAsFixed(2)}%',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: chgColor),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text('${signal['name']}(${signal['code']})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.speed, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text('2s: ${signal['mn_wan']}万', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  SizedBox(width: 12),
                  Icon(Icons.timer, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text('6s: ${signal['total_6s_wan']}万', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Spacer(),
                  Text('${signal['cap']}亿', style: TextStyle(fontSize: 12, color: Colors.cyan)),
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
        title: Text('信号详情'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('股票：${signal['name']}(${signal['code']})'),
            SizedBox(height: 8),
            Text('时间：${signal['time']}'),
            Text('事件：${signal['event']}'),
            Text('市值：${signal['cap']} 亿'),
            Text('涨幅：${signal['chg']}%'),
            Text('2秒净流入：${signal['mn_wan']} 万'),
            Text('6秒净流入：${signal['total_6s_wan']} 万'),
            Text('脉冲占比：${signal['pulse_ratio']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('关闭'),
          ),
        ],
      ),
    );
  }
}