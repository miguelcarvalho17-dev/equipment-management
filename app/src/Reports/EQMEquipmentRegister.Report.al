namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.HumanResources.Employee;

report 50100 "EQM Equipment Register"
{
    Caption = 'Equipment Register';
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;
    AdditionalSearchTerms = 'equipment inventory, asset register, equipment report';
    DefaultRenderingLayout = EquipmentRegisterExcel;

    dataset
    {
        dataitem(Equipment; "EQM Equipment")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "Category Code", Status, "Assigned Employee No.", "Purchase Date";

            column(EquipmentNo; "No.")
            {
                IncludeCaption = true;
            }
            column(Description; Description)
            {
                IncludeCaption = true;
            }
            column(CategoryCode; "Category Code")
            {
                IncludeCaption = true;
            }
            column(CategoryDescription; CategoryDescription)
            {
            }
            column(SerialNo; "Serial No.")
            {
                IncludeCaption = true;
            }
            column(Manufacturer; Manufacturer)
            {
                IncludeCaption = true;
            }
            column(Model; Model)
            {
                IncludeCaption = true;
            }
            column(Status; Status)
            {
                IncludeCaption = true;
            }
            column(AssignedEmployeeNo; "Assigned Employee No.")
            {
                IncludeCaption = true;
            }
            column(AssignedEmployeeName; AssignedEmployeeName)
            {
            }
            column(LocationCode; "Location Code")
            {
                IncludeCaption = true;
            }
            column(PurchaseDate; "Purchase Date")
            {
                IncludeCaption = true;
            }
            column(PurchaseCost; "Purchase Cost")
            {
                IncludeCaption = true;
            }
            column(WarrantyEndDate; "Warranty End Date")
            {
                IncludeCaption = true;
            }

            trigger OnAfterGetRecord()
            begin
                CategoryDescription := GetCategoryDescription(Equipment."Category Code");
                AssignedEmployeeName := GetEmployeeName(Equipment."Assigned Employee No.");
            end;
        }
    }

    rendering
    {
        layout(EquipmentRegisterExcel)
        {
            Type = Excel;
            LayoutFile = './src/Reports/Layouts/EQMEquipmentRegister.xlsx';
            Caption = 'Equipment Register (Excel)';
            Summary = 'Lists the equipment that matches your filters, one row per equipment, in an Excel workbook that you can sort, filter and total.';
        }
    }

    var
        CategoryDescriptions: Dictionary of [Code[20], Text];
        EmployeeNames: Dictionary of [Code[20], Text];
        CategoryDescription: Text;
        AssignedEmployeeName: Text;

    /// <summary>
    /// Returns the description of an equipment category. Each code is read once per run.
    /// </summary>
    /// <param name="CategoryCode">The category code. A blank code gives a blank description.</param>
    /// <returns>The category description, or blank when the category does not exist.</returns>
    local procedure GetCategoryDescription(CategoryCode: Code[20]): Text
    var
        EquipmentCategory: Record "EQM Equipment Category";
        Value: Text;
    begin
        if CategoryCode = '' then
            exit('');
        if CategoryDescriptions.Get(CategoryCode, Value) then
            exit(Value);

        EquipmentCategory.SetLoadFields(Description);
        if EquipmentCategory.Get(CategoryCode) then
            Value := EquipmentCategory.Description;
        CategoryDescriptions.Add(CategoryCode, Value);
        exit(Value);
    end;

    /// <summary>
    /// Returns the full name of an employee. Each code is read once per run.
    /// </summary>
    /// <param name="EmployeeNo">The employee number. A blank number gives a blank name.</param>
    /// <returns>The employee name, or blank when the user cannot read employees or the employee does not exist.</returns>
    local procedure GetEmployeeName(EmployeeNo: Code[20]): Text
    var
        Employee: Record Employee;
        Value: Text;
    begin
        if EmployeeNo = '' then
            exit('');
        if EmployeeNames.Get(EmployeeNo, Value) then
            exit(Value);

        if Employee.ReadPermission() then begin
            Employee.SetLoadFields("First Name", "Middle Name", "Last Name");
            if Employee.Get(EmployeeNo) then
                Value := Employee.FullName();
        end;
        EmployeeNames.Add(EmployeeNo, Value);
        exit(Value);
    end;
}
