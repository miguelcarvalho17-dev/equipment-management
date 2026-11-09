namespace MiguelCarvalho.EquipmentManagement;

using System.Environment.Configuration;

/// <summary>
/// Shows Business Central notifications about expiring warranties, overdue maintenance and equipment that is back
/// from maintenance, and handles their actions.
/// </summary>
codeunit 50112 "EQM Notification Mgt."
{
    Access = Internal;

    var
        MaintenanceMgt: Codeunit "EQM Maintenance Mgt.";
        WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
        WarrantyNotificationIdTok: Label '6F3B9C2E-8A41-4D7B-9E15-2C7A0B5D3F01', Locked = true;
        OverdueMaintNotificationIdTok: Label 'A82D4F6B-1C93-4E58-B7A0-5D9E3C1F7A02', Locked = true;
        ReturnedNotificationIdTok: Label 'D14E7A9C-3B65-4F2D-8C1E-9A6F0B2D5E03', Locked = true;
        EquipmentNoDataTok: Label 'EquipmentNo', Locked = true;
        WarrantyExpiresInDaysMsg: Label 'Warranty for %1 %2 will expire in %3 days.', Comment = '%1 = equipment description, or the category code when the description is blank, %2 = equipment number, %3 = number of days until the warranty end date';
        WarrantyExpiresTomorrowMsg: Label 'Warranty for %1 %2 will expire tomorrow.', Comment = '%1 = equipment description, or the category code when the description is blank, %2 = equipment number';
        WarrantyExpiresTodayMsg: Label 'Warranty for %1 %2 expires today.', Comment = '%1 = equipment description, or the category code when the description is blank, %2 = equipment number';
        OpenWarrantyAlertsMsg: Label '%1 warranty alerts are open. Review the warranties that are about to expire.', Comment = '%1 = number of open warranty alerts';
        OneOpenWarrantyAlertMsg: Label '1 warranty alert is open. Review the warranty that is about to expire.';
        EquipmentMaintenanceOverdueMsg: Label 'Maintenance %1 for %2 %3 has been open for %4 days. Post it when the work is finished.', Comment = '%1 = maintenance record number, %2 = equipment description, or the category code when the description is blank, %3 = equipment number, %4 = number of days since the maintenance date';
        MaintenanceRecordOverdueMsg: Label 'Maintenance record %1 has been open for %2 days. Post it when the work is finished.', Comment = '%1 = maintenance record number, %2 = number of days since the maintenance date';
        OverdueMaintenanceSummaryMsg: Label '%1 maintenance records have been open for more than %2 days. Post them when the work is finished.', Comment = '%1 = number of overdue maintenance records, %2 = number of days after which maintenance is overdue';
        OneOverdueMaintenanceMsg: Label '1 maintenance record has been open for more than %1 days. Post it when the work is finished.', Comment = '%1 = number of days after which maintenance is overdue';
        ReturnedFromMaintenanceMsg: Label '%1 %2 is back from maintenance and is available again.', Comment = '%1 = equipment description, or the category code when the description is blank, %2 = equipment number';
        ShowWarrantyAlertsActionLbl: Label 'Show warranty alerts';
        ShowOpenMaintenanceActionLbl: Label 'Show open maintenance';
        ShowOverdueMaintenanceActionLbl: Label 'Show overdue maintenance';
        OpenEquipmentCardActionLbl: Label 'Open equipment card';
        DontShowAgainActionLbl: Label 'Don''t show again';
        WarrantyNotificationNameTxt: Label 'Equipment warranty is expiring';
        WarrantyNotificationDescTxt: Label 'Show a notification when the warranty of equipment will expire soon and its warranty alert is still open.';
        OverdueNotificationNameTxt: Label 'Equipment maintenance is overdue';
        OverdueNotificationDescTxt: Label 'Show a notification when a maintenance record has been open for more than 14 days without being posted.';
        ReturnedNotificationNameTxt: Label 'Equipment returned from maintenance';
        ReturnedNotificationDescTxt: Label 'Show a notification when posting maintenance makes the equipment available again.';

    /// <summary>
    /// Returns the ID of the warranty expiring notification.
    /// </summary>
    /// <returns>The notification ID.</returns>
    internal procedure GetWarrantyNotificationId(): Guid
    var
        NotificationId: Guid;
    begin
        Evaluate(NotificationId, WarrantyNotificationIdTok);
        exit(NotificationId);
    end;

    /// <summary>
    /// Returns the ID of the overdue maintenance notification.
    /// </summary>
    /// <returns>The notification ID.</returns>
    internal procedure GetOverdueMaintenanceNotificationId(): Guid
    var
        NotificationId: Guid;
    begin
        Evaluate(NotificationId, OverdueMaintNotificationIdTok);
        exit(NotificationId);
    end;

    /// <summary>
    /// Returns the ID of the returned from maintenance notification.
    /// </summary>
    /// <returns>The notification ID.</returns>
    internal procedure GetReturnedFromMaintenanceNotificationId(): Guid
    var
        NotificationId: Guid;
    begin
        Evaluate(NotificationId, ReturnedNotificationIdTok);
        exit(NotificationId);
    end;

    /// <summary>
    /// Shows the warranty and overdue maintenance notifications for one piece of equipment and removes those of the
    /// previous record.
    /// </summary>
    /// <param name="Equipment">The equipment that is current on the page.</param>
    internal procedure ShowEquipmentNotifications(Equipment: Record "EQM Equipment")
    begin
        RecallNotification(GetWarrantyNotificationId());
        RecallNotification(GetOverdueMaintenanceNotificationId());
        if not GuiAllowed() then
            exit;
        if Equipment.SystemCreatedAt = 0DT then
            exit;

        SendEquipmentWarrantyNotification(Equipment, Today());
        SendEquipmentOverdueNotification(Equipment, Today());
    end;

    local procedure SendEquipmentWarrantyNotification(Equipment: Record "EQM Equipment"; ReferenceDate: Date)
    var
        Notification: Notification;
        DaysRemaining: Integer;
    begin
        if not IsNotificationEnabled(GetWarrantyNotificationId()) then
            exit;
        if Equipment."Warranty End Date" = 0D then
            exit;
        if Equipment.IsFinalStatus(Equipment.Status) then
            exit;
        DaysRemaining := Equipment.GetWarrantyDaysRemaining(ReferenceDate);
        if DaysRemaining < 0 then
            exit;
        if not WarrantyAlertMgt.HasOpenAlert(Equipment."No.", Equipment."Warranty End Date") then
            exit;

        Notification.Id := GetWarrantyNotificationId();
        Notification.Scope := NotificationScope::LocalScope;
        case DaysRemaining of
            0:
                Notification.Message := StrSubstNo(WarrantyExpiresTodayMsg, GetEquipmentName(Equipment), Equipment."No.");
            1:
                Notification.Message := StrSubstNo(WarrantyExpiresTomorrowMsg, GetEquipmentName(Equipment), Equipment."No.");
            else
                Notification.Message := StrSubstNo(WarrantyExpiresInDaysMsg, GetEquipmentName(Equipment), Equipment."No.", DaysRemaining);
        end;
        Notification.SetData(EquipmentNoDataTok, Equipment."No.");
        Notification.AddAction(ShowWarrantyAlertsActionLbl, Codeunit::"EQM Notification Mgt.", 'ShowWarrantyAlerts');
        Notification.AddAction(DontShowAgainActionLbl, Codeunit::"EQM Notification Mgt.", 'DisableNotification');
        Notification.Send();
    end;

    local procedure SendEquipmentOverdueNotification(Equipment: Record "EQM Equipment"; ReferenceDate: Date)
    var
        MaintenanceRecord: Record "EQM Maintenance Record";
        Notification: Notification;
    begin
        if not IsNotificationEnabled(GetOverdueMaintenanceNotificationId()) then
            exit;
        if not MaintenanceMgt.FindOldestOverdueMaintenance(Equipment."No.", ReferenceDate, MaintenanceRecord) then
            exit;

        Notification.Id := GetOverdueMaintenanceNotificationId();
        Notification.Scope := NotificationScope::LocalScope;
        Notification.Message := StrSubstNo(EquipmentMaintenanceOverdueMsg, MaintenanceRecord."No.", GetEquipmentName(Equipment), Equipment."No.", MaintenanceMgt.CalcDaysOpen(MaintenanceRecord, ReferenceDate));
        Notification.SetData(EquipmentNoDataTok, Equipment."No.");
        Notification.AddAction(ShowOpenMaintenanceActionLbl, Codeunit::"EQM Notification Mgt.", 'ShowOpenMaintenance');
        Notification.AddAction(DontShowAgainActionLbl, Codeunit::"EQM Notification Mgt.", 'DisableNotification');
        Notification.Send();
    end;

    /// <summary>
    /// Shows the overdue notification for one maintenance record and removes the previous one.
    /// </summary>
    /// <param name="MaintenanceRecord">The maintenance record that is current on the page.</param>
    internal procedure ShowMaintenanceRecordNotification(MaintenanceRecord: Record "EQM Maintenance Record")
    var
        Notification: Notification;
    begin
        RecallNotification(GetOverdueMaintenanceNotificationId());
        if not GuiAllowed() then
            exit;
        if MaintenanceRecord.SystemCreatedAt = 0DT then
            exit;
        if not IsNotificationEnabled(GetOverdueMaintenanceNotificationId()) then
            exit;
        if not MaintenanceMgt.IsMaintenanceOverdue(MaintenanceRecord, Today()) then
            exit;

        Notification.Id := GetOverdueMaintenanceNotificationId();
        Notification.Scope := NotificationScope::LocalScope;
        Notification.Message := StrSubstNo(MaintenanceRecordOverdueMsg, MaintenanceRecord."No.", MaintenanceMgt.CalcDaysOpen(MaintenanceRecord, Today()));
        Notification.AddAction(DontShowAgainActionLbl, Codeunit::"EQM Notification Mgt.", 'DisableNotification');
        Notification.Send();
    end;

    /// <summary>
    /// Shows the summary notifications about open warranty alerts and overdue maintenance on the Role Center.
    /// </summary>
    internal procedure ShowRoleCenterNotifications()
    begin
        if not GuiAllowed() then
            exit;

        SendOpenWarrantyAlertsNotification();
        SendOverdueMaintenanceSummaryNotification();
    end;

    local procedure SendOpenWarrantyAlertsNotification()
    var
        Notification: Notification;
        AlertCount: Integer;
    begin
        if not IsNotificationEnabled(GetWarrantyNotificationId()) then
            exit;
        AlertCount := WarrantyAlertMgt.CountOpenAlerts();
        if AlertCount = 0 then
            exit;

        Notification.Id := GetWarrantyNotificationId();
        Notification.Scope := NotificationScope::LocalScope;
        if AlertCount = 1 then
            Notification.Message := OneOpenWarrantyAlertMsg
        else
            Notification.Message := StrSubstNo(OpenWarrantyAlertsMsg, AlertCount);
        Notification.AddAction(ShowWarrantyAlertsActionLbl, Codeunit::"EQM Notification Mgt.", 'ShowWarrantyAlerts');
        Notification.AddAction(DontShowAgainActionLbl, Codeunit::"EQM Notification Mgt.", 'DisableNotification');
        Notification.Send();
    end;

    local procedure SendOverdueMaintenanceSummaryNotification()
    var
        Notification: Notification;
        OverdueCount: Integer;
    begin
        if not IsNotificationEnabled(GetOverdueMaintenanceNotificationId()) then
            exit;
        OverdueCount := MaintenanceMgt.CountOverdueMaintenance(Today());
        if OverdueCount = 0 then
            exit;

        Notification.Id := GetOverdueMaintenanceNotificationId();
        Notification.Scope := NotificationScope::LocalScope;
        if OverdueCount = 1 then
            Notification.Message := StrSubstNo(OneOverdueMaintenanceMsg, MaintenanceMgt.GetMaintenanceOverdueDays())
        else
            Notification.Message := StrSubstNo(OverdueMaintenanceSummaryMsg, OverdueCount, MaintenanceMgt.GetMaintenanceOverdueDays());
        Notification.AddAction(ShowOverdueMaintenanceActionLbl, Codeunit::"EQM Notification Mgt.", 'ShowOverdueMaintenance');
        Notification.AddAction(DontShowAgainActionLbl, Codeunit::"EQM Notification Mgt.", 'DisableNotification');
        Notification.Send();
    end;

    /// <summary>
    /// Shows a notification that the equipment is back from maintenance, when posting changed it from In Maintenance
    /// to Available.
    /// </summary>
    /// <param name="EquipmentNo">The equipment number of the posted maintenance record.</param>
    /// <param name="StatusBeforePosting">The equipment status read before posting.</param>
    internal procedure SendReturnedFromMaintenanceNotification(EquipmentNo: Code[20]; StatusBeforePosting: Enum "EQM Equipment Status")
    var
        Equipment: Record "EQM Equipment";
        Notification: Notification;
    begin
        if not GuiAllowed() then
            exit;
        if not IsNotificationEnabled(GetReturnedFromMaintenanceNotificationId()) then
            exit;
        if StatusBeforePosting <> StatusBeforePosting::"In Maintenance" then
            exit;
        Equipment.SetLoadFields(Description, "Category Code", Status);
        if not Equipment.Get(EquipmentNo) then
            exit;
        if Equipment.Status <> Equipment.Status::Available then
            exit;

        Notification.Id := GetReturnedFromMaintenanceNotificationId();
        Notification.Scope := NotificationScope::LocalScope;
        Notification.Message := StrSubstNo(ReturnedFromMaintenanceMsg, GetEquipmentName(Equipment), EquipmentNo);
        Notification.SetData(EquipmentNoDataTok, EquipmentNo);
        Notification.AddAction(OpenEquipmentCardActionLbl, Codeunit::"EQM Notification Mgt.", 'OpenEquipmentCard');
        Notification.AddAction(DontShowAgainActionLbl, Codeunit::"EQM Notification Mgt.", 'DisableNotification');
        Notification.Send();
    end;

    /// <summary>
    /// Handler of the Show warranty alerts action: opens the open warranty alerts.
    /// </summary>
    /// <param name="Notification">The notification the action belongs to.</param>
    procedure ShowWarrantyAlerts(Notification: Notification)
    begin
        WarrantyAlertMgt.ShowOpenAlerts(GetNotificationEquipmentNo(Notification));
    end;

    /// <summary>
    /// Handler of the Show open maintenance action: opens the open maintenance records of the equipment.
    /// </summary>
    /// <param name="Notification">The notification the action belongs to.</param>
    procedure ShowOpenMaintenance(Notification: Notification)
    begin
        MaintenanceMgt.ShowOpenMaintenanceRecords(GetNotificationEquipmentNo(Notification));
    end;

    /// <summary>
    /// Handler of the Show overdue maintenance action: opens the overdue maintenance records.
    /// </summary>
    /// <param name="Notification">The notification the action belongs to.</param>
    procedure ShowOverdueMaintenance(Notification: Notification)
    begin
        MaintenanceMgt.ShowOverdueMaintenanceRecords(Today());
    end;

    /// <summary>
    /// Handler of the Open equipment card action: opens the card of the equipment in the notification.
    /// </summary>
    /// <param name="Notification">The notification the action belongs to.</param>
    procedure OpenEquipmentCard(Notification: Notification)
    var
        Equipment: Record "EQM Equipment";
    begin
        if Equipment.Get(GetNotificationEquipmentNo(Notification)) then
            Page.Run(Page::"EQM Equipment Card", Equipment);
    end;

    /// <summary>
    /// Handler of the Don't show again action: switches the notification off for the current user.
    /// </summary>
    /// <param name="Notification">The notification the action belongs to.</param>
    procedure DisableNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(Notification.Id) then begin
            RegisterDefaultNotifications();
            MyNotifications.Disable(Notification.Id);
        end;
    end;

    /// <summary>
    /// Returns whether the user has the notification switched on in My Notifications.
    /// </summary>
    /// <param name="NotificationId">The notification ID.</param>
    /// <returns>True when the notification is enabled for the current user.</returns>
    internal procedure IsNotificationEnabled(NotificationId: Guid): Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        exit(MyNotifications.IsEnabled(NotificationId));
    end;

    /// <summary>
    /// Registers the three equipment notifications in My Notifications, switched on by default.
    /// </summary>
    internal procedure RegisterDefaultNotifications()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(GetWarrantyNotificationId(), CopyStr(WarrantyNotificationNameTxt, 1, 128), WarrantyNotificationDescTxt, true);
        MyNotifications.InsertDefault(GetOverdueMaintenanceNotificationId(), CopyStr(OverdueNotificationNameTxt, 1, 128), OverdueNotificationDescTxt, true);
        MyNotifications.InsertDefault(GetReturnedFromMaintenanceNotificationId(), CopyStr(ReturnedNotificationNameTxt, 1, 128), ReturnedNotificationDescTxt, true);
    end;

    local procedure RecallNotification(NotificationId: Guid)
    var
        Notification: Notification;
    begin
        Notification.Id := NotificationId;
        Notification.Recall();
    end;

    local procedure GetEquipmentName(Equipment: Record "EQM Equipment"): Text
    begin
        if Equipment.Description <> '' then
            exit(Equipment.Description);
        exit(Equipment."Category Code");
    end;

    local procedure GetNotificationEquipmentNo(Notification: Notification): Code[20]
    begin
        if Notification.HasData(EquipmentNoDataTok) then
            exit(CopyStr(Notification.GetData(EquipmentNoDataTok), 1, 20));
        exit('');
    end;
}
