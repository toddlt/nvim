-- Shared terminal implementation. User-facing configuration lives in the Lazy spec.
local M = {}

local config
local instances = {}
local last_agents = {}
local refresh_timer
local saved_updatetime
local selector_win

local function current_directory()
  local name = vim.api.nvim_buf_get_name(0)
  if vim.bo.buftype == "" and name ~= "" then
    return vim.fs.dirname(name)
  end
  return vim.fn.getcwd()
end

local function git_root(directory)
  local result = vim.system({ "git", "-C", directory, "rev-parse", "--show-toplevel" }, { text = true }):wait()
  if result.code == 0 and result.stdout then
    return vim.trim(result.stdout)
  end
end

local function project_context()
  if vim.b.agent_term_project then
    return vim.b.agent_term_project, vim.b.agent_term_cwd
  end

  local cwd = current_directory()
  if config.git.use_git_root then
    cwd = git_root(cwd) or cwd
  end
  return config.git.multi_instance and cwd or "global", cwd
end

local function is_running(buf)
  if not buf or not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "terminal" then
    return false
  end
  local job = vim.b[buf].terminal_job_id
  return job and vim.fn.jobwait({ job }, 0)[1] == -1
end

local function sorted_agent_names()
  local names = vim.tbl_keys(config.agents)
  table.sort(names, function(left, right)
    local left_order = config.agents[left].order or math.huge
    local right_order = config.agents[right].order or math.huge
    return left_order == right_order and left < right or left_order < right_order
  end)
  return names
end

local function running_agent(project_id, preferred_agent)
  if preferred_agent then
    return is_running(instances[preferred_agent .. "::" .. project_id]) and preferred_agent or nil
  end

  for _, name in ipairs(sorted_agent_names()) do
    if is_running(instances[name .. "::" .. project_id]) then
      return name
    end
  end
end

local function dimension(value, maximum)
  if type(value) == "string" then
    local percentage = tonumber(value:match("^(%d+)%%$"))
    if percentage then
      return math.floor(maximum * percentage / 100)
    end
  end
  return math.min(tonumber(value) or maximum, maximum)
end

local function position(value, size, maximum)
  if value == "center" then
    return math.floor((maximum - size) / 2)
  end
  if type(value) == "string" then
    local percentage = tonumber(value:match("^(%d+)%%$"))
    if percentage then
      return math.floor(maximum * percentage / 100)
    end
  end
  return math.max(0, math.min(tonumber(value) or 0, maximum - size))
end

local function open_window(buf)
  if config.window.position == "float" then
    local float = config.window.float
    local max_width = vim.o.columns
    local max_height = vim.o.lines - vim.o.cmdheight - 1
    local width = math.max(1, dimension(float.width, max_width))
    local height = math.max(1, dimension(float.height, max_height))
    return vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = width,
      height = height,
      row = position(float.row, height, max_height),
      col = position(float.col, width, max_width),
      border = float.border,
      style = "minimal",
    })
  end

  local split_commands = {
    botright = "botright split",
    topleft = "topleft split",
    left = "topleft vertical split",
    right = "botright vertical split",
    vertical = "botright vertical split",
  }
  local vertical = config.window.position == "left"
    or config.window.position == "right"
    or config.window.position == "vertical"
  vim.cmd(split_commands[config.window.position] or split_commands.botright)
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  if vertical then
    vim.api.nvim_win_set_width(win, math.max(1, math.floor(vim.o.columns * config.window.split_ratio)))
  else
    vim.api.nvim_win_set_height(win, math.max(1, math.floor(vim.o.lines * config.window.split_ratio)))
  end
  return win
end

local function configure_window(win)
  if config.window.hide_numbers then
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
  end
  if config.window.hide_signcolumn then
    vim.wo[win].signcolumn = "no"
  end
end

local function enter_terminal(buf)
  if config.window.enter_insert then
    vim.schedule(function()
      local is_current_terminal = vim.api.nvim_buf_is_valid(buf)
        and vim.api.nvim_get_current_buf() == buf
        and vim.bo[buf].buftype == "terminal"
      if is_current_terminal then
        vim.cmd("startinsert")
      end
    end)
  end
end

local function hide_buffer(buf)
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if #vim.api.nvim_list_wins() == 1 then
      vim.cmd("enew")
    else
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
end

local function terminal_keymaps(buf)
  if config.keymaps.window_navigation then
    for _, direction in ipairs({ "h", "j", "k", "l" }) do
      vim.keymap.set("t", "<C-" .. direction .. ">", "<C-\\><C-n><C-w>" .. direction, {
        buffer = buf,
        desc = "Window: move " .. direction,
      })
      vim.keymap.set("n", "<C-" .. direction .. ">", "<C-w>" .. direction, {
        buffer = buf,
        desc = "Window: move " .. direction,
      })
    end
  end
  if config.keymaps.scrolling then
    vim.keymap.set("t", "<C-f>", "<C-\\><C-n><C-f>i", { buffer = buf, desc = "Scroll page down" })
    vim.keymap.set("t", "<C-b>", "<C-\\><C-n><C-b>i", { buffer = buf, desc = "Scroll page up" })
  end
