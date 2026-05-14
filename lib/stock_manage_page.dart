import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

// 股票名称映射
Map<String, String> stockMap = {};

class StockManagePage extends StatefulWidget {
  @override
  _StockManagePageState createState() => _StockManagePageState();
}

class _StockManagePageState extends State<StockManagePage> {
  List<Map<String, dynamic>> _userStocks = [];
  List<String> _userCommonStocks = [];
  final TextEditingController _stockCodeController = TextEditingController();
  bool _loading = true;
  bool _adding = false;

  Future<void> loadStockMap() async {
    try {
      final String response = await rootBundle.loadString('stock_dict.json');
      final data = json.decode(response);
      stockMap = Map<String, String>.from(data);
    } catch (e) {
      print("加载股票字典失败: $e");
    }
  }

  // 板块标识：沪 / 深 / 创 / 北
  String _getMarketLabel(String code) {
    if (code.startsWith('6')) return '沪';
    if (code.startsWith('0')) return '深';
    if (code.startsWith('3')) return '创';
    if (code.startsWith('8') || code.startsWith('9')) return '北';
    return code[0];
  }

  @override
  void initState() {
    super.initState();
    loadStockMap().then((_) {
      _fetchUserStocks();
    });
  }

  @override
  void dispose() {
    _stockCodeController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserStocks() async {
    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('user_stocks')
            .select('stock_code, created_at')
            .eq('user_id', user.id)
            .order('created_at', ascending: false);
        _userStocks = List<Map<String, dynamic>>.from(response);

        setState(() {
          _userCommonStocks = _userStocks.map((s) => s['stock_code'].toString()).toList();
        });
      }
    } catch (e) {
      print("获取自选股失败: $e");
    }
    setState(() => _loading = false);
  }

  Future<void> _addStock() async {
    final code = _stockCodeController.text.trim().toUpperCase();
    if (code.isEmpty || !RegExp(r'^\d{6}$').hasMatch(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请输入6位股票代码'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_userStocks.any((s) => s['stock_code'] == code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已在自选列表'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _adding = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('user_stocks')
            .insert({'user_id': user.id, 'stock_code': code});
        _stockCodeController.clear();
        await _fetchUserStocks();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ 添加成功'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('添加失败'), backgroundColor: Colors.red),
      );
    }
    setState(() => _adding = false);
  }

  Future<void> _removeStock(String stockCode) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认删除'),
        content: Text('确定要删除 $stockCode 吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('user_stocks')
            .delete()
            .eq('user_id', user.id)
            .eq('stock_code', stockCode);
        await _fetchUserStocks();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ 删除成功'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('自选股管理', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _stockCodeController,
                        decoration: InputDecoration(
                          labelText: '输入股票代码',
                          hintText: '6位数字',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: Icon(Icons.search),
                        ),
                        keyboardType: TextInputType.number,
                        onSubmitted: (_) => _addStock(),
                      ),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _adding ? null : _addStock,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _adding ? CircularProgressIndicator(strokeWidth:2) : Text('添加'),
                    ),
                  ],
                ),
                SizedBox(height:12),
                Wrap(
                  spacing:8, runSpacing:8,
                  children: _userCommonStocks.map((code) {
                    return ActionChip(
                      label: Text(code),
                      onPressed: () {
                        _stockCodeController.text = code;
                        _addStock();
                      },
                      backgroundColor: Colors.cyan[900],
                      labelStyle: TextStyle(color: Colors.white),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : _userStocks.isEmpty
                    ? Center(child: Text('暂无自选股', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _userStocks.length,
                        itemBuilder: (context,i) {
                          final stock = _userStocks[i];
                          final code = stock['stock_code'];
                          final name = stockMap[code] ?? '';
                          final marketLabel = _getMarketLabel(code);

                          return Card(
                            margin: EdgeInsets.symmetric(horizontal:12,vertical:6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.cyan,
                                child: Text(
                                  marketLabel,
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text('$code $name', style: TextStyle(fontSize:16)),
                              subtitle: Text('添加于 ${_formatDate(stock['created_at'])}', style: TextStyle(fontSize:12)),
                              trailing: IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _removeStock(code),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final d = DateTime.parse(dateStr);
      return '${d.month}/${d.day} ${d.hour}:${d.minute.toString().padLeft(2,'0')}';
    } catch(e) { return ''; }
  }
}