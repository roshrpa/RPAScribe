// Set these before building. The server URL must be https.
const String serverUrl = String.fromEnvironment(
  'SERVER_URL',
  defaultValue: 'https://your-server.example.com',
);
const String appToken = String.fromEnvironment(
  'APP_TOKEN',
  defaultValue: 'change-me',
);
