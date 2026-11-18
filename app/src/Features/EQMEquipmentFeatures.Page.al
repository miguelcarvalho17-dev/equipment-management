namespace MiguelCarvalho.EquipmentManagement;

page 50140 "EQM Equipment Features"
{
    Caption = 'Equipment Features';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    AdditionalSearchTerms = 'feature management, feature activation, turn on equipment features, turn off equipment features, enable features, disable features';
    AboutTitle = 'About equipment features';
    AboutText = 'Turn the optional parts of Equipment Management on or off for this company: equipment images, warranty alerts, approval workflows, API integration and maintenance planning. When a feature is off, its pages, fields, actions and tiles are hidden, and pages that belong only to that feature show an error when they are opened. No data is deleted, and turning the feature on again shows everything as before. Users see a change the next time they open a page.';
    SourceTable = "EQM Feature Setup";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Features)
            {
                field(Feature; Rec.Feature)
                {
                    Editable = false;
                }
                field(Description; FeatureDescription)
                {
                    Caption = 'Description';
                    ToolTip = 'Specifies what the feature shows and what happens when it is turned off.';
                    Editable = false;
                }
                field(Enabled; Rec.Enabled)
                {
                }
            }
        }
    }

    var
        FeatureMgt: Codeunit "EQM Feature Mgt.";
        FeatureDescription: Text;

    trigger OnOpenPage()
    begin
        if Rec.WritePermission() then
            FeatureMgt.InitializeFeatures()
        else
            CurrPage.Editable := false;
    end;

    trigger OnAfterGetRecord()
    begin
        FeatureDescription := FeatureMgt.GetFeatureDescription(Rec.Feature);
    end;
}
