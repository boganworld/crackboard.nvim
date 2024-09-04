local config = require("crackboard.config")
local Job = require("plenary.job")

local function send_heartbeat(language)
	if not config.session_key then
		print("Crackboard: Session key not set. Use :CrackboardSetSessionKey to set it.")
		return
	end

	local body = vim.json.encode({
		timestamp = os.date("!%Y-%m-%dT%TZ"),
		session_key = config.session_key,
		language_name = language,
	})

	Job:new({
		command = "curl",
		args = {
			"-X",
			"POST",
			"-H",
			"Content-Type: application/json",
			"-d",
			body,
			config.BASE_URL .. config.HEARTBEAT,
		},
		on_exit = vim.schedule_wrap(function(j, return_val)
			if return_val == 0 then
				config.last_heartbeat_time = vim.fn.localtime()
				print("Heartbeat sent successfully")
			else
				print("Failed to send heartbeat. Status: " .. return_val)
				print(table.concat(j:stderr_result(), "\n"))
			end
		end),
	}):start()
end

local function on_save()
	local language = vim.bo.filetype
	send_heartbeat(language)
end

local function setTimeout(timeout, callback)
	local timer = vim.uv and vim.uv.new_timer() or vim.loop.new_timer()
	timer:start(timeout, 0, function()
		-- i wonder if it's possible to close and also have this cb called at the same time?
		if not timer:is_active() then
			return
		end
		timer:stop()
		timer:close()
		callback()
	end)
	return timer
end

local function on_change()
	if config.typing_timer and config.typing_timer:is_active() then
		config.typing_timer:stop()
		config.typing_timer:close()
	end
	-- wait until heart beat is available
	config.typing_timer = setTimeout(
		config.HEARTBEAT_INTERVAL,
		vim.schedule_wrap(function()
			local now = vim.fn.localtime() * 1000
			local language = vim.bo.filetype
			if not config.last_heartbeat_time or (now - config.last_heartbeat_time) >= config.HEARTBEAT_INTERVAL then
				send_heartbeat(language)
			end
		end)
	)
end

local M = {}

function M.set_session_key()
	vim.ui.input({
		prompt = "Enter session key: ",
		default = "",
	}, function(input)
		if input then
			config.session_key = input
			vim.g.crackboard_session_key = input
			print("Session key set")
		end
	end)
end

function M.load_session_key()
	config.session_key = vim.g.crackboard_session_key
end

function M.setup(opts)
	-- print(opts)

	config = vim.tbl_deep_extend("force", config, opts)

	vim.api.nvim_create_autocmd("BufWritePost", {
		pattern = "*",
		callback = on_save,
	})

	vim.api.nvim_create_autocmd("TextChanged", {
		pattern = "*",
		callback = on_change,
	})

	vim.api.nvim_create_user_command("CrackboardSetSessionKey", M.set_session_key, {})
end

return M
