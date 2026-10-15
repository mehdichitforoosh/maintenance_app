import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/location.dart';

class LocationTreeNode extends StatefulWidget {
  final Location location;
  final List<Location> allLocations;
  final int depth;

  const LocationTreeNode({
    super.key,
    required this.location,
    required this.allLocations,
    required this.depth,
  });

  @override
  State<LocationTreeNode> createState() => _LocationTreeNodeState();
}

class _LocationTreeNodeState extends State<LocationTreeNode> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final children = widget.allLocations
        .where((location) => location.parentLocationId == widget.location.id)
        .toList();
    final hasChildren = children.isNotEmpty;
    final isActive = widget.location.isActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: widget.depth * 20.0),
          child: InkWell(
            onTap: () => context.push('/locations/${widget.location.id}/edit'),
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
                        ? EneftyIcons.location_bold
                        : EneftyIcons.location_outline,
                    size: widget.depth == 0 ? 22 : 18,
                    color: widget.depth == 0
                        ? const Color(0xFF0284C7)
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.location.name,
                          style: TextStyle(
                            fontWeight: widget.depth == 0
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: widget.depth == 0 ? 15 : 14,
                          ),
                        ),
                        if (widget.location.code?.isNotEmpty == true)
                          Text(
                            'کد: ${widget.location.code}',
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
                      color: (isActive ? Colors.green : Colors.grey).withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isActive ? 'فعال' : 'غیرفعال',
                      style: TextStyle(
                        color: isActive ? Colors.green : Colors.grey,
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
                  (child) => LocationTreeNode(
                    location: child,
                    allLocations: widget.allLocations,
                    depth: widget.depth + 1,
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
