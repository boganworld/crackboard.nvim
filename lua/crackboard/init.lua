local config = require 'crackboard.config'
local Job = require 'plenary.job'

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

    Job:new({
        command = 'curl',
        args = {
            '-X', 'POST',
            '-H', 'Content-Type: application/json',
            '-d', body,
            config.HEARTBEAT
        },
        on_exit = function(j, return_val)
            if return_val == 0 then
                print("Heartbeat sent successfully")
            else
                print('Failed to send heartbeat. Status: ' .. return_val)
                print(table.concat(j:stderr_result(), "\n"))
            end
        end
    }):start()
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
