import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/utils/validators.dart';
import '../providers/work_order_providers.dart';

class CompleteTaskScreen extends ConsumerStatefulWidget {
  final String workOrderId;
  final String taskId;

  const CompleteTaskScreen({super.key, required this.workOrderId, required this.taskId});

  @override
  ConsumerState<CompleteTaskScreen> createState() => _CompleteTaskScreenState();
}

class _CompleteTaskScreenState extends ConsumerState<CompleteTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _findingsController = TextEditingController();
  final _laborController = TextEditingController(text: '30');
  final _downtimeController = TextEditingController(text: '0');
  TaskResult _result = TaskResult.success;
  bool _isLoading = false;

  @override
  void dispose() {
    _findingsController.dispose();
    _laborController.dispose();
    _downtimeController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(workOrderRepositoryProvider);
      await repo.completeTask(
        taskId: widget.taskId,
        result: _result,
        findings: _findingsController.text.trim().isEmpty ? null : _findingsController.text.trim(),
        laborMinutes: int.tryParse(_laborController.text.trim()) ?? 0,
        downtimeMinutes: int.tryParse(_downtimeController.text.trim()) ?? 0,
      );

      ref.invalidate(workOrderDetailProvider(widget.workOrderId));
      ref.invalidate(workOrderTasksProvider(widget.workOrderId));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تکمیل وظیفه تعمیراتی')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<TaskResult>(
                value: _result,
                decoration: const InputDecoration(labelText: 'نتیجه انجام کار *', border: OutlineInputBorder()),
                items: TaskResult.values.map((r) => DropdownMenuItem(value: r, child: Text(r.displayName))).toList(),
                onChanged: (v) => setState(() => _result = v ?? TaskResult.success),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _findingsController,
                decoration: const InputDecoration(labelText: 'یافته‌ها و گزارش کار', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _laborController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'زمان کار (دقیقه)', border: OutlineInputBorder()),
                      validator: (v) => AppValidators.nonNegativeNumber(v, fieldName: 'زمان کار'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _downtimeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'زمان توقف (دقیقه)', border: OutlineInputBorder()),
                      validator: (v) => AppValidators.nonNegativeNumber(v, fieldName: 'زمان توقف'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _complete,
                child: const Text('ثبت و تکمیل وظیفه'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
