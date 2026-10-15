enum AssetType {
  machine,
  motor,
  pump,
  compressor,
  electrical,
  other;

  String toDbString() {
    switch (this) {
      case AssetType.machine: return 'MACHINE';
      case AssetType.motor: return 'MOTOR';
      case AssetType.pump: return 'PUMP';
      case AssetType.compressor: return 'COMPRESSOR';
      case AssetType.electrical: return 'ELECTRICAL';
      case AssetType.other: return 'OTHER';
    }
  }

  static AssetType fromDbString(String? value) {
    switch (value) {
      case 'MACHINE': return AssetType.machine;
      case 'MOTOR': return AssetType.motor;
      case 'PUMP': return AssetType.pump;
      case 'COMPRESSOR': return AssetType.compressor;
      case 'ELECTRICAL': return AssetType.electrical;
      case 'OTHER': default: return AssetType.other;
    }
  }

  String get displayName {
    switch (this) {
      case AssetType.machine: return 'ماشین‌آلات';
      case AssetType.motor: return 'الکتروموتور';
      case AssetType.pump: return 'پمپ';
      case AssetType.compressor: return 'کمپرسور';
      case AssetType.electrical: return 'تجهیزات برق';
      case AssetType.other: return 'سایر';
    }
  }
}

enum AssetStatus {
  active,
  inactive,
  underMaintenance,
  retired;

  String toDbString() {
    switch (this) {
      case AssetStatus.active: return 'ACTIVE';
      case AssetStatus.inactive: return 'INACTIVE';
      case AssetStatus.underMaintenance: return 'UNDER_MAINTENANCE';
      case AssetStatus.retired: return 'RETIRED';
    }
  }

  static AssetStatus fromDbString(String? value) {
    switch (value) {
      case 'ACTIVE': return AssetStatus.active;
      case 'INACTIVE': return AssetStatus.inactive;
      case 'UNDER_MAINTENANCE': return AssetStatus.underMaintenance;
      case 'RETIRED': return AssetStatus.retired;
      default: return AssetStatus.active;
    }
  }

  String get displayName {
    switch (this) {
      case AssetStatus.active: return 'فعال';
      case AssetStatus.inactive: return 'غیرفعال';
      case AssetStatus.underMaintenance: return 'در دست تعمیر';
      case AssetStatus.retired: return 'اسقاط / بازنشسته';
    }
  }
}

enum ActivityType {
  inspection,
  lubrication,
  replacement,
  cleaning,
  calibration,
  testing,
  repair,
  other;

  String toDbString() {
    switch (this) {
      case ActivityType.inspection: return 'INSPECTION';
      case ActivityType.lubrication: return 'LUBRICATION';
      case ActivityType.replacement: return 'REPLACEMENT';
      case ActivityType.cleaning: return 'CLEANING';
      case ActivityType.calibration: return 'CALIBRATION';
      case ActivityType.testing: return 'TESTING';
      case ActivityType.repair: return 'REPAIR';
      case ActivityType.other: return 'OTHER';
    }
  }

  static ActivityType fromDbString(String? value) {
    switch (value) {
      case 'INSPECTION': return ActivityType.inspection;
      case 'LUBRICATION': return ActivityType.lubrication;
      case 'REPLACEMENT': return ActivityType.replacement;
      case 'CLEANING': return ActivityType.cleaning;
      case 'CALIBRATION': return ActivityType.calibration;
      case 'TESTING': return ActivityType.testing;
      case 'REPAIR': return ActivityType.repair;
      case 'OTHER': default: return ActivityType.other;
    }
  }

  String get displayName {
    switch (this) {
      case ActivityType.inspection: return 'بازرسی';
      case ActivityType.lubrication: return 'روغن‌کاری / گریس‌کاری';
      case ActivityType.replacement: return 'تعویض قطعه';
      case ActivityType.cleaning: return 'تمیزکاری';
      case ActivityType.calibration: return 'کالیبراسیون';
      case ActivityType.testing: return 'تست و آزمون';
      case ActivityType.repair: return 'تعمیر';
      case ActivityType.other: return 'سایر';
    }
  }
}

