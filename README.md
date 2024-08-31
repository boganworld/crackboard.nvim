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
