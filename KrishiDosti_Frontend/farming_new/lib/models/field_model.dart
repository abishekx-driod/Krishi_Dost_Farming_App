class FieldModel {
  String id;
  String name;
  String? crop;
  double? size;
  String? location;

  double? latitude;
  double? longitude;

  String? sowingDate;
  String? irrigationType;
  String? fertilizerType;

  FieldModel({
    required this.id,
    required this.name,
    this.crop,
    this.size,
    this.location,
    this.latitude,
    this.longitude,
    this.sowingDate,
    this.irrigationType,
    this.fertilizerType,
  });

  Map<String, dynamic> toJson() => {
        "name": name,
        "crop": crop,
        "size": size,
        "location": location,
        "latitude": latitude,
        "longitude": longitude,
        "sowingDate": sowingDate,
        "irrigationType": irrigationType,
        "fertilizerType": fertilizerType,
      };

  static FieldModel fromJson(String id, Map<String, dynamic> json) {
    return FieldModel(
      id: id,
      name: json["name"] ?? "",
      crop: json["crop"],
      size: (json["size"] ?? 0).toDouble(),
      location: json["location"],
      latitude: json["latitude"],
      longitude: json["longitude"],
      sowingDate: json["sowingDate"],
      irrigationType: json["irrigationType"],
      fertilizerType: json["fertilizerType"],
    );
  }
}
