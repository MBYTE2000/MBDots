{ ... }:
{
  programs.nixvim = {
    enable = true;
    keymaps = [
      { key = "<C-n>"; action = ":Neotree toggle";               mode = "n"; options.desc = "Открыть дерево файлов слева"; }
      { key = "<C-b>"; action = ":Neotree buffers reveal float<CR>"; mode = "n"; options.desc = "Показать открытые буферы"; }
      { key = "<C-t>"; action = ":ToggleTerm<CR>";               mode = "n"; options.desc = "Открыть/закрыть терминал внизу"; }
    ];
    opts = {
      number = true;
      relativenumber = true;
      shiftwidth = 2;
    };
    plugins = {
      lualine.enable = true;
      neo-tree = {
        enable = true;
        settings = {
          enable_diagnostics = true;
          enable_git_status = true;
          close_if_last_window = true;
        };
      };
      toggleterm = {
        enable = true;
        settings = {
          direction = "horizontal";
          size = 0.30;
        };
      };
    };
    plugins.lsp = {
      enable = true;
      servers.clangd.enable = true;
    };
  };
}
