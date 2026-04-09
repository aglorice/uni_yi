class GymFilterOption {
  const GymFilterOption({
    required this.id,
    required this.label,
    this.controlName,
    this.caption,
    this.builder,
    this.builderList,
    this.url,
  });

  final String id;
  final String label;
  final String? controlName;
  final String? caption;
  final String? builder;
  final String? builderList;
  final String? url;

  GymFilterOption copyWith({
    String? id,
    String? label,
    String? controlName,
    String? caption,
    String? builder,
    String? builderList,
    String? url,
  }) {
    return GymFilterOption(
      id: id ?? this.id,
      label: label ?? this.label,
      controlName: controlName ?? this.controlName,
      caption: caption ?? this.caption,
      builder: builder ?? this.builder,
      builderList: builderList ?? this.builderList,
      url: url ?? this.url,
    );
  }
}

class GymSearchControl {
  const GymSearchControl({
    required this.name,
    required this.caption,
    required this.options,
    this.defaultBuilder,
    this.builderList,
    this.url,
  });

  final String name;
  final String caption;
  final String? defaultBuilder;
  final String? builderList;
  final String? url;
  final List<GymFilterOption> options;
}

class GymSearchModel {
  const GymSearchModel({
    required this.controls,
    required this.venueTypes,
    required this.sports,
  });

  final List<GymSearchControl> controls;
  final List<GymFilterOption> venueTypes;
  final List<GymFilterOption> sports;

  GymSearchControl? controlByName(String name) {
    for (final control in controls) {
      if (control.name == name) {
        return control;
      }
    }
    for (final control in controls) {
      if (control.name.contains(name)) {
        return control;
      }
    }
    return null;
  }

  GymSearchControl? get venueTypeControl => controlByName('HYSLX');

  GymSearchControl? get sportControl => controlByName('GLBM');
}
