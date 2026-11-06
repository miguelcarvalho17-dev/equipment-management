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
                Caption = 'Last Maintenance Date';
                ToolTip = 'Specifies the date of the most recent maintenance of the equipment. It is blank when no maintenance has been registered.';
            }
            field(LastMaintenanceType; LastMaintenanceType)
            {
                Caption = 'Last Maintenance Type';
                ToolTip = 'Specifies the type of the most recent maintenance of the equipment. It is blank when no maintenance has been registered.';
            }
            field(TotalMaintenanceCost; TotalMaintenanceCost)
            {
                Caption = 'Total Maintenance Cost';
                AutoFormatType = 1;
                ToolTip = 'Specifies the total cost of all maintenance registered for the equipment, in local currency.';
            }
        }
    }

    var
        NoOfMaintenanceRecords: Integer;
        NoOfOpenMaintenanceRecords: Integer;
        LastMaintenanceDate: Date;
        LastMaintenanceType: Text;
        TotalMaintenanceCost: Decimal;

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
        TotalMaintenanceCost := 0;
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
        TotalMaintenanceCost := MaintenanceMgt.GetTotalMaintenanceCost(Rec."No.");
    end;
}
