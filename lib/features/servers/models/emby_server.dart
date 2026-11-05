class EmbyServer {
  const EmbyServer({
    this.localId,
    required this.name,
    required this.address,
    required this.username,
    required this.password,
    required this.accessToken,
    required this.serverId,
  });

  final int? localId;
  final String name;
  final String address;
  final String username;
  final String password;
  final String accessToken;
  final String serverId;

  EmbyServer copyWith({int? localId}) => EmbyServer(
    localId: localId ?? this.localId,
    name: name,
    address: address,
    username: username,
    password: password,
    accessToken: accessToken,
    serverId: serverId,
  );
}
