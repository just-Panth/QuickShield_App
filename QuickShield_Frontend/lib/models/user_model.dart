/// Data model for user authentication credentials.
class UserData {
  String? userId;
  String? phoneNumber;
  String? email;
  String? passwordHash;

  UserData({
    this.userId,
    this.phoneNumber,
    this.email,
    this.passwordHash,
  });

  UserData copyWith({
    String? userId,
    String? phoneNumber,
    String? email,
    String? passwordHash,
  }) {
    return UserData(
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
    );
  }
}

/// Data model for user work profile and location.
class UserProfile {
  String? workerId;
  String? storeId;
  String? storeName;
  String? state;
  String? city;
  String? area;
  double? latitude;
  double? longitude;

  UserProfile({
    this.workerId,
    this.storeId,
    this.storeName,
    this.state,
    this.city,
    this.area,
    this.latitude,
    this.longitude,
  });

  UserProfile copyWith({
    String? workerId,
    String? storeId,
    String? storeName,
    String? state,
    String? city,
    String? area,
    double? latitude,
    double? longitude,
  }) {
    return UserProfile(
      workerId: workerId ?? this.workerId,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      state: state ?? this.state,
      city: city ?? this.city,
      area: area ?? this.area,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