enum Priority {
  low,
  medium,
  high,
  critical;

  String toDbString() {
    switch (this) {
      case Priority.low: return 'LOW';
      case Priority.medium: return 'MEDIUM';
      case Priority.high: return 'HIGH';
      case Priority.critical: return 'CRITICAL';
    }
  }

  static Priority fromDbString(String? value) {
    switch (value) {
      case 'LOW': return Priority.low;
      case 'MEDIUM': return Priority.medium;
      case 'HIGH': return Priority.high;
      case 'CRITICAL': return Priority.critical;
      default: return Priority.medium;
    }
  }

  String get displayName {
    switch (this) {
      case Priority.low: return 'کم';
      case Priority.medium: return 'متوسط';
      case Priority.high: return 'زیاد';
      case Priority.critical: return 'بحرانی';
    }
  }
}

enum ScheduleType {
  calendar,
  meter,
  condition,
  oneTime,
  manual;

  String toDbString() {
    switch (this) {
      case ScheduleType.calendar: return 'CALENDAR';
      case ScheduleType.meter: return 'METER';
      case ScheduleType.condition: return 'CONDITION';
      case ScheduleType.oneTime: return 'ONE_TIME';
      case ScheduleType.manual: return 'MANUAL';
    }
  }

  static ScheduleType fromDbString(String? value) {
    switch (value) {
      case 'CALENDAR': return ScheduleType.calendar;
      case 'METER': return ScheduleType.meter;
      case 'CONDITION': return ScheduleType.condition;
      case 'ONE_TIME': return ScheduleType.oneTime;
      case 'MANUAL': return ScheduleType.manual;
      default: return ScheduleType.manual;
    }
  }

  String get displayName {
    switch (this) {
      case ScheduleType.calendar: return 'تقویمی (زمانی)';
      case ScheduleType.meter: return 'کارکرد (متری)';
      case ScheduleType.condition: return 'شرطی (سنسور/وضعیت)';
      case ScheduleType.oneTime: return 'یک‌باره';
      case ScheduleType.manual: return 'دستی';
    }
  }
}

enum CalendarUnit {
  day,
  week,
  month,
  year;

  String toDbString() {
    switch (this) {
      case CalendarUnit.day: return 'DAY';
      case CalendarUnit.week: return 'WEEK';
      case CalendarUnit.month: return 'MONTH';
      case CalendarUnit.year: return 'YEAR';
    }
  }

  static CalendarUnit? fromDbString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'DAY': return CalendarUnit.day;
      case 'WEEK': return CalendarUnit.week;
      case 'MONTH': return CalendarUnit.month;
      case 'YEAR': return CalendarUnit.year;
      default: return null;
    }
  }

  String get displayName {
    switch (this) {
      case CalendarUnit.day: return 'روز';
      case CalendarUnit.week: return 'هفته';
      case CalendarUnit.month: return 'ماه';
      case CalendarUnit.year: return 'سال';
    }
  }
}

enum ScheduleAnchor {
  completionDate,
  previousDueDate;

  String toDbString() {
    switch (this) {
      case ScheduleAnchor.completionDate: return 'COMPLETION_DATE';
      case ScheduleAnchor.previousDueDate: return 'PREVIOUS_DUE_DATE';
    }
  }

  static ScheduleAnchor fromDbString(String? value) {
    switch (value) {
      case 'COMPLETION_DATE': return ScheduleAnchor.completionDate;
      case 'PREVIOUS_DUE_DATE': return ScheduleAnchor.previousDueDate;
      default: return ScheduleAnchor.completionDate;
    }
  }
}

enum WorkOrderType {
  preventive,
  corrective,
  emergency;

  String toDbString() {
    switch (this) {
      case WorkOrderType.preventive: return 'PREVENTIVE';
      case WorkOrderType.corrective: return 'CORRECTIVE';
      case WorkOrderType.emergency: return 'EMERGENCY';
    }
  }

