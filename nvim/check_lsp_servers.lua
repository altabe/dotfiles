-- LSP Server Diagnostic Script
-- Run this in Neovim to check for multiple LSP servers and conflicts
-- Usage: :lua dofile('check_lsp_servers.lua')

print("=== LSP Server Diagnostic Report ===")
print("Run this script in Neovim to check for LSP conflicts")
print("")

-- Check 1: Current LSP clients
print("1. CURRENT LSP CLIENTS:")
local clients = vim.lsp.get_active_clients({ bufnr = 0 })
if #clients > 0 then
    print("   Active LSP clients:", #clients)
    for i, client in ipairs(clients) do
        print("   - Client", i, ":", client.name, "(id:", client.id, ")")
        print("     Root:", client.config.root_dir or "N/A")
        print("     Settings:", vim.inspect(client.config.settings or {}))
    end
else
    print("   No LSP clients attached to current buffer")
end

print("")

-- Check 2: All LSP clients (not just current buffer)
print("2. ALL LSP CLIENTS:")
local all_clients = vim.lsp.get_active_clients()
if #all_clients > 0 then
    print("   Total active LSP clients:", #all_clients)
    for i, client in ipairs(all_clients) do
        print("   - Client", i, ":", client.name, "(id:", client.id, ")")
    end
else
    print("   No LSP clients active")
end

print("")

-- Check 3: Mason packages
print("3. MASON PACKAGES:")
local mason_packages = {}
local mason_path = vim.fn.stdpath("data") .. "/mason/packages"
if vim.fn.isdirectory(mason_path) == 1 then
    local packages = vim.fn.readdir(mason_path)
    for _, package in ipairs(packages) do
        table.insert(mason_packages, package)
    end
    print("   Installed Mason packages:")
    for _, package in ipairs(mason_packages) do
        print("   -", package)
    end
else
    print("   Mason packages directory not found")
end

print("")

-- Check 4: Mason binaries
print("4. MASON BINARIES:")
local mason_bin_path = vim.fn.stdpath("data") .. "/mason/bin"
if vim.fn.isdirectory(mason_bin_path) == 1 then
    local binaries = vim.fn.readdir(mason_bin_path)
    print("   Installed Mason binaries:")
    for _, binary in ipairs(binaries) do
        print("   -", binary)
    end
else
    print("   Mason bin directory not found")
end

print("")

-- Check 5: Python-specific LSP servers
print("5. PYTHON LSP SERVERS:")
local python_servers = {}
for _, package in ipairs(mason_packages) do
    if package:find("python") or package:find("py") or package:find("ruff") then
        table.insert(python_servers, package)
    end
end
if #python_servers > 0 then
    print("   Python-related packages found:")
    for _, server in ipairs(python_servers) do
        print("   -", server)
    end
else
    print("   No Python-related packages found")
end

print("")

-- Check 6: Test gd command behavior
print("6. GD COMMAND TEST:")
print("   To test gd behavior:")
print("   1. Open a Python file")
print("   2. Place cursor on a function/class name")
print("   3. Press gd")
print("   4. Check if the same definition appears twice")
print("   5. Note the output here")

print("")

-- Check 7: LSP configuration
print("7. LSP CONFIGURATION:")
print("   Current LSP config:")
local lsp_config = require("lspconfig")
for server_name, _ in pairs(lsp_config) do
    if type(lsp_config[server_name]) == "table" and lsp_config[server_name].setup then
        print("   -", server_name, "configured")
    end
end

print("")

-- Check 8: Environment info
print("8. ENVIRONMENT INFO:")
print("   Neovim version:", vim.version())
print("   Platform:", vim.loop.os_uname().sysname)
print("   Architecture:", vim.loop.os_uname().machine)
print("   SSH connection:", vim.env.SSH_CONNECTION and "Yes" or "No")
print("   TMUX session:", vim.env.TMUX and "Yes" or "No")

print("")
print("=== END DIAGNOSTIC REPORT ===")
print("")
print("If you see multiple Python LSP servers (like pyright, python-lsp-server, ruff-lsp, etc.),")
print("that's likely causing the duplicate definitions issue.")
print("")
print("Copy this output and paste it for further analysis.") 