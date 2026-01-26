import 'package:flutter/material.dart';
import '../services/api_client.dart';

class ModelSelector extends StatefulWidget {
  final String selectedModel;
  final Function(String) onModelChanged;

  const ModelSelector({
    Key? key,
    required this.selectedModel,
    required this.onModelChanged,
  }) : super(key: key);

  @override
  State<ModelSelector> createState() => _ModelSelectorState();
}

class _ModelSelectorState extends State<ModelSelector> {
  final ApiClient _apiClient = ApiClient();
  List<ModelInfo> _models = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    try {
      final modelsData = await _apiClient.getModels();
      setState(() {
        _models = modelsData
            .map((m) => ModelInfo(
                  id: m['id'] ?? '',
                  name: m['name'] ?? m['id'] ?? 'Unknown',
                ))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _models = [
          ModelInfo(id: 'gpt-4', name: 'GPT-4'),
          ModelInfo(id: 'gpt-3.5-turbo', name: 'GPT-3.5 Turbo'),
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 150,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return PopupMenuButton<String>(
      initialValue: widget.selectedModel,
      onSelected: widget.onModelChanged,
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (context) => _models.map((model) {
        return PopupMenuItem<String>(
          value: model.id,
          child: Row(
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 20,
                color: widget.selectedModel == model.id
                    ? Colors.blue.shade600
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  model.name,
                  style: TextStyle(
                    fontWeight: widget.selectedModel == model.id
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: widget.selectedModel == model.id
                        ? Colors.blue.shade600
                        : Colors.grey.shade900,
                  ),
                ),
              ),
              if (widget.selectedModel == model.id)
                Icon(
                  Icons.check,
                  size: 20,
                  color: Colors.blue.shade600,
                ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 18,
              color: Colors.grey.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              _models.firstWhere(
                (m) => m.id == widget.selectedModel,
                orElse: () => ModelInfo(id: widget.selectedModel, name: widget.selectedModel),
              ).name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: Colors.grey.shade700,
            ),
          ],
        ),
      ),
    );
  }
}

class ModelInfo {
  final String id;
  final String name;

  ModelInfo({required this.id, required this.name});
}
