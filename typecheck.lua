local uv = vim.uv or vim.loop

---@param path string
---@return any
local function read_json_file(path)
  local fd = assert(uv.fs_open(path, "r", 420)) -- 0644
  local stat = assert(uv.fs_fstat(fd))
  local content = assert(uv.fs_read(fd, stat.size))
  uv.fs_close(fd)

  return vim.json.decode(content, { luanil = { object = true } })
end

---@param path string
---@param data any
local function write_json_file(path, data)
  local fd = assert(uv.fs_open(path, "w", 420)) -- 0644
  uv.fs_write(fd, vim.json.encode(data))
  uv.fs_close(fd)
end

---@param cmd string[]
---@param opts? table
---@return integer exit code
local function run_cmd(cmd, opts)
  local exit_code
  local output = {}
  local jid = vim.fn.jobstart(
    cmd,
    vim.tbl_deep_extend("error", {
      stdout_buffered = true,
      stderr_buffered = true,
      on_stdout = function(_, data)
        vim.list_extend(output, data)
      end,
      on_stderr = function(_, data)
        vim.list_extend(output, data)
      end,
      on_exit = function(_, code)
        print(table.concat(output, "\n"))
        exit_code = code
      end,
    }, opts or {})
  )
  if jid == 0 then
    print(string.format("Passed invalid arguments to '%s'", cmd[1]))
    return 1
  elseif jid == -1 then
    print(string.format("'%s' is not executable", cmd[1]))
    return 1
  end
  vim.fn.jobwait({ jid })
  return exit_code
end

---@param cmd string[]
---@return integer exit code
local function run_cmd_in_terminal(cmd)
  local exit_code
  local handle, err = uv.spawn(cmd[1], {
    args = vim.list_slice(cmd, 2),
    -- Keep LuaLS attached to the caller's terminal so its pretty output,
    -- including ANSI colors, is rendered normally.
    stdio = { 0, 1, 2 },
  }, function(code, signal)
    if code ~= 0 then
      exit_code = code
    elseif signal ~= 0 then
      exit_code = 128 + signal
    else
      exit_code = 0
    end
  end)
  if not handle then
    print(string.format("Could not run '%s': %s", cmd[1], err))
    return 1
  end
  while exit_code == nil do
    vim.wait(100)
  end
  handle:close()
  return exit_code
end

---@param workdir string path to directory to clone repo into
---@param url string url of repo with optional version specifier at the end (e.g. @master)
---@return string location on disk of the cloned repo
local function clone_repo(workdir, url)
  local pieces = vim.split(url, "@", { plain = true, trimempty = true })
  url = pieces[1]
  local rev = pieces[2]
  local basename = vim.fn.fnamemodify(url, ":t")
  local dest = string.format("%s/libs/%s", workdir, basename)
  if vim.fn.isdirectory(dest) == 0 then
    local code = run_cmd({ "git", "clone", url, dest })
    if code ~= 0 then
      print(string.format("Error cloning repo %s", url))
      os.exit(1)
    end
  end
  if rev then
    local code = run_cmd({ "git", "checkout", rev }, { cwd = dest })
    if code ~= 0 then
      print(string.format("Could not check out rev '%s'", rev))
      os.exit(1)
    end
  end
  return dest
end

---@param opts Options
---@return table
local function gen_config(opts)
  local config
  if opts.configpath then
    local project_conf = read_json_file(opts.configpath)
    -- luarc.json files don't have to prefix values with Lua
    -- https://luals.github.io/wiki/configuration/#luarcjson-file
    -- So if they don't, we need to add that prefix to keep the right format.
    if not project_conf.Lua then
      project_conf = { Lua = project_conf }
    end
    config = vim.tbl_deep_extend("force", project_conf, {
      Lua = {
        telemetry = {
          enable = false,
        },
      },
    })
  else
    config = {
      Lua = {
        telemetry = {
          enable = false,
        },
        diagnostics = {
          globals = { "it", "describe", "before_each", "after_each" },
        },
        runtime = {
          version = "LuaJIT",
          path = { "?.lua", "?/init.lua" },
          pathStrict = true,
        },
      },
    }
  end
  config.Lua.workspace = config.Lua.workspace or {}
  config.Lua.workspace.library = config.Lua.workspace.library or {}
  table.insert(config.Lua.workspace.library, vim.env.VIMRUNTIME)
  table.insert(opts.libraries, "https://github.com/Bilal2453/luvit-meta")
  for _, lib in ipairs(opts.libraries) do
    if lib:match("^.*://") then
      local path = clone_repo(opts.workdir, lib)
      table.insert(config.Lua.workspace.library, path)
    else
      table.insert(config.Lua.workspace.library, lib)
    end
  end
  config.Lua.workspace.ignoreDir = config.Lua.workspace.ignoreDir or {}
  vim.list_extend(config.Lua.workspace.ignoreDir, opts.ignore)
  return config