  static WorkOrderType fromDbString(String? value) {
    switch (value) {
      case 'PREVENTIVE': return WorkOrderType.preventive;
      case 'CORRECTIVE': return WorkOrderType.corrective;
      case 'EMERGENCY': return WorkOrderType.emergency;
      default: return WorkOrderType.preventive;
    }
  }

  String get displayName {
    switch (this) {
      case WorkOrderType.preventive: return 'پیشگیرانه (PM)';
      case WorkOrderType.corrective: return 'اصلاحی (CM)';
      case WorkOrderType.emergency: return 'اضطراری';
    }
  }
}

enum WorkOrderStatus {
  draft,
  open,
  inProgress,
  onHold,
  completed,
  cancelled;

  String toDbString() {
    switch (this) {
      case WorkOrderStatus.draft: return 'DRAFT';
      case WorkOrderStatus.open: return 'OPEN';
      case WorkOrderStatus.inProgress: return 'IN_PROGRESS';
      case WorkOrderStatus.onHold: return 'ON_HOLD';
      case WorkOrderStatus.completed: return 'COMPLETED';
      case WorkOrderStatus.cancelled: return 'CANCELLED';
    }
  }

  static WorkOrderStatus fromDbString(String? value) {
    switch (value) {
      case 'DRAFT': return WorkOrderStatus.draft;
      case 'OPEN': return WorkOrderStatus.open;
      case 'IN_PROGRESS': return WorkOrderStatus.inProgress;
      case 'ON_HOLD': return WorkOrderStatus.onHold;
      case 'COMPLETED': return WorkOrderStatus.completed;
      case 'CANCELLED': return WorkOrderStatus.cancelled;
      default: return WorkOrderStatus.open;
    }
  }

  String get displayName {
    switch (this) {
      case WorkOrderStatus.draft: return 'پیش‌نویس';
      case WorkOrderStatus.open: return 'باز';
      case WorkOrderStatus.inProgress: return 'در حال انجام';
      case WorkOrderStatus.onHold: return 'معلق';
      case WorkOrderStatus.completed: return 'تکمیل شده';
      case WorkOrderStatus.cancelled: return 'لغو شده';
    }
  }
}

enum TaskStatus {
  pending,
  inProgress,
  completed,
  skipped,
  cancelled;

  String toDbString() {
    switch (this) {
      case TaskStatus.pending: return 'PENDING';
      case TaskStatus.inProgress: return 'IN_PROGRESS';
      case TaskStatus.completed: return 'COMPLETED';
      case TaskStatus.skipped: return 'SKIPPED';
      case TaskStatus.cancelled: return 'CANCELLED';
    }
  }

  static TaskStatus fromDbString(String? value) {
    switch (value) {
      case 'PENDING': return TaskStatus.pending;
      case 'IN_PROGRESS': return TaskStatus.inProgress;
      case 'COMPLETED': return TaskStatus.completed;
      case 'SKIPPED': return TaskStatus.skipped;
      case 'CANCELLED': return TaskStatus.cancelled;
      default: return TaskStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case TaskStatus.pending: return 'در انتظار';
      case TaskStatus.inProgress: return 'در حال اجرا';
      case TaskStatus.completed: return 'تکمیل‌شده';
      case TaskStatus.skipped: return 'صرف‌نظر شده';
      case TaskStatus.cancelled: return 'لغو شده';
    }
  }
}

enum TaskResult {
  success,
  issueFound,
  failed,
  followUpRequired;

  String toDbString() {
    switch (this) {
      case TaskResult.success: return 'SUCCESS';
      case TaskResult.issueFound: return 'ISSUE_FOUND';
      case TaskResult.failed: return 'FAILED';
      case TaskResult.followUpRequired: return 'FOLLOW_UP_REQUIRED';
    }
  }

