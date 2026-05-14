import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserAnalysisPage extends StatefulWidget {
  @override
  _UserAnalysisPageState createState() => _UserAnalysisPageState();
}

class _UserAnalysisPageState extends State<UserAnalysisPage> {
  List<Map<String, dynamic>> _analysis = [];
  bool _loading = true;
  String? _selectedDate;
  String _filterGrade = 'all'; // all, S, A, B, C

  @override
  void initState() {
    super.initState();
    _fetchAnalysis();
  }

  Future<void> _fetchAnalysis() async {
    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('user_auction_reports')
            .select()
            .eq('user_id', user.id)
            .order('analysis_date', ascending: false)
            .order('score', ascending: false);
        _analysis = List<Map<String, dynamic>>.from(response);
        if (_analysis.isNotEmpty) {
          _selectedDate = _analysis[0]['analysis_date'];
        }
      }
    } catch (e) {
      print("获取分析数据失败: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取数据失败：$e'), backgroundColor: Colors.red),
      );
    }
    setState(() => _loading = false);
  }

  List<String> get _availableDates {
    return _analysis.map((a) => a['analysis_date'] as String).toSet().toList();
  }

  List<Map<String, dynamic>> get _filteredAnalysis {
    if (_selectedDate == null) return [];
    var filtered = _analysis.where((a) => a['analysis_date'] == _selectedDate).toList();
    if (_filterGrade != 'all') {
      filtered = filtered.where((a) => a['grade'] == _filterGrade).toList();
    }
    return filtered;
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'S': return Colors.red;
      case 'A': return Colors.orange;
      case 'B': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _getGradeText(String grade) {
    switch (grade) {
      case 'S': return '强烈关注';
      case 'A': return '重点关注';
      case 'B': return '一般关注';
      default: return '谨慎';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('自选股竞价分析', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchAnalysis,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _analysis.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('暂无分析数据', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      SizedBox(height: 8),
                      Text('请先添加自选股，次日9:25后查看', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // 日期选择器 + 评级筛选
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedDate,
                              items: _availableDates.map((date) {
                                return DropdownMenuItem(
                                  value: date,
                                  child: Text(date, style: TextStyle(fontSize: 14)),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => _selectedDate = value),
                              decoration: InputDecoration(
                                labelText: '选择日期',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[700]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _filterGrade,
                                items: [
                                  DropdownMenuItem(value: 'all', child: Text('全部')),
                                  DropdownMenuItem(value: 'S', child: Text('S级', style: TextStyle(color: Colors.red))),
                                  DropdownMenuItem(value: 'A', child: Text('A级', style: TextStyle(color: Colors.orange))),
                                  DropdownMenuItem(value: 'B', child: Text('B级', style: TextStyle(color: Colors.blue))),
                                  DropdownMenuItem(value: 'C', child: Text('C级', style: TextStyle(color: Colors.grey))),
                                ],
                                onChanged: (value) => setState(() => _filterGrade = value!),
                                icon: Icon(Icons.filter_list, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 统计卡片
                    if (_filteredAnalysis.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(
                              icon: Icons.star,
                              value: _filteredAnalysis.where((a) => a['grade'] == 'S').length.toString(),
                              label: 'S级',
                              color: Colors.red,
                            ),
                            _StatItem(
                              icon: Icons.trending_up,
                              value: _filteredAnalysis.where((a) => a['grade'] == 'A').length.toString(),
                              label: 'A级',
                              color: Colors.orange,
                            ),
                            _StatItem(
                              icon: Icons.remove_red_eye,
                              value: _filteredAnalysis.where((a) => a['grade'] == 'B').length.toString(),
                              label: 'B级',
                              color: Colors.blue,
                            ),
                            _StatItem(
                              icon: Icons.warning,
                              value: _filteredAnalysis.where((a) => a['grade'] == 'C').length.toString(),
                              label: 'C级',
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    // 分析列表
                    Expanded(
                      child: _filteredAnalysis.isEmpty
                          ? Center(child: Text('暂无该日期的分析数据', style: TextStyle(color: Colors.grey)))
                          : RefreshIndicator(
                              onRefresh: _fetchAnalysis,
                              child: ListView.builder(
                                itemCount: _filteredAnalysis.length,
                                itemBuilder: (context, i) {
                                  final a = _filteredAnalysis[i];
                                  return Card(
                                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => _showDetailDialog(a),
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
                                                    color: _getGradeColor(a['grade']).withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: _getGradeColor(a['grade'])),
                                                  ),
                                                  child: Text(
                                                    '${a['grade']}级 ${_getGradeText(a['grade'])}',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: _getGradeColor(a['grade']),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[800],
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    a['tag'] ?? '一般',
                                                    style: TextStyle(fontSize: 10),
                                                  ),
                                                ),
                                                Spacer(),
                                                Text(
                                                  '${(a['jjzf'] as num?)?.toStringAsFixed(2) ?? '0'}%',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: (a['jjzf'] ?? 0) >= 0 ? Colors.redAccent : Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              '${a['stock_name']}(${a['stock_code']})',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                            ),
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.speed, size: 14, color: Colors.grey),
                                                SizedBox(width: 4),
                                                Text('评分: ${(a['score'] as num?)?.toStringAsFixed(2) ?? '0'}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                                SizedBox(width: 12),
                                                Icon(Icons.storage, size: 14, color: Colors.grey),
                                                SizedBox(width: 4),
                                                Text('${a['cap']}亿', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                              ],
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              a['comment'] ?? '',
                                              style: TextStyle(fontSize: 11, color: Colors.white54),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${data['stock_name']}(${data['stock_code']})'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow(label: '竞价涨幅', value: '${(data['jjzf'] as num?)?.toStringAsFixed(2) ?? '0'}%'),
              _DetailRow(label: '竞价量', value: '${data['jjl']}手'),
              _DetailRow(label: '竞价金额', value: '${((data['jje'] as num?)?.toInt() ?? 0) ~/ 10000}万'),
              _DetailRow(label: '未匹配量', value: '${data['nol']}手'),
              _DetailRow(label: '趋势', value: data['trend'] == 1 ? '主动买' : (data['trend'] == -1 ? '主动卖' : '中性')),
              _DetailRow(label: '市值', value: '${data['cap']}亿'),
              _DetailRow(label: '强度', value: '${(data['strength_val'] as num?)?.toStringAsFixed(3) ?? '0'}‰'),
              _DetailRow(label: '评分', value: '${(data['score'] as num?)?.toStringAsFixed(3) ?? '0'}'),
              _DetailRow(label: '评级', value: '${data['grade']}级'),
              _DetailRow(label: '形态', value: data['tag'] ?? '一般'),
              Divider(),
              Text('💬 操作建议', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(data['comment'] ?? '', style: TextStyle(fontSize: 13)),
            ],
          ),
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

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}