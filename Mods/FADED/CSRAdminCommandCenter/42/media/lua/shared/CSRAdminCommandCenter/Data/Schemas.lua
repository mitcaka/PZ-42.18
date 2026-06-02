require "CSRAdminCommandCenter/ACC_Main"

local ACC = CSRAdminCommandCenter
ACC.Schemas = ACC.Schemas or {}

ACC.Schemas.Keys = {
    Root = "CSR_ACC_Root",
    DebugState = "CSR_ACC_DebugState",
    SettingsState = "CSR_ACC_SettingsState",
    ClaimState = "CSR_ACC_ClaimState",
    JournalState = "CSR_ACC_JournalState",
    VehicleClaimAuthorityState = "CSR_ACC_VehicleClaimAuthorityState",
    VehiclePositions = "CSR_ACC_VehiclePositions",
    PlayerState = "CSR_ACC_PlayerState",
    PadlockState = "CSR_ACC_PadlockState",
    ClaimHistoryTail = "CSR_ACC_ClaimHistoryTail",
    JournalHistoryTail = "CSR_ACC_JournalHistoryTail",
    AuthorityHistoryTail = "CSR_ACC_AuthorityHistoryTail",
    MovementHistoryTail = "CSR_ACC_MovementHistoryTail",
    PadlockHistoryTail = "CSR_ACC_PadlockHistoryTail",
    CleanupHistoryTail = "CSR_ACC_CleanupHistoryTail",
    AccessHistoryTail = "CSR_ACC_AccessHistoryTail",
    SettingsHistoryTail = "CSR_ACC_SettingsHistoryTail",
}

ACC.Schemas.LogFiles = {
    claims = "csr_acc_claims.log",
    journal = "csr_acc_journal.log",
    authority = "csr_acc_vehicle_claim_authority.log",
    movement = "csr_acc_vehicle_movement.log",
    padlocks = "csr_acc_padlocks.log",
    cleanup = "csr_acc_cleanup.log",
    debug = "csr_acc_debug.log",
    access = "csr_acc_access.log",
    settings = "csr_acc_settings.log",
    export = "csr_acc_export.log",
}

return ACC.Schemas
