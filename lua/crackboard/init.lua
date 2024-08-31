local config = require 'crackboard.config'

local function send_heartbeat(language)
    if not config.session_key then
        print("Crackboard: Session key not set. Use :CrackboardSetSessionKey to set it.")
        return
    end

    local body = vim.json.encode({
        timestamp = os.date('!%Y-%m-%dT%TZ'),
        session_key = config.session_key,
        language_name = language
    })

    local client = vim.loop.new_tcp()
    local req = table.concat({
        string.format("POST %s HTTP/1.1", config.HEARTBEAT),
        "Host: " .. config.BASE_URL,
        "Accept: */*",
        "Content-Type: application/json",
        "Content-Length: ".. #body,
        "",
        body,
        "",
    }, "\n")

    print(req)

    vim.loop.getaddrinfo(config.BASE_URL, "443", {
        family = "inet",
        socktype = "stream",
        protocol = "tcp"
    }, function(err, res)
        if err then
            print("DNS resolution error: " .. err)
            return
        end

        if not res or #res == 0 then
            print("Failed to resolve " .. config.BASE_URL)
            return
        end

        local client = vim.loop.new_tcp()
        client:connect(res[1].addr, res[1].port, function(err)
            if err then
                print("Connection error: " .. err)
                client:close()
                return
            end

            client:write(req)

            local response = ""
            client:read_start(function(err, chunk)
                if err then
                    print("Read error: " .. err)
                    client:close()
                    return
                end

                if chunk then
                    response = response .. chunk
                else
                    client:close()
                    local status = response:match("HTTP/1%.%d (%d+)")
                    if status == "200" then
                        config.last_heartbeat_time = uv.now()
                        print("Heartbeat sent successfully")
                    else
                        print('Failed to send heartbeat. Status: ' .. (status or "unknown"))
                    end
                end
            end)
        end)
    end)
end

local function on_save()
    local language = vim.bo.filetype
    send_heartbeat(language)
end

local function on_change()
    if config.typing_timer then
        vim.loop.timer_stop(config.typing_timer)
    end

    config.typing_timer = vim.loop.new_timer()
    config.typing_timer:start(config.HEARTBEAT_INTERVAL, 0, vim.schedule_wrap(function()
        local now = vim.fn.localtime() * 1000
        local language = vim.bo.filetype
        if not config.last_heartbeat_time or (now - config.last_heartbeat_time) >= config.HEARTBEAT_INTERVAL then
            send_heartbeat(language)
        end
    end))
end

local M = {}

function M.set_session_key()
    vim.ui.input({
        prompt = 'Enter session key: ',
        default = ''
    }, function(input)
        if input then
            config.session_key = input
            vim.g.crackboard_session_key = input
            print('Session key set')
        end
    end)
end

function M.load_session_key()
    config.session_key = vim.g.crackboard_session_key
end

function M.setup(opts)
    print(opts)
    
    config = vim.tbl_deep_extend("force", config, opts)

    vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = "*",
        callback = on_save
    })

    vim.api.nvim_create_autocmd("TextChanged", {
        pattern = "*",
        callback = on_change
    })

    vim.api.nvim_create_user_command("CrackboardSetSessionKey", M.set_session_key, {})
end

return M
