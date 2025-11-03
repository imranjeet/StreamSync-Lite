import 'package:equatable/equatable.dart';

class ProfileState extends Equatable {
  final bool isDarkMode;
  final bool isSending;
  final String? successMessage;
  final String? errorMessage;
  final String? userName;
  final String? userEmail;

  const ProfileState({
    required this.isDarkMode,
    required this.isSending,
    this.successMessage,
    this.errorMessage,
    this.userName,
    this.userEmail,
  });

  factory ProfileState.initial() => const ProfileState(
        isDarkMode: false,
        isSending: false,
        successMessage: null,
        errorMessage: null,
        userName: null,
        userEmail: null,
      );

  ProfileState copyWith({
    bool? isDarkMode,
    bool? isSending,
    String? successMessage,
    String? errorMessage,
    String? userName,
    String? userEmail,
  }) {
    return ProfileState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isSending: isSending ?? this.isSending,
      successMessage: successMessage,
      errorMessage: errorMessage,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
    );
  }

  @override
  List<Object?> get props => [
        isDarkMode,
        isSending,
        successMessage,
        errorMessage,
        userName,
        userEmail,
      ];
}


