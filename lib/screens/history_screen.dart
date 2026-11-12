import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/history_entry.dart';
import '../services/history_database.dart';
import '../services/export_service.dart';

/// 历史记录界面
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryEntry> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await HistoryDatabase.instance.readAll();
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  Future<void> _deleteEntry(int id) async {
    await HistoryDatabase.instance.delete(id);
    _loadHistory();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已删除记录')),
      );
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空历史记录'),
        content: const Text('确定要删除所有历史记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await HistoryDatabase.instance.deleteAll();
      _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已清空历史记录')),
        );
      }
    }
  }

  Future<void> _exportHistory() async {
    if (_history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可导出的记录')),
      );
      return;
    }

    // 选择导出格式
    final format = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择导出格式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('CSV格式'),
              subtitle: const Text('适合Excel打开'),
              onTap: () => Navigator.pop(context, 'csv'),
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet),
              title: const Text('TXT格式'),
              subtitle: const Text('纯文本格式'),
              onTap: () => Navigator.pop(context, 'txt'),
            ),
          ],
        ),
      ),
    );

    if (format == null) return;

    try {
      String filePath;
      if (format == 'csv') {
        filePath = await ExportService.exportToCSV(_history);
      } else {
        filePath = await ExportService.exportToTXT(_history);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出成功：$filePath'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('历史记录'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.file_download),
              onPressed: _exportHistory,
              tooltip: '导出',
            ),
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAll,
              tooltip: '清空',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 80,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无历史记录',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final entry = _history[index];
                    return _buildHistoryCard(entry);
                  },
                ),
    );
  }

  Widget _buildHistoryCard(HistoryEntry entry) {
    final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(entry.timestamp);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () {
          // 返回到计算器页面并加载该表达式
          Navigator.pop(context, entry.expression);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.expression,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '= ${entry.result}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeStr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteEntry(entry.id!),
                tooltip: '删除',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
