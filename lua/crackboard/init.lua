local config = require('crackboard.config')
local http = require('plenary.http')

local function send_heartbeat(language)
    local body = vim.fn.json_encode({
        timestamp = os.date('!%Y-%m-%dT%TZ'),
        session_key = config.session_key,
        language_name = language
    })

    http.post(config.ENDPOINT, {
        headers = { ['Content-Type'] = 'application/json' },
        body = body
    }, function(response)
        if response and response.status ~= 200 then
            print('Failed to send heartbeat:', response.status)
        else
            config.last_heartbeat_time = vim.fn.localtime() * 1000
        end
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
    vim.ui.input({ prompt = 'Enter session key: ', default = '' }, function(input)
        if input then
            config.session_key = input
            vim.g.crackboard_session_key = input
            print('Session key set to: ' .. input)
        end
    end)
end

function M.load_session_key()
    config.session_key = vim.g.crackboard_session_key
end

function M.setup()
    M.load_session_key()
    vim.api.nvim_create_autocmd("BufWritePost", { pattern = "*", callback = on_save })
    vim.api.nvim_create_autocmd("TextChanged", { pattern = "*", callback = on_change })
end

return M