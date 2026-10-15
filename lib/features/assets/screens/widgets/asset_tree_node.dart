import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/enums/app_enums.dart';
import '../../models/asset.dart';

class AssetTreeNode extends StatefulWidget {
  final Asset asset;
  final List<Asset> allAssets;
  final int depth;

  const AssetTreeNode({
    super.key,
    required this.asset,
    required this.allAssets,
    required this.depth,
  });

  @override
  State<AssetTreeNode> createState() => _AssetTreeNodeState();
}

class _AssetTreeNodeState extends State<AssetTreeNode> {
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
    final children = widget.allAssets
        .where((asset) => asset.parentAssetId == widget.asset.id)
        .toList();
    final hasChildren = children.isNotEmpty;
    final statusColor = _getStatusColor(widget.asset.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: widget.depth * 20.0),
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
                  if (hasChildren)
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          _isExpanded
                              ? EneftyIcons.arrow_down_bold
                              : EneftyIcons.arrow_right_3_bold,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 26),
                  Icon(
                    widget.depth == 0
                        ? EneftyIcons.cpu_bold
                        : EneftyIcons.setting_bold,
                    size: widget.depth == 0 ? 22 : 18,
                    color: widget.depth == 0
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.asset.name,
                          style: TextStyle(
                            fontWeight: widget.depth == 0
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: widget.depth == 0 ? 15 : 14,
                          ),
                        ),
                        Text(
                          'کد: ${widget.asset.code} | نوع: ${widget.asset.assetType.displayName}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.asset.status.displayName,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasChildren && _isExpanded)
          Column(
            children: children
                .map(
                  (child) => AssetTreeNode(
                    asset: child,
                    allAssets: widget.allAssets,
                    depth: widget.depth + 1,
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
