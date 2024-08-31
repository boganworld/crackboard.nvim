local default_config = {
    BASE_URL = "crackboard.dev",
    HEARTBEAT = "/heartbeat",
    HEARTBEAT_INTERVAL = 2 * 60 * 1000, -- 2 minutes in milliseconds
    session_key = nil,
    last_heartbeat_time = nil,
    typing_timer = nil
}

return default_config