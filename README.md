# nvim-tabline

Created as a fork of [crispgm/nvim-tabline](https://github.com/crispgm/nvim-tabline) with the following main improvement in mind:

* Support for scrolling through a multitude of tabs.

A minimal Tabline plugin for Neovim, written in Lua.
It is basically a drop-in replacement for [tabline.vim](https://github.com/mkitt/tabline.vim) but with [a few differences](#Differences).

![nvim-tabline-screenshots](screenshots/nvim-tabline.png)

## Installation

With `lazy.nvim`:

```lua
{
    'ethician/nvim-tabline',
    dependencies = { 'nvim-tree/nvim-web-devicons' }, -- optional
    config = true,
}
```

## Configuration

```lua
require('tabline').setup({opts})
```

### Defaults

```lua
require('tabline').setup({
    show_index = true,           -- show tab index
    show_modify = true,          -- show buffer modification indicator
    show_icon = false,           -- show file extension icon
    show_scrollers = true,       -- show left/right scroller indicators
    show_nr_tabs = true,         -- show total number of tabs
    shorten_path = false,        -- directory is represented by a `shorten_length` number of characters
    shorten_path_fully = false,  -- directory substructure is represented by `shorten_indicator`
    shorten_indicator = '_',     -- self descriptive
    separator = ' ',             -- self descriptive
    fnamemodify = ':t',          -- file name modifier
    scroller_left = '< ',        -- left scroller
    scroller_right = ' >',       -- right scroller
    no_name = '[No Name]',       -- no-name buffer name
    header = '',                 -- static string at the beginning of a tabline
    footer = '',                 -- static string at the end of a tabline
    prefix = '',                 -- static string at the beginning of a tab
    suffix = '',                 -- static string at the end of a tab
    active_prefix = '',          -- static string at the beginning of an active tab
    active_suffix = '',          -- static string at the end of an active tab
    modify_indicator = '+',      -- inidicator of a modified buffer
    shorten_length = 1,          -- see `shorten_path`
    tab_max_length = 0,          -- max length of a tab
    filename_max_length = 0,     -- max filename length before it gets cut off and prepended by `shorten_indicator`
})
```

### Mappings

Vim's tabpage commands are powerful enough, `:help tabpage` for details.
If you need switch between tabs, [here is a great tutorial](https://superuser.com/questions/410982/in-vim-how-can-i-quickly-switch-between-tabs).

### Highlights

The highlighting of the tab pages line follows vim settings. See `:help setting-tabline` for details.

### Differences

nvim-tabline is not exactly a Lua translation. There are some differences for configuration:

- Control whether to display tab number (`show_index`) and buffer modification indicator (`show_modify`).
- File extension icon with nvim-dev-icons.
- Customize modify indicator and no name buffer name.
- Close button (`g:tablineclosebutton`) is not supported.
