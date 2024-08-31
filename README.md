# crackboard.nvim

crackboard.dev is a leaderboard productivity tracker for tpot

lazy (wip):

```lua
require('lazy').setup({
  {
    'crackboard.nvim',
    config = function()
      require('crackboard.nvim').setup({
        session_key = 'xx'
      })
    end,
  }
})
```