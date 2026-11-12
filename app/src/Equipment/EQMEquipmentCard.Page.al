namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.HumanResources.Employee;
using System.Security.AccessControl;

page 50101 "EQM Equipment Card"
{
    Caption = 'Equipment Card';
    AboutTitle = 'About equipment details';
    AboutText = 'Here you manage one piece of equipment. The first sections show its details, its current status and who it is assigned to, its purchase and warranty information, and its planned maintenance. Use **Assign to Employee** and **Return** to change the assignment, and **Register Maintenance** to record maintenance work. Further down, **Assignment History** lists every assignment, **Maintenance History** lists every posted maintenance, and **Audit** shows who created the record and who changed it last. The **Picture** FactBox shows the picture of the equipment; use its actions to take, import, export or delete it.';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "EQM Equipment";
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("No."; Rec."No.")
                {
                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit() then
                            CurrPage.Update(false);
                    end;
                }
                field(Description; Rec.Description)
                {
                    Importance = Promoted;
                }
                field("Category Code"; Rec."Category Code")
                {
                    Importance = Promoted;
                    ShowMandatory = true;
                }
                field("Serial No."; Rec."Serial No.")
                {
                }
                field(Manufacturer; Rec.Manufacturer)
                {
                }
                field(Model; Rec.Model)
                {
                }
            }
            group(Assignment)
            {
                Caption = 'Assignment';

                field(StatusNew; Rec.Status)
                {
                    ValuesAllowed = Available, "In Maintenance";
                    Importance = Promoted;
                    Visible = IsNewRecord;
                    StyleExpr = StatusStyle;

                    trigger OnValidate()
                    begin
                        UpdateControls();
                    end;
                }
                field(Status; Rec.Status)
                {
                    Importance = Promoted;
                    Visible = IsSaved;
                    StyleExpr = StatusStyle;

                    trigger OnValidate()
                    begin
                        if (Rec.Status = Rec.Status::Assigned) and (xRec.Status <> Rec.Status::Assigned) then
                            Error(UseAssignActionErr);

                        UpdateControls();
                    end;
                }
                field("Assigned Employee No."; Rec."Assigned Employee No.")
                {
                    Editable = false;
                }
                field("Assigned Employee Name"; AssignedEmployeeName)
                {
                    Caption = 'Assigned Employee Name';
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the name of the employee the equipment is assigned to.';
                }
                field(AssignedSince; ActiveAssignmentDate)
                {
                    Caption = 'Assigned Since';
                    Editable = false;
                    ToolTip = 'Specifies the date the equipment was assigned to the current employee. It is blank when the equipment is not assigned.';
                }
                field(AssignedBy; ActiveAssignedBy)
                {
                    Caption = 'Assigned By';
                    Editable = false;
                    ToolTip = 'Specifies the user who assigned the equipment to the current employee. It is blank when the equipment is not assigned.';
                }
                field("Location Code"; Rec."Location Code")
                {
                }
            }
            group(Purchase)
            {
                Caption = 'Purchase';

                field("Purchase Date"; Rec."Purchase Date")
                {
                }
                field("Purchase Cost"; Rec."Purchase Cost")
                {
                }
            }
            group(Warranty)
            {
                Caption = 'Warranty';

                field("Warranty Start Date"; Rec."Warranty Start Date")
                {
                }
                field("Warranty End Date"; Rec."Warranty End Date")
                {
                    Importance = Promoted;

                    trigger OnValidate()
                    begin
                        UpdateWarrantyStatus();
                    end;
                }
                field(WarrantyStatus; WarrantyStatus)
                {
                    Caption = 'Warranty Status';
                    ToolTip = 'Specifies whether the warranty is Active, Expiring Soon (it ends within 30 days) or Expired (the end date has passed). It is calculated from the warranty end date and today''s date, and is blank when no warranty end date is filled in.';
                    Editable = false;
                    Importance = Promoted;
                    StyleExpr = WarrantyStatusStyle;
                }
                field("Warranty Provider"; Rec."Warranty Provider")
                {
                    Importance = Promoted;
                }
                field("Warranty Reference No."; Rec."Warranty Reference No.")
                {
                }
            }
            group(PlannedMaintenance)
            {
                Caption = 'Planned Maintenance';

                field("Last Maintenance Date"; Rec."Last Maintenance Date")
                {
                    trigger OnValidate()
                    begin
                        UpdateNextMaintenanceStyle();
                    end;
                }
                field("Maintenance Frequency (Months)"; Rec."Maintenance Frequency (Months)")
                {
                    Importance = Promoted;

                    trigger OnValidate()
                    begin
                        UpdateNextMaintenanceStyle();
                    end;
                }
                field("Next Maintenance Date"; Rec."Next Maintenance Date")
                {
                    Importance = Promoted;
                    StyleExpr = NextMaintenanceStyle;
                }
            }
            part(AssignmentHistory; "EQM Assignment History Part")
            {
                Caption = 'Assignment History';
                SubPageLink = "Equipment No." = field("No.");
            }
            part(MaintenanceHistory; "EQM Maintenance History Part")
            {
                Caption = 'Maintenance History';
                SubPageLink = "Equipment No." = field("No.");
            }
            group(Audit)
            {
                Caption = 'Audit';

                field(CreatedDate; Rec.SystemCreatedAt)
                {
                    Caption = 'Created Date';
                    Editable = false;
                    ToolTip = 'Specifies when the equipment record was created.';
                }
                field(CreatedBy; CreatedByUserName)
                {
                    Caption = 'Created By';
                    Editable = false;
                    ToolTip = 'Specifies the user who created the equipment record.';
                }
                field(LastModifiedDate; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date';
                    Editable = false;
                    ToolTip = 'Specifies when the equipment record was last modified.';
                }
                field(LastModifiedBy; ModifiedByUserName)
                {
                    Caption = 'Last Modified By';
                    Editable = false;
                    ToolTip = 'Specifies the user who last changed the equipment record.';
                }
            }
        }
        area(FactBoxes)
        {
            part(Picture; "EQM Equipment Picture")
            {
                SubPageLink = "No." = field("No.");
            }
            part(EquipmentFactBox; "EQM Equipment FactBox")
            {
                SubPageLink = "No." = field("No.");
            }
            part(MaintenanceFactBox; "EQM Maintenance FactBox")
            {
                SubPageLink = "No." = field("No.");
            }
            systempart(Links; Links)
            {
                Visible = false;
            }
            systempart(Notes; Notes)
            {
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AssignToEmployee)
            {
                Caption = 'Assign to Employee';
                ToolTip = 'Assign available equipment to an active employee that you select. The assignment is recorded with the work date and your user name. Not available while the equipment has open maintenance.';
                Image = Employee;
                Enabled = CanAssign;

                trigger OnAction()
                var
                    EmployeeNo: Code[20];
                begin
                    if SelectActiveEmployee(EmployeeNo) then begin
                        Rec.AssignEmployee(EmployeeNo);
                        CurrPage.Update(false);
                    end;
                end;
            }
            action(Unassign)
            {
                Caption = 'Return';
                ToolTip = 'Return the equipment from the assigned employee. The status changes to Available and the assignment is closed with the work date and your user name. The assignment stays in the history.';
                Image = Undo;
                Enabled = IsAssigned;

                trigger OnAction()
                begin
                    Rec.UnassignEmployee();
                    CurrPage.Update(false);
                end;
            }
            action(RegisterMaintenance)
            {
                Caption = 'Register Maintenance';
                ToolTip = 'Register maintenance for the equipment. The equipment status changes to In Maintenance, and the equipment cannot be assigned until the maintenance record is posted. Not available for lost or disposed equipment.';
                Image = ServiceLedger;
                Enabled = CanRegisterMaintenance;
                RunObject = page "EQM Maintenance Record Card";
                RunPageLink = "Equipment No." = field("No.");
                RunPageMode = Create;
            }
        }
        area(Navigation)
        {
            group(EquipmentGroup)
            {
                Caption = 'Equipment';
                Image = FixedAssets;

                action(Assignments)
                {
                    Caption = 'Assignments';
                    ToolTip = 'View the assignment history of the equipment.';
                    Image = History;
                    Enabled = IsSaved;
                    ShortCutKey = 'Ctrl+F7';
                    RunObject = page "EQM Equipment Assignments";
                    RunPageLink = "Equipment No." = field("No.");
                }
                action(Maintenance)
                {
                    Caption = 'Maintenance';
                    ToolTip = 'View the maintenance records of the equipment.';
                    Image = MaintenanceRegistrations;
                    Enabled = IsSaved;
                    RunObject = page "EQM Maintenance Records";
                    RunPageLink = "Equipment No." = field("No.");
                }
                action(ShowMaintenanceHistory)
                {
                    Caption = 'Maintenance History';
                    ToolTip = 'View the posted maintenance history of the equipment.';
                    Image = LedgerEntries;
                    Enabled = IsSaved;
                    RunObject = page "EQM Maintenance History";
                    RunPageLink = "Equipment No." = field("No.");
                }
                action(WarrantyAlerts)
                {
                    Caption = 'Warranty Alerts';
                    ToolTip = 'View the warranty alerts of the equipment. An alert is created 90, 60 and 30 days before the warranty ends.';
                    Image = Alerts;
                    Enabled = IsSaved;
                    RunObject = page "EQM Warranty Alerts";
                    RunPageLink = "Equipment No." = field("No.");
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(AssignToEmployee_Promoted; AssignToEmployee)
                {
                }
                actionref(Unassign_Promoted; Unassign)
                {
                }
                actionref(RegisterMaintenance_Promoted; RegisterMaintenance)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Equipment';

                actionref(Assignments_Promoted; Assignments)
                {
                }
                actionref(Maintenance_Promoted; Maintenance)
                {
                }
                actionref(ShowMaintenanceHistory_Promoted; ShowMaintenanceHistory)
                {
                }
                actionref(WarrantyAlerts_Promoted; WarrantyAlerts)
                {
                }
            }
        }
    }

    var
        NotificationMgt: Codeunit "EQM Notification Mgt.";
        NotifiedEquipmentNo: Code[20];
        NotificationsChecked: Boolean;
        AssignedEmployeeName: Text[100];
        IsAssigned: Boolean;
        IsSaved: Boolean;
        IsNewRecord: Boolean;
        CanAssign: Boolean;
        CanRegisterMaintenance: Boolean;
        StatusStyle: Text;
        WarrantyStatus: Enum "EQM Warranty Status";
        WarrantyStatusStyle: Text;
        NextMaintenanceStyle: Text;
        ActiveAssignmentDate: Date;
        ActiveAssignedBy: Code[50];
        CreatedByUserName: Code[50];
        ModifiedByUserName: Code[50];
        UseAssignActionErr: Label 'To assign equipment, use the Assign to Employee action.';

    trigger OnAfterGetRecord()
    begin
        UpdateControls();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        UpdateControls();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if NotificationsChecked and (Rec."No." = NotifiedEquipmentNo) then
            exit;

        NotifiedEquipmentNo := Rec."No.";
        NotificationsChecked := true;
        NotificationMgt.ShowEquipmentNotifications(Rec);
    end;

    local procedure SelectActiveEmployee(var EmployeeNo: Code[20]): Boolean
    var
        Employee: Record Employee;
        EmployeeList: Page "Employee List";
    begin
        Employee.SetRange(Status, Employee.Status::Active);
        Employee.SetRange("Privacy Blocked", false);
        EmployeeList.SetTableView(Employee);
        EmployeeList.LookupMode(true);
        if EmployeeList.RunModal() <> Action::LookupOK then
            exit(false);

        EmployeeList.GetRecord(Employee);
        EmployeeNo := Employee."No.";
        exit(true);
    end;

    local procedure UpdateControls()
    var
        Employee: Record Employee;
        ActiveAssignment: Record "EQM Equipment Assignment";
        AssignmentMgt: Codeunit "EQM Assignment Mgt.";
        MaintenanceMgt: Codeunit "EQM Maintenance Mgt.";
    begin
        IsAssigned := Rec.Status = Rec.Status::Assigned;
        IsSaved := Rec.SystemCreatedAt <> 0DT;
        IsNewRecord := not IsSaved;
        StatusStyle := Rec.GetStatusStyle();
        CanAssign := IsSaved and (Rec.Status = Rec.Status::Available);
        if CanAssign then
            CanAssign := not MaintenanceMgt.HasOpenMaintenance(Rec."No.");
        CanRegisterMaintenance := IsSaved and not Rec.IsFinalStatus(Rec.Status);
        AssignedEmployeeName := '';
        if (Rec."Assigned Employee No." <> '') and Employee.ReadPermission() then begin
            Employee.SetLoadFields("First Name", "Middle Name", "Last Name");
            if Employee.Get(Rec."Assigned Employee No.") then
                AssignedEmployeeName := Employee.FullName();
        end;

        ActiveAssignmentDate := 0D;
        ActiveAssignedBy := '';
        CreatedByUserName := '';
        ModifiedByUserName := '';
        if IsSaved and (Rec.Status = Rec.Status::Assigned) then
            if AssignmentMgt.GetActiveAssignment(Rec."No.", ActiveAssignment) then begin
                ActiveAssignmentDate := ActiveAssignment."Assignment Date";
                ActiveAssignedBy := ActiveAssignment."Assigned By";
            end;
        CreatedByUserName := GetUserName(Rec.SystemCreatedBy);
        ModifiedByUserName := GetUserName(Rec.SystemModifiedBy);
        UpdateWarrantyStatus();
        UpdateNextMaintenanceStyle();
    end;

    local procedure UpdateWarrantyStatus()
    begin
        WarrantyStatus := Rec.GetWarrantyStatus();
        WarrantyStatusStyle := Rec.GetWarrantyStatusStyle(WarrantyStatus);
    end;

    local procedure UpdateNextMaintenanceStyle()
    begin
        NextMaintenanceStyle := Rec.GetNextMaintenanceDateStyle();
    end;

    local procedure GetUserName(UserSecurityId: Guid): Code[50]
    var
        User: Record User;
    begin
        if IsNullGuid(UserSecurityId) then
            exit('');
        if not User.ReadPermission() then
            exit('');
        User.SetLoadFields("User Name");
        if User.Get(UserSecurityId) then
            exit(User."User Name");
        exit('');
    end;
}
