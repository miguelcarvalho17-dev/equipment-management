namespace MiguelCarvalho.EquipmentManagement;

enum 50108 "EQM Attachment Category"
{
    Extensible = true;
    Caption = 'Attachment Category';

    value(0; Other)
    {
        Caption = 'Other';
    }
    value(1; "Purchase Invoice")
    {
        Caption = 'Purchase Invoice';
    }
    value(2; "Maintenance Report")
    {
        Caption = 'Maintenance Report';
    }
    value(3; "Warranty Certificate")
    {
        Caption = 'Warranty Certificate';
    }
    value(4; "User Manual")
    {
        Caption = 'User Manual';
    }
    value(5; "Delivery Note")
    {
        Caption = 'Delivery Note';
    }
}
