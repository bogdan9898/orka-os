-- Used by `iso/build.sh nvim`: after `Lazy! restore` has installed the
-- plugins, install everything LazyVim would otherwise download on the first
-- start (treesitter parsers, Mason tools and language servers), wait for it,
-- and fail loudly if something is missing.
--   nvim --headless "+Lazy! restore" "+luafile iso/nvim-bundle.lua"
-- (leading newline: plugin progress messages don't always end with one)
local function out(msg) io.stdout:write("\n" .. msg .. "\n") end
local function fail(msg) out("ERROR: " .. msg); vim.cmd("cquit 1") end

require("lazy").load({ plugins = { "nvim-treesitter", "nvim-lspconfig", "mason.nvim", "mason-lspconfig.nvim" } })

-- Treesitter parsers (compiled with tree-sitter-cli).
local parsers = LazyVim.opts("nvim-treesitter").ensure_installed
local ts_done = false
require("nvim-treesitter").install(parsers):await(function() ts_done = true end)
if not vim.wait(15 * 60 * 1000, function() return ts_done end, 500) then fail("treesitter install timed out") end
local have = require("nvim-treesitter.config").get_installed("parsers")
local missing = vim.tbl_filter(function(p) return not vim.tbl_contains(have, p) end, parsers)
if #missing > 0 then fail("parsers not installed: " .. table.concat(missing, " ")) end
out("parsers: " .. #parsers)

-- Mason: LazyVim's tools plus the packages of the language servers it enables.
local tools = vim.deepcopy(LazyVim.opts("mason.nvim").ensure_installed or {})
local to_pkg = require("mason-lspconfig").get_mappings().lspconfig_to_package
for server, sopts in pairs(LazyVim.opts("nvim-lspconfig").servers or {}) do
  local on = server ~= "*" and sopts ~= false and (type(sopts) ~= "table" or (sopts.mason ~= false and sopts.enabled ~= false))
  if on and to_pkg[server] then table.insert(tools, to_pkg[server]) end
end

local mr = require("mason-registry")
local refreshed = false
mr.refresh(function() refreshed = true end)
if not vim.wait(5 * 60 * 1000, function() return refreshed end, 200) then fail("mason registry refresh timed out") end

local pending = 0
for _, name in ipairs(tools) do
  local p = mr.get_package(name)
  if not p:is_installed() and not p:is_installing() then
    pending = pending + 1
    p:install({}, function(ok, err)
      pending = pending - 1
      if not ok then out("ERROR: mason " .. name .. ": " .. tostring(err)) end
    end)
  end
end
if not vim.wait(15 * 60 * 1000, function() return pending == 0 end, 500) then fail("mason install timed out") end
for _, name in ipairs(tools) do
  if not mr.get_package(name):is_installed() then fail("mason package not installed: " .. name) end
end
out("mason: " .. table.concat(tools, " "))
vim.cmd("qall!")
