return {
  "neovim/nvim-lspconfig", -- LSP config

  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "simrat39/rust-tools.nvim", -- Rust Custom LSP
    "p00f/clangd_extensions.nvim",
    "hrsh7th/cmp-nvim-lsp", -- LSP completion
  },

  config = function()
    -- Base
    local mason = require("mason")
    local mason_lsp = require("mason-lspconfig")
    local lsp = require("lspconfig")

    -- Language specific
    local rust_tools = require("rust-tools")
    local clangd_extensions = require("clangd_extensions")

    -- Tools
    local cmp_lsp = require("cmp_nvim_lsp")

    local signs = {
      Error = " ",
      Warn = " ",
      Hint = " ",
      Info = " ",
    }

    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
    end

    vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })

    local servers = {
      "rust_analyzer",
      "clangd",
--      "svelte",
--      "tsserver",
--      "yamlls",
--      "pyright",
--      "jsonls",
--      "html",
--      "cssls",
      "lua_ls",
--      "dockerls",
--      "tailwindcss",
--      "taplo",
--      "astro",
    }

    local server_settings = {
      ["lua_ls"] = {
        Lua = {
          runtime = { version = "LuaJIT" },
          diagnostics = { globals = { "vim" } },
          workspace = {
        	library = vim.api.nvim_get_runtime_file("", true),
		checkThirdParty = false,
         },
        },
      },
    }

    local server_with_disabled_formatting = {
      ["tsserver"] = true,
      ["lua_ls"] = true,
      ["tailwindcss"] = true,
      ["cssls"] = true,
    }

    local use_formatter = {
      ["tsserver"] = true,
      -- ["sumneko_lua"] = true,
      ["cssls"] = true,
    }

    local null_ls_format = function(bufnr)
      vim.lsp.buf.format({
        async = true,
        filter = function (client)
          return client.name == 'null-ls'
        end
      })
      bufnr = bufnr
    end

	mason.setup()
	mason_lsp.setup({ ensure_installed = servers })

    	local capabilities = vim.lsp.protocol.make_client_capabilities()
	capabilities = cmp_lsp.default_capabilities(capabilities)

	-- The biding for every servers
	local on_attach = function(client, bufnr)
	local bufopts = { noremap = true, silent = true, buffer = bufnr }

	vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
	vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
	vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, bufopts)
	vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
	vim.keymap.set("n", "ge", vim.diagnostic.open_float, bufopts)
	vim.keymap.set("n", "<leader>dj", vim.diagnostic.goto_next, bufopts)
	vim.keymap.set("n", "<leader>dk", vim.diagnostic.goto_prev, bufopts)
	vim.keymap.set("n", "<leader>dl", ":Telescope diagnostics<CR>", bufopts)
	vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, bufopts)

      if server_with_disabled_formatting[client.name] then
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false

        if use_formatter[client.name] then
          vim.keymap.set("n", "<leader>F", null_ls_format, bufopts)
        end
      else
        vim.keymap.set("n", "<leader>F", ":lua vim.lsp.buf.format({ async = true })<CR>", bufopts)
      end
    end

    for _, server in pairs(servers) do
      if server == "rust_analyzer" then
        rust_tools.setup({ tools = { on_initialized = on_attach } })
      elseif server == "clangd" then
	clangd_extensions.setup{server = {}}
      else
        lsp[server].setup({
          capabilities = capabilities,
          on_attach = on_attach,
          settings = server_settings[server],
        })
      end
    end
  end,
}

