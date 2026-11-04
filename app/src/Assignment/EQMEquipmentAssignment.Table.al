namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.HumanResources.Employee;
using System.Security.AccessControl;

/// <summary>
/// One entry per assignment of equipment to an employee. Entries are created and closed by the app when
/// equipment is assigned and returned; users cannot edit them. Closed entries are deleted together with their equipment.
/// </summary>
table 50103 "EQM Equipment Assignment"
{
    Caption = 'Equipment Assignment';
    DataClassification = CustomerContent;
    Access = Public;
    LookupPageId = "EQM Equipment Assignments";
    DrillDownPageId = "EQM Equipment Assignments";
    DataCaptionFields = "Equipment No.", "Employee No.";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the assignment entry.';
            AutoIncrement = true;
        }
        field(2; "Equipment No."; Code[20])
        {
            Caption = 'Equipment No.';
            ToolTip = 'Specifies the equipment that was assigned.';
            TableRelation = "EQM Equipment"."No.";
            NotBlank = true;
        }
        field(3; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            ToolTip = 'Specifies the employee the equipment was assigned to.';
            TableRelation = Employee."No.";
            NotBlank = true;
        }
        field(4; "Assignment Date"; Date)
        {
            Caption = 'Assignment Date';
            ToolTip = 'Specifies the date the equipment was assigned. It is the work date of the user who assigned it.';
        }
        field(5; "Assigned By"; Code[50])
        {
            Caption = 'Assigned By';
            ToolTip = 'Specifies the user who assigned the equipment.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(6; Status; Enum "EQM Assignment Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies whether the assignment is active or closed. Equipment has at most one active assignment. The assignment is closed when the equipment is returned or its status changes from Assigned to another status. Closed assignments are kept as history.';
            InitValue = Active;
        }
        field(7; "Closing Date"; Date)
        {
            Caption = 'Closing Date';
            ToolTip = 'Specifies the date the assignment was closed. It is the work date of the user who closed it.';
        }
        field(8; "Closed By"; Code[50])
        {
            Caption = 'Closed By';
            ToolTip = 'Specifies the user who closed the assignment.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(9; "Equipment Description"; Text[100])
        {
            Caption = 'Equipment Description';
            ToolTip = 'Specifies the description of the equipment.';
            FieldClass = FlowField;
            CalcFormula = lookup("EQM Equipment".Description where("No." = field("Equipment No.")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(EquipmentStatus; "Equipment No.", Status)
        {
        }
        key(EmployeeStatus; "Employee No.", Status)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Equipment No.", "Employee No.", "Assignment Date", Status)
        {
        }
    }
}
