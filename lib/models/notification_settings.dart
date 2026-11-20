class NotificationSettings {
  final bool enabled;
  final bool showNext;
  final int remindMinutes;

  const NotificationSettings({
    this.enabled = false,
    this.showNext = true,
    this.remindMinutes = 0,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      NotificationSettings(
        enabled: json['enabled'] as bool? ?? false,
        showNext: json['showNext'] as bool? ?? true,
        remindMinutes: (json['remindMinutes'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'showNext': showNext,
        'remindMinutes': remindMinutes,
      };

  NotificationSettings copyWith({
    bool? enabled,
    bool? showNext,
    int? remindMinutes,
  }) =>
      NotificationSettings(
        enabled: enabled ?? this.enabled,
        showNext: showNext ?? this.showNext,
        remindMinutes: remindMinutes ?? this.remindMinutes,
      );
}