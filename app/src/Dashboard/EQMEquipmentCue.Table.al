namespace MiguelCarvalho.EquipmentManagement;

table 50104 "EQM Equipment Cue"
{
    Caption = 'Equipment Cue';
    DataClassification = CustomerContent;
    TableType = Temporary;
    Access = Internal;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(10; "Total Equipment"; Integer)
        {
            Caption = 'Total Equipment';
            ToolTip = 'Specifies the number of equipment records, whatever their status.';
            FieldClass = FlowField;
            CalcFormula = count("EQM Equipment");
            Editable = false;
        }
        field(11; "Available Equipment"; Integer)
        {
            Caption = 'Available Equipment';
            ToolTip = 'Specifies the number of equipment records that are available for assignment.';
            FieldClass = FlowField;
            CalcFormula = count("EQM Equipment" where(Status = const(Available)));
            Editable = false;
        }
        field(12; "Assigned Equipment"; Integer)
        {
            Caption = 'Assigned Equipment';
            ToolTip = 'Specifies the number of equipment records that are assigned to an employee.';
            FieldClass = FlowField;
            CalcFormula = count("EQM Equipment" where(Status = const(Assigned)));
            Editable = false;
        }
        field(13; "Equipment in Maintenance"; Integer)
        {
            Caption = 'Equipment in Maintenance';
            ToolTip = 'Specifies the number of equipment records that are in maintenance.';
            FieldClass = FlowField;
            CalcFormula = count("EQM Equipment" where(Status = const("In Maintenance")));
            Editable = false;
        }
        field(14; "Lost Equipment"; Integer)
        {
            Caption = 'Lost Equipment';
            ToolTip = 'Specifies the number of equipment records that are lost.';
            FieldClass = FlowField;
            CalcFormula = count("EQM Equipment" where(Status = const(Lost)));
            Editable = false;
        }
        field(15; "Disposed Equipment"; Integer)
        {
            Caption = 'Disposed Equipment';
            ToolTip = 'Specifies the number of equipment records that are disposed of.';
            FieldClass = FlowField;
            CalcFormula = count("EQM Equipment" where(Status = const(Disposed)));
            Editable = false;
        }
        field(20; "Total Maintenance Cost"; Decimal)
        {
            Caption = 'Total Maintenance Cost';
            ToolTip = 'Specifies the total cost of all posted maintenance, in local currency.';
            FieldClass = FlowField;
            CalcFormula = sum("EQM Maintenance History Entry".Cost);
            AutoFormatType = 1;
            Editable = false;
        }
        field(21; "Average Maintenance Cost"; Decimal)
        {
            Caption = 'Average Maintenance Cost';
            ToolTip = 'Specifies the average cost of one posted maintenance, in local currency. Maintenance with a cost of zero is included.';
            FieldClass = FlowField;
            CalcFormula = average("EQM Maintenance History Entry".Cost);
            AutoFormatType = 1;
            Editable = false;
        }
        field(30; "Warranty Expiring Soon"; Integer)
        {
            Caption = 'Warranty Expiring Soon';
            ToolTip = 'Specifies the number of equipment records whose warranty ends within the next 30 days, today included. Lost and disposed equipment is not counted.';
            FieldClass = FlowField;
            CalcFormula = count("EQM Equipment" where("Warranty End Date" = field("Warranty Expiring Filter"), Status = filter(<> Lost & <> Disposed)));
            Editable = false;
        }
        field(31; "Warranty Expired"; Integer)
        {
            Caption = 'Warranty Expired';
            ToolTip = 'Specifies the number of equipment records whose warranty end date has passed. Lost and disposed equipment and equipment without a warranty end date are not counted.';
            FieldClass = FlowField;
            CalcFormula = count("EQM Equipment" where("Warranty End Date" = field("Warranty Expired Filter"), Status = filter(<> Lost & <> Disposed)));
            Editable = false;
        }
        field(40; "Warranty Expiring Filter"; Date)
        {
            Caption = 'Warranty Expiring Filter';
            ToolTip = 'Specifies the warranty end dates that count as expiring soon. It is set automatically.';
            FieldClass = FlowFilter;
        }
        field(41; "Warranty Expired Filter"; Date)
        {
            Caption = 'Warranty Expired Filter';
            ToolTip = 'Specifies the warranty end dates that count as expired. It is set automatically.';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
