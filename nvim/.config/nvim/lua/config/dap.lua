local dap = require("dap")
dap.adapters["local-lua"] = {
  type = "executable",
  command = "node",
  args = {
    "/absolute/path/to/local-lua-debugger-vscode/extension/debugAdapter.js"
  },
  enrich_config = function(config, on_config)
    if not config["extensionPath"] then
      local c = vim.deepcopy(config)
      -- 💀 If this is missing or wrong you'll see 
      -- "module 'lldebugger' not found" errors in the dap-repl when trying to launch a debug session
      c.extensionPath = "/absolute/path/to/local-lua-debugger-vscode/"
      on_config(c)
    else
      on_config(config)
    end
  end,
}

dap.configurations.python = {
  {
    type = 'python';
    request = 'launch';
    name = "Launch file";
    program = "${file}";
    pythonPath = function()
      return '/opt/homebrew/bin/python3'
    end;
  },
}

dap.configurations.lua = {
  {
    type = 'lua';
    request = 'launch';
    name = "Launch file";
    program = "${file}";
    pythonPath = function()
      return '/usr/bin/python'
    end;
  },
}

dap.configurations.lua = {
  {
    name = 'Current file (local-lua-dbg, nlua)',
    type = 'local-lua',
    request = 'launch',
    cwd = '${workspaceFolder}',
    program = {
      lua = 'nlua.lua',
      file = '${file}',
    },
    verbose = true,
    args = {},
  },
}
