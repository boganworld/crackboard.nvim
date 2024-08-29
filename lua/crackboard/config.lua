local config = {}

config.HEARTBEAT_INTERVAL = 2 * 60 * 1000  -- 2 minutes in milliseconds
config.ENDPOINT = 'https://crackboard.dev/heartbeat'
config.session_key = nil
config.last_heartbeat_time = nil
config.typing_timer = nil

return config