end

---@param opts Options
---@return integer exit code
local function run_typecheck(opts)
  local logdir = string.format("%s/logs", opts.workdir)
  vim.fn.mkdir(logdir, "p")
  -- Clear out check result from prior run if present

  local config = gen_config(opts)
  local configpath = string.format("%s/luarc.json", logdir)
  write_json_file(configpath, config)
  local cmd = {
    opts.bin or "lua-language-server",
    "--logpath",
    logdir,
    "--configpath",
    configpath,
    "--check_format",
    "pretty",
    "--checklevel",
    opts.level or "Warning",
    "--check",
    opts.path,
  }
  return run_cmd_in_terminal(cmd)
end

---@class Options
---@field path string
---@field bin? string
---@field level? "Error"|"Warning"|"Information"
---@field configpath? string
---@field ignore string[]
---@field libraries string[]
---@field workdir string

---@param path string
---@return string
local function parse_configpath(path)
  if vim.fn.filereadable(path) == 0 then
    print(string.format("Could not find configpath file '%s'", path))
    os.exit(1)
  end
  return vim.fn.fnamemodify(path, ":p")
end

---@param level string
---@return "Error"|"Warning"|"Information"
local function parse_level(level)
  local lower_level = level:lower()
  if lower_level == "error" then
    return "Error"
  elseif lower_level == "warning" then
    return "Warning"
  elseif lower_level == "information" then
    return "Information"
  else
    print(string.format("Level '%s' must be one of Information, Warning, or Error", level))
    os.exit(1)
  end
end

---@param bin string
---@return string
local function parse_bin(bin)
  if vim.fn.filereadable(bin) == 0 then
    print(string.format("Could not find bin file '%s'", bin))
    os.exit(1)
  end
  return bin
end

local function print_help()
  local help = table.concat({
    string.format("%s [OPTIONS] [PATH]", arg[0]),
    "\nOptions:",
    "  -h, --help             Print help and exit",
    "  --bin BIN              Path to lua-language-server",
    "  --level LEVEL          Minimum level to check (one of Information, Warning, Error)",
    "  --configpath CONFIG    Path to luarc.json config file",
    "  --ignore PATH          Path to ignore. May be specified multiple times",
    "  --lib LIBRARY          Path to library or url of github repo. May be specified multiple times",
    "  --workdir DIR          Path to directory to store libraries and temp files",
    "",
  }, "\n")
  print(help)
end

---@param cli_args string[]
---@return Options
local function parse_args(cli_args)
  local opts = {
    ignore = {},
    libraries = {},
    workdir = assert(uv.os_tmpdir()) .. "/nvim-typecheck-action",
  }
  local i = 1
  while i <= #cli_args do
    local str = cli_args[i]
    if str == "-h" or str == "--help" then
      print_help()
      os.exit(0)
    elseif str == "--level" then
      i = i + 1
      opts.level = parse_level(cli_args[i])
    elseif str == "--bin" then
      i = i + 1
      opts.bin = parse_bin(cli_args[i])
    elseif str == "--configpath" then
      i = i + 1
      opts.configpath = parse_configpath(cli_args[i])
    elseif str == "--ignore" then
      i = i + 1
      table.insert(opts.ignore, cli_args[i])
    elseif str == "--lib" then
      i = i + 1
      table.insert(opts.libraries, cli_args[i])
    elseif str == "--workdir" then
      i = i + 1
      opts.workdir = vim.fn.fnamemodify(cli_args[i], ":p")
      if vim.endswith(opts.workdir, "/") then
        opts.workdir = opts.workdir:sub(1, -2)
      end
    else
      if opts.path then
        print("Error: can only specify one path to check")
        print_help()
        os.exit(1)
      else
        opts.path = str
      end
    end
    i = i + 1
  end

  if not opts.configpath then
    if uv.fs_stat(".luarc.json") then
      opts.configpath = vim.fn.fnamemodify(".luarc.json", ":p")
    elseif uv.fs_stat("luarc.json") then
      opts.configpath = vim.fn.fnamemodify("luarc.json", ":p")
    end
  end

  opts.path = opts.path or "."
  return opts
end

-- Ensure that the stdout doesn't get truncated
vim.o.columns = 10000
math.randomseed(uv.hrtime())
assert(arg)
local opts = parse_args(arg)
os.exit(run_typecheck(opts))
