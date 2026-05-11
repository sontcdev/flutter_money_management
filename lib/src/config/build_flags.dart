class BuildFlags {
  const BuildFlags._();

  static const bool enableReleaseNetworkLogging = bool.fromEnvironment(
    'ENABLE_RELEASE_NETWORK_LOGGING',
    defaultValue: false,
  );
}
