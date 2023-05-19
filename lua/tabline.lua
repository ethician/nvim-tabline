-- nvim-tabline
-- David Zhang <https://github.com/crispgm>

local M = {}
local fn = vim.fn

local utf8 = require('utf8')

M.options = {
  show_index = true,
  show_modify = true,
  show_icon = false,
  show_scrollers = true,
  show_nr_tabs = true,
  shorten_path = false,
  shorten_path_fully = false,
  shorten_indicator = '_',
  separator = ' ',
  fnamemodify = ':t',
  scroll_left = '< ',
  scroll_right = ' >',
  no_name = '[No Name]',
  header = '',
  footer = '',
  prefix = '',
  suffix = '',
  active_prefix = '',
  active_suffix = '',
  modify_indicator = '+',
  shorten_length = 1,
  tab_max_length = 0,
  filename_max_length = 0,
}

M.consts = {
  path_separator = function()
    if vim.fn.has("win32") == 1 or vim.fn.has("win32unix") == 1 then
      return '\\'
    else
      return '/'
    end
  end,
  separator_length = 0,
  scroll_left_length = 0,
  scroll_right_length = 0,
  header_length = 0,
  footer_length = 0,
  unavailable_length = 0,
}

M.pages = {
  count = 0,
  active_tab_index = 0,
  previous_active_tab_index = 0,
  view_begin_index = 0,
  view_end_index = 0,
  alignment = 0,  -- 0 left, 1 right
  have_left_scroller = false,
  have_right_scroller = false,
  tabs = {},
}

function M.pages:get(index)
  local tab = self.tabs[index]
  if tab == nil then
    tab = {
      index = index,
      previous_index = index,
      is_processed = false,
      is_active = false,
      absolute_begin_index = 0,
      absolute_end_index = 0,
      string = '',
      string_length = 0,
    }
    table.insert(self.tabs, tab)
    self.count = self.count + 1
  else
    if tab.index ~= index then
      if self.previous_active_tab_index == tab.index then
        self.previous_active_tab_index = index
      end
      tab.previous_index = tab.index
      tab.index = index
    end
  end
  return tab
end

function M.pages:get_active()
  if self.active_tab_index == 0 then
    return nil
  else
    return self.tabs[self.active_tab_index]
  end
end

local function BuildBufferName(tab)
  local winnr = fn.tabpagewinnr(tab.index)
  local buflist = fn.tabpagebuflist(tab.index)
  local bufnr = buflist[winnr]
  local bufname = fn.bufname(bufnr)
  local bufmodified = fn.getbufvar(bufnr, '&mod')

  tab.string = ''

  -- active
  if tab.index == fn.tabpagenr() then
    M.pages.previous_active_tab_index = M.pages.active_tab_index
    M.pages.active_tab_index = tab.index
    tab.is_active = true
    tab.string = tab.string .. M.options.active_prefix
  else
    tab.is_active = false
    tab.string = tab.string .. M.options.prefix
  end

  -- tab index
  if M.options.show_index then
    tab.string = tab.string .. tab.index
  end

  -- modify indicator
  if bufmodified == 1 and M.options.show_modify then
    tab.string = tab.string .. M.options.modify_indicator
  else
    tab.string = tab.string .. ' '
  end

  -- icon
  local icon = ''
  if M.options.show_icon and M.has_devicons then
    local ext = fn.fnamemodify(bufname, ':e')
    icon = M.devicons.get_icon(bufname, ext, { default = true }) .. ' '
  end

  -- buffer name
  if bufname ~= '' then
    local name = ''

    local filename = fn.fnamemodify(bufname, M.options.fnamemodify)
    local filename_length = utf8.len(filename)

    if M.options.tab_max_length > 1 then
      filename = M.options.shorten_indicator .. utf8.sub(filename, filename_length - M.options.tab_max_length + 2)
    else
      local tail = fn.fnamemodify(bufname, ':t')
      local tail_length = utf8.len(tail)

      local head = utf8.sub(filename, 1, filename_length - tail_length)
      local head_length = utf8.len(head)

      if head_length > 0 then
        if M.options.shorten_path_fully then
          name = M.options.shorten_indicator .. M.consts.path_separator
        elseif M.options.shorten_path then
          name = fn.pathshorten(head)
        else
          name = head
        end
      end

      if M.options.filename_max_length > 1 then
        if tail_length > M.options.filename_max_length then
          name = name .. M.options.shorten_indicator .. utf8.sub(tail, tail_length - M.options.filename_max_length + 2)
        else
          name = name .. tail
        end
      else
        name = name .. tail
      end
    end

    if utf8.len(icon) > 0 then
      tab.string = tab.string .. name .. ' ' .. icon
    else
      tab.string = tab.string .. name
    end
  else
    tab.string = tab.string .. M.options.no_name
  end

  if tab.is_active then
    tab.string = tab.string .. M.options.active_suffix
  else
    tab.string = tab.string .. M.options.suffix
  end

  tab.string_length = utf8.len(tab.string)
end

local function HandleFirstTab(s_length, available_width)
  M.pages.alignment = 0

  if s_length < available_width then
    M.pages.view_begin_index = 1
    M.pages.view_end_index = s_length
    return
  end

  M.pages.view_begin_index = 1
  M.pages.view_end_index = available_width
end

local function HandleLastTab(s_length, available_width)
  M.pages.alignment = 1

  if s_length < available_width then
    M.pages.view_begin_index = 1
    M.pages.view_end_index = s_length
    return
  end

  M.pages.view_begin_index = s_length - available_width + 1
  M.pages.view_end_index = s_length
end