end

local function command_with_args(agent, args)
  return vim.list_extend(vim.deepcopy(agent.command), args or {})
end

local function start(instance_id, project_id, cwd, agent_name, agent, args)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "hide"
  vim.b[buf].agent_term_instance = instance_id
  vim.b[buf].agent_term_project = project_id
  vim.b[buf].agent_term_cwd = cwd
  vim.b[buf].agent_term_agent = agent_name

  local win = open_window(buf)
  configure_window(win)
  local job_options = { term = true, cwd = cwd }
  if agent.env then
    job_options.env = agent.env
  end
  local started, job = pcall(vim.fn.jobstart, command_with_args(agent, args), job_options)
  if not started or job < 1 then
    hide_buffer(buf)
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
    error(("agent-term: failed to start %s: %s"):format(agent_name, job), 0)
  end

  vim.api.nvim_buf_set_name(buf, "agent-term://" .. agent_name .. "/" .. project_id .. "/" .. job)
  instances[instance_id] = buf
  terminal_keymaps(buf)

  if config.refresh.enable and not saved_updatetime then
    saved_updatetime = vim.o.updatetime
    vim.o.updatetime = config.refresh.updatetime
  end
  enter_terminal(buf)
end

---Toggle an agent terminal for the current project, or select one when none is running.
---@param agent_name? string Defaults to the current or most recently used running agent
---@param variant_name? string Variant declared under the selected agent
---@return boolean success
function M.toggle(agent_name, variant_name)
  local project_id, cwd = project_context()
  if not agent_name then
    local current_agent = vim.b.agent_term_agent
    local last_agent = last_agents[project_id]
    agent_name = (current_agent and running_agent(project_id, current_agent))
      or (last_agent and running_agent(project_id, last_agent))
      or running_agent(project_id)
    if not agent_name then
      M.select()
      return true
    end
  end
  local agent = config.agents[agent_name]
  if not agent then
    vim.notify("Unknown agent: " .. agent_name, vim.log.levels.ERROR, { title = "agent-term" })
    return false
  end

  local args = {}
  if variant_name then
    local variant = agent.variants[variant_name]
    if not variant then
      vim.notify(
        ("Unknown variant %q for agent %q"):format(variant_name, agent_name),
        vim.log.levels.ERROR,
        { title = "agent-term" }
      )
      return false
    end
    args = variant.args or {}
  end

  local instance_id = agent_name .. "::" .. project_id
  last_agents[project_id] = agent_name
  local buf = instances[instance_id]
  if buf and not is_running(buf) then
    hide_buffer(buf)
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
    instances[instance_id] = nil
    buf = nil
  end

  if not buf then
    start(instance_id, project_id, cwd, agent_name, agent, args)
  elseif #vim.fn.win_findbuf(buf) > 0 then
    hide_buffer(buf)
  else
    configure_window(open_window(buf))
    enter_terminal(buf)
  end
  return true
end

local function close_selector()
  if selector_win and vim.api.nvim_win_is_valid(selector_win) then
    vim.api.nvim_win_close(selector_win, true)
  end
  selector_win = nil
end

---Select an agent in a native floating window and toggle it for the current project.
---@return integer window
function M.select()
  local names = sorted_agent_names()
  close_selector()

  local width = 20
  for _, name in ipairs(names) do
    width = math.max(width, vim.fn.strdisplaywidth(name) + 4)
  end
  width = math.min(width, math.max(1, vim.o.columns - 4))
  local height = math.min(#names, math.max(1, vim.o.lines - 4))

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, names)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "agent-term-select"

  selector_win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)),
    border = "rounded",
    style = "minimal",
    title = " Agent terminal ",
    title_pos = "center",
  })
  vim.wo[selector_win].cursorline = true

  local function choose()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local agent_name = names[row]
    close_selector()
    if agent_name then
      vim.schedule(function()
        M.toggle(agent_name)
      end)
    end
  end

  local map_opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "<CR>", choose, vim.tbl_extend("force", map_opts, { desc = "Select agent" }))
  vim.keymap.set("n", "q", close_selector, vim.tbl_extend("force", map_opts, { desc = "Close selector" }))
  vim.keymap.set("n", "<Esc>", close_selector, vim.tbl_extend("force", map_opts, { desc = "Close selector" }))
  return selector_win
end

