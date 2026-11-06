class EmbyServer {
  const EmbyServer({
    this.localId,
    required this.name,
    required this.address,
    required this.username,
    required this.password,
    required this.accessToken,
    required this.serverId,
    this.userId,
  });

  final int? localId;
  final String name;
  final String address;
  final String username;
  final String password;
  final String accessToken;
  final String serverId;
  final String? userId;

  EmbyServer copyWith({int? localId, String? userId, String? accessToken}) =>
      EmbyServer(
        localId: localId ?? this.localId,
        name: name,
        address: address,
        username: username,
        password: password,
        accessToken: accessToken ?? this.accessToken,
        serverId: serverId,
        userId: userId ?? this.userId,
      );
}