local function HandleMiddleTab(s, s_length, available_width, tab)
  if s_length < available_width then
    M.pages.view_begin_index = 1
    M.pages.view_end_index = s_length
    return
  end

  local to_right = M.pages.active_tab_index > M.pages.previous_active_tab_index;
  local to_left = M.pages.active_tab_index < M.pages.previous_active_tab_index;

  if to_right then
    local offset = 0
    if M.pages.have_right_scroller then
      offset = offset + M.consts.scroll_right_length
    end

    if tab.absolute_end_index < M.pages.view_end_index - offset then
      return
    end

    M.pages.alignment = 1

    M.pages.view_end_index = tab.absolute_end_index
    M.pages.view_begin_index = tab.absolute_end_index - available_width + 1

    return
  end
  
  if to_left then
    local offset = 0
    if M.pages.have_left_scroller then
      offset = offset + M.consts.scroll_left_length
    end

    if tab.absolute_begin_index > M.pages.view_begin_index + offset then
      return
    end

    M.pages.alignment = 0

    M.pages.view_begin_index = tab.absolute_begin_index
    M.pages.view_end_index = tab.absolute_begin_index + available_width - 1

    return
  end

  return
end

local function GetTabline(options)
    local s = ''

    local nr_tabs = fn.tabpagenr('$')

    local begin_index = 1

    local s_length = 0

    for index = 1, nr_tabs do
      local tab = M.pages:get(index)

      BuildBufferName(tab)

      -- TODO(tom): Ineffective. Re-factor.
      if index == nr_tabs then
        s = s .. tab.string

        tab.absolute_begin_index = begin_index
        tab.absolute_end_index = tab.absolute_begin_index + tab.string_length - 1

        s_length = s_length + tab.string_length
      else
        s = s .. tab.string .. M.options.separator

        tab.absolute_begin_index = begin_index
        tab.absolute_end_index = tab.absolute_begin_index + tab.string_length - 1
        
        begin_index = tab.absolute_end_index + M.consts.separator_length + 1

        s_length = s_length + tab.string_length + M.consts.separator_length
      end
    end

    local width = vim.api.nvim_eval("&columns")

    local available_width = width - M.consts.unavailable_length

    -- number of tabs
    local s_nr_tabs = ''
    local s_nr_tabs_length = 0

    if M.options.show_nr_tabs then
      if s_length < available_width then
        s_nr_tabs = s_nr_tabs .. '%#TabLineFill#%='
      end
      s_nr_tabs = s_nr_tabs .. ' [' .. M.pages.count .. ']'
      s_nr_tabs_length = utf8.len(s_nr_tabs)
      available_width = available_width - s_nr_tabs_length
    end

    -- view
    local active_tab = M.pages:get_active()
    if active_tab == nil then
      return s
    end

    if active_tab.index == 1 then
      HandleFirstTab(s_length, available_width)
    elseif active_tab.index == nr_tabs then
      HandleLastTab(s_length, available_width)
    else
      HandleMiddleTab(s, s_length, available_width, active_tab)
    end

    -- scrollers
    local offset = 0
    if M.options.show_scrollers then
      if M.pages.view_begin_index > 1 then
        if M.pages.view_end_index < s_length then
          M.pages.have_left_scroller = true
          M.pages.have_right_scroller = true
          local need = M.consts.scroll_left_length + M.consts.scroll_right_length
          if M.pages.alignment == 0 then
            offset = M.consts.scroll_left_length
            s = M.options.scroll_left .. utf8.sub(s, M.pages.view_begin_index, M.pages.view_end_index - need) .. M.options.scroll_right
          else
            offset = M.consts.scroll_left_length - need
            s = M.options.scroll_left .. utf8.sub(s, M.pages.view_begin_index + need, M.pages.view_end_index) .. M.options.scroll_right
          end
        else
          M.pages.have_left_scroller = true
          M.pages.have_right_scroller = false
          s = M.options.scroll_left .. utf8.sub(s, M.pages.view_begin_index + M.consts.scroll_left_length)
        end
      else
        if M.pages.view_end_index < s_length then
          M.pages.have_left_scroller = false
          M.pages.have_right_scroller = true
          local need = M.consts.scroll_right_length
          s = utf8.sub(s, 1, M.pages.view_end_index - need) .. M.options.scroll_right
        else
          M.pages.have_left_scroller = false
          M.pages.have_right_scroller = false
          s = utf8.sub(s, M.pages.view_begin_index, M.pages.view_end_index)
        end
      end
    else
      s = utf8.sub(s, M.pages.view_begin_index, M.pages.view_end_index)
    end

    -- number of tabs
    s = s .. s_nr_tabs

    -- decorate
    local position = active_tab.absolute_begin_index - M.pages.view_begin_index + offset
    s = utf8.insert(s, '%#TabLine#', position + active_tab.string_length)
    s = utf8.insert(s, '%' .. active_tab.index .. 'T' .. '%#TabLineSel#', position)

    return M.options.header .. s .. M.options.footer
end

function M.setup(user_options)
  M.options = vim.tbl_extend('force', M.options, user_options)
  M.has_devicons, M.devicons = pcall(require, 'nvim-web-devicons')

  M.consts.separator_length = utf8.len(M.options.separator)
  M.consts.scroll_left_length = utf8.len(M.options.scroll_left)
  M.consts.scroll_right_length = utf8.len(M.options.scroll_right)
  M.consts.header_length = utf8.len(M.options.header)
  M.consts.footer_length = utf8.len(M.options.footer)
  M.consts.unavailable_length = M.consts.header_length + M.consts.footer_length

  function _G.nvim_tabline()
    return GetTabline(M.options)
  end

  vim.o.showtabline = 2
  vim.o.tabline = '%!v:lua.nvim_tabline()'

  vim.g.loaded_nvim_tabline = 1
end

return M
