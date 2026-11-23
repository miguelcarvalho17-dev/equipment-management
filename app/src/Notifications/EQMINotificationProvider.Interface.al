namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Delivers equipment notifications on one channel.
/// </summary>
interface "EQM INotification Provider"
{
    Access = Internal;

    /// <summary>
    /// Delivers the notification described by the payload.
    /// </summary>
    /// <param name="NotificationPayload">The notification content.</param>
    procedure Send(var NotificationPayload: Codeunit "EQM Notification Payload");

    /// <summary>
    /// Removes a notification that was delivered earlier. Does nothing when the channel cannot recall.
    /// </summary>
    /// <param name="NotificationId">The ID of the notification to remove.</param>
    procedure Recall(NotificationId: Guid);
}
