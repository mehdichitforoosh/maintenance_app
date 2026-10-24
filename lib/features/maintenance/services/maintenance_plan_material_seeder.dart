import 'package:sqflite/sqflite.dart';

import '../../../core/storage/database/tables/maintenance_plan_material_table.dart';
import '../../../core/storage/database/tables/work_order_material_table.dart';
import '../../../core/utils/id_generator.dart';

class MaintenancePlanMaterialSeeder {
  static Future<void> seedTaskMaterials(
    DatabaseExecutor db, {
    required String planId,
    required String taskId,
    required String now,
  }) async {
    final materials = await db.query(
      MaintenancePlanMaterialTable.tableName,
      where:
          '${MaintenancePlanMaterialTable.maintenancePlanId} = ? AND ${MaintenancePlanMaterialTable.deletedAt} IS NULL',
      whereArgs: [planId],
    );

    for (final material in materials) {
      await db.insert(WorkOrderMaterialTable.tableName, {
        WorkOrderMaterialTable.id: IdGenerator.generate(),
        WorkOrderMaterialTable.workOrderTaskId: taskId,
        WorkOrderMaterialTable.itemId:
            material[MaintenancePlanMaterialTable.itemId],
        WorkOrderMaterialTable.plannedQuantity:
            material[MaintenancePlanMaterialTable.plannedQuantity],
        WorkOrderMaterialTable.notes:
            material[MaintenancePlanMaterialTable.notes],
        WorkOrderMaterialTable.createdAt: now,
        WorkOrderMaterialTable.updatedAt: now,
        WorkOrderMaterialTable.syncStatus: 'pending',
      });
    }
  }
}
