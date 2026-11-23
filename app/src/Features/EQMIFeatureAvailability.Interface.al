namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Tells whether an optional equipment feature is turned on. Business logic asks through this interface so tests and
/// later sources can replace the answer.
/// </summary>
interface "EQM IFeature Availability"
{
    Access = Internal;

    /// <summary>
    /// Returns whether the feature is turned on.
    /// </summary>
    /// <param name="Feature">The feature.</param>
    /// <returns>True when the feature is turned on.</returns>
    procedure IsEnabled(Feature: Enum "EQM Feature"): Boolean;
}
