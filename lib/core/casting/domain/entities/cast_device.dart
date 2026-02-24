enum CastDeviceType { googleCast, dlna, androidTv }

class CastDevice {
  final String id;
  final String name;
  final String? model;
  final String? ip;
  final CastDeviceType type;
  final dynamic originalDevice;

  CastDevice({
    required this.id,
    required this.name,
    this.model,
    this.ip,
    required this.type,
    this.originalDevice,
  });
}