  static TaskResult? fromDbString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'SUCCESS': return TaskResult.success;
      case 'ISSUE_FOUND': return TaskResult.issueFound;
      case 'FAILED': return TaskResult.failed;
      case 'FOLLOW_UP_REQUIRED': return TaskResult.followUpRequired;
      default: return null;
    }
  }

  String get displayName {
    switch (this) {
      case TaskResult.success: return 'موفقیت‌آمیز';
      case TaskResult.issueFound: return 'یافت شدن نقص';
      case TaskResult.failed: return 'ناموفق';
      case TaskResult.followUpRequired: return 'نیازمند پیگیری';
    }
  }
}

enum ItemType {
  consumable,
  sparePart;

  String toDbString() {
    switch (this) {
      case ItemType.consumable: return 'CONSUMABLE';
      case ItemType.sparePart: return 'SPARE_PART';
    }
  }

  static ItemType fromDbString(String? value) {
    switch (value) {
      case 'CONSUMABLE': return ItemType.consumable;
      case 'SPARE_PART': return ItemType.sparePart;
      default: return ItemType.consumable;
    }
  }

  String get displayName {
    switch (this) {
      case ItemType.consumable: return 'مصرفی';
      case ItemType.sparePart: return 'قطعه یدکی';
    }
  }
}

enum PurchaseOrderStatus {
  draft,
  ordered,
  partiallyReceived,
  received,
  cancelled;

  String toDbString() {
    switch (this) {
      case PurchaseOrderStatus.draft: return 'DRAFT';
      case PurchaseOrderStatus.ordered: return 'ORDERED';
      case PurchaseOrderStatus.partiallyReceived: return 'PARTIALLY_RECEIVED';
      case PurchaseOrderStatus.received: return 'RECEIVED';
      case PurchaseOrderStatus.cancelled: return 'CANCELLED';
    }
  }

  static PurchaseOrderStatus fromDbString(String? value) {
    switch (value) {
      case 'DRAFT': return PurchaseOrderStatus.draft;
      case 'ORDERED': return PurchaseOrderStatus.ordered;
      case 'PARTIALLY_RECEIVED': return PurchaseOrderStatus.partiallyReceived;
      case 'RECEIVED': return PurchaseOrderStatus.received;
      case 'CANCELLED': return PurchaseOrderStatus.cancelled;
      default: return PurchaseOrderStatus.draft;
    }
  }

  String get displayName {
    switch (this) {
      case PurchaseOrderStatus.draft: return 'پیش‌نویس';
      case PurchaseOrderStatus.ordered: return 'سفارش داده شده';
      case PurchaseOrderStatus.partiallyReceived: return 'تحویل جزئی';
      case PurchaseOrderStatus.received: return 'تحویل کامل';
      case PurchaseOrderStatus.cancelled: return 'لغو شده';
    }
  }
}

enum TransactionType {
  purchaseReceipt,
  maintenanceConsumption,
  adjustmentIn,
  adjustmentOut,
  returnItem;

  String toDbString() {
    switch (this) {
      case TransactionType.purchaseReceipt: return 'PURCHASE_RECEIPT';
      case TransactionType.maintenanceConsumption: return 'MAINTENANCE_CONSUMPTION';
      case TransactionType.adjustmentIn: return 'ADJUSTMENT_IN';
      case TransactionType.adjustmentOut: return 'ADJUSTMENT_OUT';
      case TransactionType.returnItem: return 'RETURN';
    }
  }

  static TransactionType fromDbString(String? value) {
    switch (value) {
      case 'PURCHASE_RECEIPT': return TransactionType.purchaseReceipt;
      case 'MAINTENANCE_CONSUMPTION': return TransactionType.maintenanceConsumption;
      case 'ADJUSTMENT_IN': return TransactionType.adjustmentIn;
      case 'ADJUSTMENT_OUT': return TransactionType.adjustmentOut;
      case 'RETURN': return TransactionType.returnItem;
      default:
        throw FormatException('Unknown stock transaction type: $value');
    }
  }

