namespace MiguelCarvalho.EquipmentManagement;

page 50115 "EQM Maintenance FactBox"
{
    Caption = 'Maintenance';
    PageType = CardPart;
    ApplicationArea = All;
    SourceTable = "EQM Equipment";
    Editable = false;

    layout
    {
        area(Content)
        {
            field(NoOfMaintenanceRecords; NoOfMaintenanceRecords)
            {
                Caption = 'No. of Maintenance Records';
                ToolTip = 'Specifies how many maintenance records the equipment has. Choose the number to see them.';

                trigger OnDrillDown()
                var
                    MaintenanceMgt: Codeunit "EQM Maintenance Mgt.";
                begin
                    MaintenanceMgt.ShowMaintenanceRecords(Rec."No.");
                end;
            }
            field(NoOfOpenMaintenanceRecords; NoOfOpenMaintenanceRecords)
            {
                Caption = 'Open Maintenance Records';
                ToolTip = 'Specifies how many maintenance records of the equipment are open. While a record is open, the equipment cannot be assigned. Choose the number to see them.';

                trigger OnDrillDown()
                var
                    MaintenanceMgt: Codeunit "EQM Maintenance Mgt.";
                begin
                    MaintenanceMgt.ShowOpenMaintenanceRecords(Rec."No.");
                end;
            }
            field(LastMaintenanceDate; LastMaintenanceDate)
            {
                Caption = 'Latest Record Date';
                ToolTip = 'Specifies the date of the most recent maintenance record of the equipment, of any type, open or posted. It is blank when no maintenance has been registered.';
            }
            field(LastMaintenanceType; LastMaintenanceType)
            {
                Caption = 'Latest Record Type';
                ToolTip = 'Specifies the type of the most recent maintenance record of the equipment. It is blank when no maintenance has been registered.';
            }
            field("Next Maintenance Date"; Rec."Next Maintenance Date")
            {
            }
            field(TotalMaintenanceCost; Rec."Total Maintenance Cost")
            {
            }
            field(AverageMaintenanceCost; Rec."Average Maintenance Cost")
            {
            }
            field(MaintenanceCostPct; MaintenanceCostPct)
            {
                Caption = 'Maintenance Cost %';
                ToolTip = 'Specifies the total posted maintenance cost as a percentage of the purchase cost. A value of 100 or more means that maintenance has cost as much as the equipment itself, which may justify replacing it. It is blank when the equipment has no purchase cost or no posted maintenance.';
                DecimalPlaces = 0 : 1;
                BlankZero = true;
                StyleExpr = MaintenanceCostStyle;
            }
        }
    }

    var
        NoOfMaintenanceRecords: Integer;
        NoOfOpenMaintenanceRecords: Integer;
        LastMaintenanceDate: Date;
        LastMaintenanceType: Text;
        MaintenanceCostPct: Decimal;
        MaintenanceCostStyle: Text;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        ClearFactBox();
        exit(Rec.Find(Which));
    end;

    trigger OnAfterGetRecord()
    begin
        ClearFactBox();
        UpdateFactBox();
    end;

    local procedure ClearFactBox()
    begin
        NoOfMaintenanceRecords := 0;
        NoOfOpenMaintenanceRecords := 0;
        LastMaintenanceDate := 0D;
        LastMaintenanceType := '';
        MaintenanceCostPct := 0;
        MaintenanceCostStyle := '';
    end;

    local procedure UpdateFactBox()
    var
        MaintenanceRecord: Record "EQM Maintenance Record";
        MaintenanceMgt: Codeunit "EQM Maintenance Mgt.";
    begin
        if Rec."No." = '' then
            exit;

        NoOfMaintenanceRecords := MaintenanceMgt.CountMaintenanceRecords(Rec."No.");
        if NoOfMaintenanceRecords = 0 then
            exit;

        NoOfOpenMaintenanceRecords := MaintenanceMgt.CountOpenMaintenanceRecords(Rec."No.");

        if MaintenanceMgt.GetLastMaintenanceRecord(Rec."No.", MaintenanceRecord) then begin
            LastMaintenanceDate := MaintenanceRecord."Maintenance Date";
            LastMaintenanceType := Format(MaintenanceRecord."Maintenance Type");
        end;
        MaintenanceCostPct := Rec.GetMaintenanceCostPercentage();
        MaintenanceCostStyle := Rec.GetMaintenanceCostStyle(MaintenanceCostPct);
    end;
}
