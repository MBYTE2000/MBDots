{ pkgs, lib, ... }:
{
  programs.nixvim = {
    enable = true;

    globals.mapleader = " ";  # <Space> — для <Leader>ac и подобных из claudecode

    # --- Опции редактора ---------------------------------------------------
    opts = {
      number = true;
      relativenumber = true;   # относительная нумерация: 5 4 3 2 1 [0] 1 2 3
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
      termguicolors = true;
      signcolumn = "yes";
      cursorline = true;
      wrap = false;
      scrolloff = 6;
    };

    # --- Keymaps -----------------------------------------------------------
    keymaps = [
      # Файловое дерево
      { key = "<C-n>"; mode = "n"; action = ":Neotree toggle<CR>"; options.desc = "File tree (neo-tree)"; }
      { key = "<C-b>"; mode = "n"; action = ":Neotree buffers reveal float<CR>"; options.desc = "Buffers overlay"; }
      # Терминал
      { key = "<C-t>"; mode = "n"; action = ":ToggleTerm<CR>"; options.desc = "Toggle terminal"; }
      { key = "<Esc>"; mode = "t"; action = "<C-\\><C-n>"; options.desc = "Terminal → normal mode"; }
      # Claude Code (см. extraConfigLua ниже; здесь только шпаргалка в which-key)
      { key = "<Leader>ac"; mode = "n"; action = "<cmd>ClaudeCode<CR>"; options.desc = "Claude Code: toggle"; }
      { key = "<Leader>af"; mode = "n"; action = "<cmd>ClaudeCodeFocus<CR>"; options.desc = "Claude Code: focus"; }
      { key = "<Leader>as"; mode = "v"; action = "<cmd>ClaudeCodeSend<CR>"; options.desc = "Claude Code: send selection"; }
      { key = "<Leader>aa"; mode = "n"; action = "<cmd>ClaudeCodeDiffAccept<CR>"; options.desc = "Claude Code: accept diff"; }
      { key = "<Leader>ad"; mode = "n"; action = "<cmd>ClaudeCodeDiffDeny<CR>"; options.desc = "Claude Code: deny diff"; }
    ];

    # --- Плагины -----------------------------------------------------------
    plugins = {
      lualine.enable = true;

      # Treesitter — подсветка для KDL, Nix и остального, что пишется в этом
      # репо. Это даёт syntax highlighting для *.kdl файлов внутри Nix-стрингов
      # (readFile ./config/*.kdl), а также цветной Nix, bash, lua, json...
      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
          ensure_installed = [ ];  # используем grammarPackages ниже — воспроизводимо
        };
        grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
          kdl
          nix
          bash
          lua
          json
          yaml
          toml
          markdown
          markdown_inline
          javascript
          typescript
          python
          rust
          c
          cpp
        ];
      };

      # File tree
      neo-tree = {
        enable = true;
        settings = {
          enable_diagnostics = true;
          enable_git_status = true;
          close_if_last_window = true;
        };
      };

      # Терминал внизу
      toggleterm = {
        enable = true;
        settings = {
          direction = "horizontal";
          size = 0.30;
          shade_terminals = true;
        };
      };

      # LSP (C/C++ + Nix)
      lsp = {
        enable = true;
        servers = {
          clangd.enable = true;
          nixd.enable = true;    # Nix LSP (полезно ради самого репо)
        };
      };

      # web-devicons — иконки в neo-tree и других UI
      web-devicons.enable = true;
    };

    # --- Плагины через extraPlugins (нет нативной nixvim-опции) ------------
    extraPlugins = with pkgs.vimPlugins; [
      # Официальный плагин от Anthropic для Claude Code
      # https://github.com/coder/claudecode.nvim
      claudecode-nvim
      # Зависимость claudecode: folke/snacks.nvim (для terminal-provider)
      snacks-nvim
      # KDL синтаксис как отдельный vim-плагин на случай, если TS-parser
      # не установится (fallback filetype detection + syntax)
      # kdl-vim не в nixpkgs — treesitter + ftdetect ниже покрывают
    ];

    # --- Lua-конфиг для extraPlugins --------------------------------------
    extraConfigLua = ''
      -- Claude Code: минимальный setup. Клавиши задаются через keymaps выше.
      require("claudecode").setup({
        -- terminal_cmd = "claude",    -- бинарь берётся из PATH (у нас есть claude-code)
        auto_start = false,             -- открывается только по <Leader>ac
        -- Провайдер терминала — snacks.nvim; уже подтянут через extraPlugins.
        terminal = {
          provider = "snacks",
          split_side = "right",
          split_width_percentage = 0.4,
        },
      })

      -- KDL — filetype detection на всякий случай (для *.kdl файлов).
      vim.filetype.add({
        extension = {
          kdl = "kdl",
        },
      })
    '';
  };
}