  String get displayName {
    switch (this) {
      case TransactionType.purchaseReceipt: return 'رسید خرید';
      case TransactionType.maintenanceConsumption: return 'مصرف در نگهداری';
      case TransactionType.adjustmentIn: return 'تعدیل افزایش (ورود)';
      case TransactionType.adjustmentOut: return 'تعدیل کاهش (خروج)';
      case TransactionType.returnItem: return 'برگشت از مصرف';
    }
  }
}

enum AlertType {
  maintenanceDue,
  maintenanceOverdue,
  conditionTriggered,
  lowStock,
  workOrderOverdue;

  String toDbString() {
    switch (this) {
      case AlertType.maintenanceDue: return 'MAINTENANCE_DUE';
      case AlertType.maintenanceOverdue: return 'MAINTENANCE_OVERDUE';
      case AlertType.conditionTriggered: return 'CONDITION_TRIGGERED';
      case AlertType.lowStock: return 'LOW_STOCK';
      case AlertType.workOrderOverdue: return 'WORK_ORDER_OVERDUE';
    }
  }

  static AlertType fromDbString(String? value) {
    switch (value) {
      case 'MAINTENANCE_DUE': return AlertType.maintenanceDue;
      case 'MAINTENANCE_OVERDUE': return AlertType.maintenanceOverdue;
      case 'CONDITION_TRIGGERED': return AlertType.conditionTriggered;
      case 'LOW_STOCK': return AlertType.lowStock;
      case 'WORK_ORDER_OVERDUE': return AlertType.workOrderOverdue;
      default: return AlertType.maintenanceDue;
    }
  }

  String get displayName {
    switch (this) {
      case AlertType.maintenanceDue: return 'سررسید نگهداری';
      case AlertType.maintenanceOverdue: return 'نگهداری معوق/تأخیر';
      case AlertType.conditionTriggered: return 'شرط بحرانی فعال';
      case AlertType.lowStock: return 'موجودی کم انبار';
      case AlertType.workOrderOverdue: return 'دستورکار معوق';
    }
  }
}

enum AlertSeverity {
  info,
  warning,
  critical;

  String toDbString() {
    switch (this) {
      case AlertSeverity.info: return 'INFO';
      case AlertSeverity.warning: return 'WARNING';
      case AlertSeverity.critical: return 'CRITICAL';
    }
  }

  static AlertSeverity fromDbString(String? value) {
    switch (value) {
      case 'INFO': return AlertSeverity.info;
      case 'WARNING': return AlertSeverity.warning;
      case 'CRITICAL': return AlertSeverity.critical;
      default: return AlertSeverity.warning;
    }
  }

  String get displayName {
    switch (this) {
      case AlertSeverity.info: return 'اطلاعیه';
      case AlertSeverity.warning: return 'هشدار';
      case AlertSeverity.critical: return 'بحرانی';
    }
  }
}

enum AlertStatus {
  active,
  acknowledged,
  resolved,
  dismissed;

  String toDbString() {
    switch (this) {
      case AlertStatus.active: return 'ACTIVE';
      case AlertStatus.acknowledged: return 'ACKNOWLEDGED';
      case AlertStatus.resolved: return 'RESOLVED';
      case AlertStatus.dismissed: return 'DISMISSED';
    }
  }

  static AlertStatus fromDbString(String? value) {
    switch (value) {
      case 'ACTIVE': return AlertStatus.active;
      case 'ACKNOWLEDGED': return AlertStatus.acknowledged;
      case 'RESOLVED': return AlertStatus.resolved;
      case 'DISMISSED': return AlertStatus.dismissed;
      default: return AlertStatus.active;
    }
  }

  String get displayName {
    switch (this) {
      case AlertStatus.active: return 'فعال';
      case AlertStatus.acknowledged: return 'تایید شده';
      case AlertStatus.resolved: return 'برطرف شده';
      case AlertStatus.dismissed: return 'رد شده';
    }
  }
}
