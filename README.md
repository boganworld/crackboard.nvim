# crackboard.nvim

crackboard.dev is a leaderboard productivity tracker for tpot

lazy (wip):

```lua
require('lazy').setup({
  {
    'boganworld/crackboard.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('crackboard').setup({
        session_key = 'xx',
      })
    end,
  }
})
```

If you prefer to configure plugins on a per-file basis, you can create `lua/plugins/crackboard.lua` with the following content:
```lua
return {
  {
    "boganworld/crackboard.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("crackboard").setup({
        session_key = 'xx',
      })
    end,
  },
}
```

Also if you commit your dotfiles to VCS, you can use the following that reads your session key from `~/.local/secure/crackboard_session_key`:
```lua
return {
  {
    "boganworld/crackboard.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local function read_session_key(filepath)
        local file = io.open(filepath, "r")
        if not file then
          error("Could not open file: " .. filepath)
        end
        local key = file:read("*a")
        file:close()
        return key
      end

      local home_dir = os.getenv("HOME")
      local session_key_file = home_dir .. "/.local/secure/crackboard_session_key"

      require("crackboard").setup({
        session_key = read_session_key(session_key_file),
      })
    end,
  },
}
```
