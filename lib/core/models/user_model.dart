class UserModel {
  final int? id;
  final String? email;
  final String? name;
  final String? about;
  final String? goal;
  final String? profilePic;
  final String? country;
  final String? countryCode;
  final String? mobileNumber;
  final String? linkedin;
  final String? facebook;
  final String? instagram;
  final bool? isAdmin;
  final String? token;
  final String? role;
  final bool? isPremium;
  final String? premiumSince;
  final String? premiumExpiry;

  UserModel({
    this.id,
    this.email,
    this.name,
    this.about,
    this.goal,
    this.profilePic,
    this.country,
    this.countryCode,
    this.mobileNumber,
    this.linkedin,
    this.facebook,
    this.instagram,
    this.isAdmin,
    this.token,
    this.role,
    this.isPremium,
    this.premiumSince,
    this.premiumExpiry,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int?,
      email: json['email'] as String?,
      name: json['name'] as String?,
      about: json['about'] as String?,
      goal: json['goal'] as String?,
      profilePic: json['profile_pic'] as String?,
      country: json['country'] as String?,
      countryCode: json['country_code'] as String?,
      mobileNumber: json['mobile_number'] as String?,
      linkedin: json['linkedin'] as String?,
      facebook: json['facebook'] as String?,
      instagram: json['instagram'] as String?,
      isAdmin: json['is_admin'] as bool?,
      token: json['token'] as String?,
      role: json['role'] as String?,
      isPremium: json['isPremium'] as bool?,
      premiumSince: json['premiumSince'] as String?,
      premiumExpiry: json['premiumExpiry'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'about': about,
      'goal': goal,
      'profile_pic': profilePic,
      'country': country,
      'country_code': countryCode,
      'mobile_number': mobileNumber,
      'linkedin': linkedin,
      'facebook': facebook,
      'instagram': instagram,
      'is_admin': isAdmin,
      'token': token,
      'role': role,
      'isPremium': isPremium,
      'premiumSince': premiumSince,
      'premiumExpiry': premiumExpiry,
    };
  }

  UserModel copyWith({
    int? id,
    String? email,
    String? name,
    String? about,
    String? goal,
    String? profilePic,
    String? country,
    String? countryCode,
    String? mobileNumber,
    String? linkedin,
    String? facebook,
    String? instagram,
    bool? isAdmin,
    String? token,
    String? role,
    bool? isPremium,
    String? premiumSince,
    String? premiumExpiry,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      about: about ?? this.about,
      goal: goal ?? this.goal,
      profilePic: profilePic ?? this.profilePic,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      linkedin: linkedin ?? this.linkedin,
      facebook: facebook ?? this.facebook,
      instagram: instagram ?? this.instagram,
      isAdmin: isAdmin ?? this.isAdmin,
      token: token ?? this.token,
      role: role ?? this.role,
      isPremium: isPremium ?? this.isPremium,
      premiumSince: premiumSince ?? this.premiumSince,
      premiumExpiry: premiumExpiry ?? this.premiumExpiry,
    );
  }
}
