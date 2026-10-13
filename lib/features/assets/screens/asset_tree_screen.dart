import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../facilities/providers/facility_providers.dart';
import '../models/asset.dart';
import '../providers/asset_providers.dart';

class AssetTreeScreen extends ConsumerWidget {
  const AssetTreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilityAsync = ref.watch(primaryFacilityProvider);

    return facilityAsync.when(
      data: (facility) {
        if (facility == null) return const Scaffold(body: Center(child: Text('کارگاهی یافت نشد')));
        final assetsAsync = ref.watch(assetsProvider(facility.id));

        return Scaffold(
          appBar: AppBar(
            title: const Text('درخت سلسله‌مراتبی تجهیزات', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: assetsAsync.when(
            data: (allAssets) {
              if (allAssets.isEmpty) return const Center(child: Text('تجهیزی ثبت نشده است.'));
              final rootAssets = allAssets.where((a) => a.parentAssetId == null).toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                itemCount: rootAssets.length,
                itemBuilder: (context, index) {
                  final rootAsset = rootAssets[index];
                  return _AssetTreeNode(
                    asset: rootAsset,
                    allAssets: allAssets,
                    depth: 0,
                  );
                },
              );
            },
            loading: () => const AppLoading(),
            error: (e, _) => AppErrorState(message: e.toString()),
          ),
        );
      },
      loading: () => const Scaffold(body: AppLoading()),
      error: (e, _) => Scaffold(body: AppErrorState(message: e.toString())),
    );
  }
}

class _AssetTreeNode extends StatefulWidget {
  final Asset asset;
  final List<Asset> allAssets;
  final int depth;

  const _AssetTreeNode({
    required this.asset,
    required this.allAssets,
    required this.depth,
  });

  @override
  State<_AssetTreeNode> createState() => _AssetTreeNodeState();
}

class _AssetTreeNodeState extends State<_AssetTreeNode> {
  bool _isExpanded = true;

  Color _getStatusColor(AssetStatus status) {
    switch (status) {
      case AssetStatus.active:
        return Colors.green;
      case AssetStatus.underMaintenance:
        return Colors.orange;
      case AssetStatus.inactive:
        return Colors.grey;
      case AssetStatus.retired:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = widget.allAssets.where((a) => a.parentAssetId == widget.asset.id).toList();
    final hasChildren = children.isNotEmpty;
    final indentPadding = EdgeInsets.only(right: widget.depth * 20.0);
    final statusColor = _getStatusColor(widget.asset.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: indentPadding,
          child: InkWell(
            onTap: () => context.push('/assets/${widget.asset.id}'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Expand/Collapse Icon if children exist
                  if (hasChildren)
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Icon(
                          _isExpanded ? EneftyIcons.arrow_down_bold : EneftyIcons.arrow_right_3_bold,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 26),

                  // Node Icon
                  Icon(
                    widget.depth == 0 ? EneftyIcons.cpu_bold : EneftyIcons.setting_bold,
                    size: widget.depth == 0 ? 22 : 18,
                    color: widget.depth == 0 ? Theme.of(context).colorScheme.primary : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 10),

                  // Asset Name & Code
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.asset.name,
                          style: TextStyle(
                            fontWeight: widget.depth == 0 ? FontWeight.bold : FontWeight.w600,
                            fontSize: widget.depth == 0 ? 15 : 14,
                          ),
                        ),
                        Text(
                          'کد: ${widget.asset.code} | نوع: ${widget.asset.assetType.displayName}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  // Status Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.asset.status.displayName,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Recursive Children Nodes
        if (hasChildren && _isExpanded)
          Column(
            children: children
                .map((child) => _AssetTreeNode(
                      asset: child,
                      allAssets: widget.allAssets,
                      depth: widget.depth + 1,
                    ))
                .toList(),
          ),
      ],
    );
  }
}
