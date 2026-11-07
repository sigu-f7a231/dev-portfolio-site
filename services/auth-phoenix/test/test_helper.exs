# Emulator の上のテスト（@moduletag :emulator）は、ふだんは飛ばす。動かすときは：
#   FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 mix test --only emulator
ExUnit.start(exclude: [:emulator])