local function setup_refresh(group)
  if not config.refresh.enable then
    return
  end

  vim.o.autoread = true
  vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
    group = group,
    callback = function()
      if vim.fn.filereadable(vim.api.nvim_buf_get_name(0)) == 1 then
        vim.cmd("silent! checktime")
      end
    end,
    desc = "Reload files changed by an external agent",
  })
  if config.refresh.show_notifications then
    vim.api.nvim_create_autocmd("FileChangedShellPost", {
      group = group,
      callback = function()
        vim.notify("File changed on disk; buffer reloaded", vim.log.levels.INFO, { title = "agent-term" })
      end,
    })
  end

  refresh_timer = (vim.uv or vim.loop).new_timer()
  refresh_timer:start(0, config.refresh.timer_interval, vim.schedule_wrap(function()
    for _, buf in pairs(instances) do
      if is_running(buf) and #vim.fn.win_findbuf(buf) > 0 then
        vim.cmd("silent! checktime")
        return
      end
    end
  end))
end

local function setup_commands()
  vim.api.nvim_create_user_command("AgentTerm", function(command)
    if #command.fargs > 2 then
      vim.notify("Usage: AgentTerm [agent] [variant]", vim.log.levels.ERROR, { title = "agent-term" })
      return
    end
    M.toggle(command.fargs[1], command.fargs[2])
  end, {
    nargs = "*",
    desc = "Toggle an agent terminal: AgentTerm [agent] [variant]",
    force = true,
    complete = function(arg_lead)
      local candidates = vim.tbl_keys(config.agents)
      for _, agent in pairs(config.agents) do
        vim.list_extend(candidates, vim.tbl_keys(agent.variants))
      end
      table.sort(candidates)
      return vim.tbl_filter(function(candidate)
        return vim.startswith(candidate, arg_lead)
      end, candidates)
    end,
  })
  vim.api.nvim_create_user_command("AgentTermSelect", M.select, {
    desc = "Select and toggle an agent terminal",
    force = true,
  })
end

local function setup_keymaps()
  local toggle = config.keymaps.toggle
  if toggle then
    vim.keymap.set({ "n", "t" }, toggle, function()
      M.toggle()
    end, { desc = "Agent terminal: toggle" })
  end
  if config.keymaps.select then
    vim.keymap.set("n", config.keymaps.select, M.select, { desc = "Agent terminal: select" })
  end

  for agent_name, agent in pairs(config.agents) do
    local selected_agent = agent_name
    if agent.key then
      vim.keymap.set("n", agent.key, function()
        M.toggle(selected_agent)
      end, { desc = "Agent terminal: " .. selected_agent })
    end
    for variant_name, variant in pairs(agent.variants) do
      if variant.key then
        local selected_variant = variant_name
        vim.keymap.set("n", variant.key, function()
          M.toggle(selected_agent, selected_variant)
        end, { desc = ("Agent terminal: %s %s"):format(selected_agent, selected_variant) })
      end
    end
  end
end

---Configure agent-term and register its commands and keymaps.
---@param opts table
function M.setup(opts)
  assert(type(opts) == "table", "agent-term.setup() requires a configuration table")
  config = vim.deepcopy(opts)
  assert(type(config.agents) == "table", "agent-term: agents must be a table")
  for name, agent in pairs(config.agents) do
    local valid_command = vim.islist(agent.command) and #agent.command > 0
    assert(valid_command, "agent-term: command must be a non-empty argv list for " .. name)
    agent.variants = agent.variants or {}
  end
  if refresh_timer then
    refresh_timer:stop()
    refresh_timer:close()
    refresh_timer = nil
  end

  local group = vim.api.nvim_create_augroup("AgentTerm", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    group = group,
    callback = function(event)
      if vim.b[event.buf].agent_term_instance then
        enter_terminal(event.buf)
      end
    end,
  })
  vim.api.nvim_create_autocmd("TermClose", {
    group = group,
    callback = function(event)
      local instance_id = vim.b[event.buf].agent_term_instance
      if not instance_id then
        return
      end
      instances[instance_id] = nil
      local project_id = vim.b[event.buf].agent_term_project
      local agent_name = vim.b[event.buf].agent_term_agent
      if project_id and last_agents[project_id] == agent_name then
        last_agents[project_id] = nil
      end
      vim.schedule(function()
        hide_buffer(event.buf)
        pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
      end)
      if saved_updatetime and vim.tbl_isempty(instances) then
        vim.o.updatetime = saved_updatetime
        saved_updatetime = nil
      end
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      if refresh_timer then
        refresh_timer:stop()
        refresh_timer:close()
        refresh_timer = nil
      end
    end,
  })

  setup_commands()
  setup_keymaps()
  setup_refresh(group)
end

return M
