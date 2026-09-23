class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String updateProfile = '/user/profile';
  static const String uploadAvatar = '/user/avatar';
  static const String changePassword = '/user/password';

  // Locations
  static const String updateLocation = '/locations/update';
  static const String locationHistory = '/locations/history';

  // Rooms
  static const String rooms = '/rooms';
  static const String joinRoom = '/rooms/join';
  static String roomDetails(int roomId) => '/rooms/$roomId';
  static String roomLeave(int roomId) => '/rooms/$roomId/leave';
  static String roomMemberRemove(int roomId, int userId) => '/rooms/$roomId/members/$userId';
  static String roomLocations(int roomId) => '/rooms/$roomId/locations';
  static String roomMessages(int roomId) => '/rooms/$roomId/messages';
  static String roomUploadMedia(int roomId) => '/rooms/$roomId/messages/media';
  static String roomAlerts(int roomId) => '/rooms/$roomId/alerts';
  static String roomSos(int roomId) => '/rooms/$roomId/sos';
  static String alertAcknowledge(int roomId, int alertId) => '/rooms/$roomId/alerts/$alertId/acknowledge';
  static String alertCancel(int roomId, int alertId) => '/rooms/$roomId/alerts/$alertId/cancel';
  static String roomPlaces(int roomId) => '/rooms/$roomId/places';
  
  // Calls
  static String roomCalls(int roomId) => '/rooms/$roomId/calls';
  static const String activeCall = '/calls/active';
  static String callDetails(int callId) => '/calls/$callId';
  static String callJoin(int callId) => '/calls/$callId/join';
  static String callDecline(int callId) => '/calls/$callId/decline';
  static String callEnd(int callId) => '/calls/$callId/end';
}
