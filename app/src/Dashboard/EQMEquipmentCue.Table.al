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
        field(22; "Total Maintenance Cost YTD"; Decimal)
        {
            Caption = 'Total Maintenance Cost YTD';
            ToolTip = 'Specifies the total cost of the maintenance posted with a maintenance date from 1 January of the current year up to and including today, in local currency. Open maintenance records are not included until they are posted. Choose the amount to see the maintenance history.';
            FieldClass = FlowField;
            CalcFormula = sum("EQM Maintenance History Entry".Cost where("Maintenance Date" = field("Maint. Cost YTD Filter")));
            AutoFormatType = 1;
            Editable = false;
        }
        field(23; "Maint. Cost YTD Filter"; Date)
        {
            Caption = 'Maintenance Cost YTD Filter';
            ToolTip = 'Specifies the maintenance dates that count for the year-to-date maintenance cost. It is set automatically.';
            FieldClass = FlowFilter;
        }
        field(30; "Warranty Expiring Soon"; Integer)
        {
            Caption = 'Warranties Expiring in 30 Days';
            ToolTip = 'Specifies the number of equipment records whose warranty ends within the next 30 days, today included. Lost and disposed equipment is not counted.';
            FieldClass = FlowField;
            CalcFormula = count("EQM Equipment" where("Warranty End Date" = field("Warranty Expiring Filter"), Status = filter(<> Lost & <> Disposed)));
            Editable = false;
        }
        field(31; "Warranty Expired"; Integer)
        {
            Caption = 'Expired Warranties';
            ToolTip = 'Specifies the number of equipment records whose warranty end date has passed. Lost and disposed equipment and equipment without a warranty end date are not counted.';
            FieldClass = FlowField;
            CalcFormula = count("EQM Equipment" where("Warranty End Date" = field("Warranty Expired Filter"), Status = filter(<> Lost & <> Disposed)));
            Editable = false;
        }
        field(32; "Open Warranty Alerts"; Integer)
        {
            Caption = 'Open Warranty Alerts';
            ToolTip = 'Specifies the number of warranty alerts that are open. An alert is created 90, 60 and 30 days before a warranty ends. Choose the number to see and acknowledge the alerts.';
            FieldClass = FlowField;
            CalcFormula = count("EQM Warranty Alert" where(Status = const(Open)));
            Editable = false;
        }
        field(33; "Active Warranties"; Integer)
        {
            Caption = 'Active Warranties';
            ToolTip = 'Specifies the number of equipment records whose warranty is still in force: the warranty end date is today or later. Warranties that expire within the next 30 days are included. Lost and disposed equipment and equipment without a warranty end date are not counted. Choose the number to see the equipment.';
            FieldClass = FlowField;
            CalcFormula = count("EQM Equipment" where("Warranty End Date" = field("Active Warranty Filter"), Status = filter(<> Lost & <> Disposed)));
            Editable = false;
        }
        field(34; "Warranties Expiring 90 Days"; Integer)
        {
            Caption = 'Warranties Expiring in 90 Days';
            ToolTip = 'Specifies the number of equipment records whose warranty ends within the next 90 days, today included. Warranties that end within 30 days are included. Lost and disposed equipment is not counted. Choose the number to see the equipment.';
            FieldClass = FlowField;
            CalcFormula = count("EQM Equipment" where("Warranty End Date" = field("Warranty 90 Days Filter"), Status = filter(<> Lost & <> Disposed)));
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
        field(42; "Active Warranty Filter"; Date)
        {
            Caption = 'Active Warranty Filter';
            ToolTip = 'Specifies the warranty end dates that count as active. It is set automatically.';
            FieldClass = FlowFilter;
        }
        field(43; "Warranty 90 Days Filter"; Date)
        {
            Caption = 'Warranty 90 Days Filter';
            ToolTip = 'Specifies the warranty end dates that count as expiring within 90 days. It is set automatically.';
            FieldClass = FlowFilter;
        }
        field(50; "Overdue Maintenance Equipment"; Integer)
        {
            Caption = 'Overdue Maintenance Equipment';
            ToolTip = 'Specifies the number of equipment records whose next maintenance date is before today. Equipment without a next maintenance date and lost or disposed equipment are not counted. Choose the number to see the equipment.';
            FieldClass = FlowField;
            CalcFormula = count("EQM Equipment" where("Next Maintenance Date" = field("Overdue Maintenance Filter"), Status = filter(<> Lost & <> Disposed)));
            Editable = false;
        }
        field(51; "Overdue Maintenance Filter"; Date)
        {
            Caption = 'Overdue Maintenance Filter';
            ToolTip = 'Specifies the next maintenance dates that count as overdue. It is set automatically.';
            FieldClass = FlowFilter;
        }
        field(52; "Planned Maintenance This Month"; Integer)
        {
            Caption = 'Planned Maintenance This Month';
            ToolTip = 'Specifies the number of equipment records whose next maintenance date is in the current month, including dates earlier this month that are already overdue. Lost and disposed equipment is not counted. When preventive maintenance is posted, the next maintenance date moves forward and the equipment is no longer counted. Choose the number to see the equipment.';
            FieldClass = FlowField;
            CalcFormula = count("EQM Equipment" where("Next Maintenance Date" = field("Planned Maint. Month Filter"), Status = filter(<> Lost & <> Disposed)));
            Editable = false;
        }
        field(53; "Planned Maint. Month Filter"; Date)
        {
            Caption = 'Planned Maintenance Month Filter';
            ToolTip = 'Specifies the next maintenance dates that count as planned this month. It is set automatically.';
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
