import Config

config :auth_service, AuthServiceWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4102],
  server: false,
  secret_key_base: String.duplicate("test-only-secret", 4)

# Firebase Auth は Req.Test の偽物（test/support/firebase_stub.ex）。Emulator の上のテストは test/emulator_test.exs が切り替える
config :auth_service, :firebase,
  project_id: "demo-test",
  api_key: "test-key",
  auth_emulator_host: "auth.test:9099"

config :auth_service, :req_options, plug: {Req.Test, AuthService.Firebase}, retry: false
config :auth_service, :login_throttle, max_failures: 3, window_seconds: 900
config :logger, level: :warning
