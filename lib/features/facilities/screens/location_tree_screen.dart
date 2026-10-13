import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../models/location.dart';
import '../providers/facility_providers.dart';

class LocationTreeScreen extends ConsumerWidget {
  const LocationTreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilityAsync = ref.watch(primaryFacilityProvider);

    return facilityAsync.when(
      data: (facility) {
        if (facility == null) return const Scaffold(body: Center(child: Text('کارگاهی یافت نشد')));
        final locationsAsync = ref.watch(locationsProvider(facility.id));

        return Scaffold(
          appBar: AppBar(
            title: const Text('درخت سلسله‌مراتبی موقعیت‌ها', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: locationsAsync.when(
            data: (allLocations) {
              if (allLocations.isEmpty) return const Center(child: Text('موقعیتی ثبت نشده است.'));
              final rootLocations = allLocations.where((loc) => loc.parentLocationId == null).toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                itemCount: rootLocations.length,
                itemBuilder: (context, index) {
                  final rootLoc = rootLocations[index];
                  return _LocationTreeNode(
                    location: rootLoc,
                    allLocations: allLocations,
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

class _LocationTreeNode extends StatefulWidget {
  final Location location;
  final List<Location> allLocations;
  final int depth;

  const _LocationTreeNode({
    required this.location,
    required this.allLocations,
    required this.depth,
  });

  @override
  State<_LocationTreeNode> createState() => _LocationTreeNodeState();
}

class _LocationTreeNodeState extends State<_LocationTreeNode> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final children = widget.allLocations.where((loc) => loc.parentLocationId == widget.location.id).toList();
    final hasChildren = children.isNotEmpty;
    final indentPadding = EdgeInsets.only(right: widget.depth * 20.0);
    final isActive = widget.location.isActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: indentPadding,
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
                    widget.depth == 0 ? EneftyIcons.location_bold : EneftyIcons.location_outline,
                    size: widget.depth == 0 ? 22 : 18,
                    color: widget.depth == 0 ? const Color(0xFF0284C7) : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 10),

                  // Location Name & Code
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.location.name,
                          style: TextStyle(
                            fontWeight: widget.depth == 0 ? FontWeight.bold : FontWeight.w600,
                            fontSize: widget.depth == 0 ? 15 : 14,
                          ),
                        ),
                        if (widget.location.code != null && widget.location.code!.isNotEmpty)
                          Text(
                            'کد: ${widget.location.code}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                      ],
                    ),
                  ),

                  // Active Status Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isActive ? Colors.green : Colors.grey).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isActive ? 'فعال' : 'غیرفعال',
                      style: TextStyle(color: isActive ? Colors.green : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
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
                .map((child) => _LocationTreeNode(
                      location: child,
                      allLocations: widget.allLocations,
                      depth: widget.depth + 1,
                    ))
                .toList(),
          ),
      ],
    );
  }
}
