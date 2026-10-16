enum AccessMode {
  fullAccess,
  readOnly,
  trialNotStarted;

  bool get allowsWrite => this == AccessMode.fullAccess;
}

enum AccessOperation {
  read,
  write,
}

