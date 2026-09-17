/// Identifier embedded into the application at build time.
const String appBuildId = String.fromEnvironment(
  'APP_BUILD_ID',
  defaultValue: 'local-dev',
);
