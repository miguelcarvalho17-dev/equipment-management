namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Feature activation: tells whether an optional feature is turned on in the current company. A feature without a
/// row in "EQM Feature Setup" is enabled, so nothing changes until an administrator turns a feature off.
/// </summary>
codeunit 50138 "EQM Feature Mgt."
{
    Access = Internal;

    var
        FeatureDisabledErr: Label 'The %1 feature is turned off in this company. To use it, ask an administrator to turn it on in the Equipment Features page.', Comment = '%1 = feature name, for example Warranty Alerts';
        OpenFeaturesLbl: Label 'Open Equipment Features';
        OpenFeaturesDescLbl: Label 'Open the page where administrators turn equipment features on or off.';
        EquipmentImagesDescTxt: Label 'Shows the Picture FactBox on the equipment card and list, where users take, import, export and delete equipment pictures. Pictures that are already stored are kept when the feature is off.';
        WarrantyAlertsDescTxt: Label 'Shows the Warranty Alerts page, its actions, tile and notifications, and lets the daily job create warranty alerts. Warranty dates and the warranty status stay visible when the feature is off.';
        ApprovalWorkflowsDescTxt: Label 'Shows the equipment request process: the Equipment Requests pages, the approval actions and the Requests Pending Approval tile. Requests must be approved before equipment is assigned, so the requests are hidden when the feature is off.';
        ApiIntegrationDescTxt: Label 'Lets external systems use the equipment APIs and shows the integration event settings and entries. When the feature is off, the APIs return an error and no integration event entries are written.';
        MaintenancePlanningDescTxt: Label 'Shows the planned maintenance fields (last maintenance date, maintenance frequency and next maintenance date) and the planned maintenance tiles. The next maintenance date is still calculated when the feature is off.';

    /// <summary>Returns whether the feature is turned on in the current company.</summary>
    /// <param name="Feature">The feature.</param>
    /// <returns>True when the feature has no setup row, when its row is enabled, or when the user cannot read the setup.</returns>
    internal procedure IsEnabled(Feature: Enum "EQM Feature"): Boolean
    var
        FeatureSetup: Record "EQM Feature Setup";
    begin
        // Fail open: feature activation hides UI; it is not a security boundary (permissions are)
        if not FeatureSetup.ReadPermission() then
            exit(true);
        FeatureSetup.SetLoadFields(Enabled);
        if not FeatureSetup.Get(Feature) then
            exit(true);
        exit(FeatureSetup.Enabled);
    end;

    /// <summary>Raises an actionable error when the feature is turned off.</summary>
    /// <param name="Feature">The feature.</param>
    internal procedure CheckEnabled(Feature: Enum "EQM Feature")
    var
        FeatureDisabledError: ErrorInfo;
    begin
        if IsEnabled(Feature) then
            exit;
        FeatureDisabledError.Message(StrSubstNo(FeatureDisabledErr, Format(Feature)));
        FeatureDisabledError.PageNo(Page::"EQM Equipment Features");
        FeatureDisabledError.AddNavigationAction(OpenFeaturesLbl, OpenFeaturesDescLbl);
        Error(FeatureDisabledError);
    end;

    /// <summary>Creates the missing setup rows, one per feature, enabled. Existing rows are not changed.</summary>
    internal procedure InitializeFeatures()
    var
        FeatureSetup: Record "EQM Feature Setup";
        Ordinal: Integer;
    begin
        foreach Ordinal in Enum::"EQM Feature".Ordinals() do
            if not FeatureSetup.Get(Enum::"EQM Feature".FromInteger(Ordinal)) then begin
                FeatureSetup.Init();
                FeatureSetup.Feature := Enum::"EQM Feature".FromInteger(Ordinal);
                FeatureSetup.Enabled := true;
                FeatureSetup.Insert(true);
            end;
    end;

    /// <summary>Turns a feature on or off, creating its setup row when needed.</summary>
    /// <param name="Feature">The feature.</param>
    /// <param name="NewEnabled">True to turn the feature on.</param>
    internal procedure SetFeatureEnabled(Feature: Enum "EQM Feature"; NewEnabled: Boolean)
    var
        FeatureSetup: Record "EQM Feature Setup";
    begin
        if not FeatureSetup.Get(Feature) then begin
            FeatureSetup.Init();
            FeatureSetup.Feature := Feature;
            FeatureSetup.Enabled := NewEnabled;
            FeatureSetup.Insert(true);
            exit;
        end;
        if FeatureSetup.Enabled = NewEnabled then
            exit;
        FeatureSetup.Enabled := NewEnabled;
        FeatureSetup.Modify(true);
    end;

    /// <summary>Returns the description of what the feature shows and what happens when it is off.</summary>
    /// <param name="Feature">The feature.</param>
    /// <returns>The description.</returns>
    internal procedure GetFeatureDescription(Feature: Enum "EQM Feature"): Text
    begin
        case Feature of
            Feature::"Equipment Images":
                exit(EquipmentImagesDescTxt);
            Feature::"Warranty Alerts":
                exit(WarrantyAlertsDescTxt);
            Feature::"Approval Workflows":
                exit(ApprovalWorkflowsDescTxt);
            Feature::"API Integration":
                exit(ApiIntegrationDescTxt);
            Feature::"Maintenance Planning":
                exit(MaintenancePlanningDescTxt);
        end;
        exit('');
    end;
}
