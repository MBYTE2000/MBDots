{ ... }:
# Starship — pastel-powerline preset адаптированный под stylix.
# Каждый сегмент — своя base16-цветная плитка с diagonal powerline arrows ().
# stylix.targets.starship даёт нам палитру base00-base0F автоматически.
#
# Раскладка градиента по палитре:
#   base09 (оранжевый) — user@host                       (акцент)
#   base0A (жёлтый)    — directory
#   base0B (зелёный)   — git branch + status
#   base0D (синий)     — язык (c/rust/go/node/py/…)
#   base0C (циан)      — docker/kubernetes/nix_shell/env
#   base0E (пурпур)    — cmd_duration + clock
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      add_newline = true;
      command_timeout = 800;

      # Полный pastel-powerline. Каждый сегмент имеет свой bg,
      # переход между сегментами —  (fg предыдущего = bg следующего).
      format = builtins.concatStringsSep "" [
        "[](bg:base09)"
        "$os"
        "$username"
        "[](fg:base09 bg:base0A)"
        "$directory"
        "[](fg:base0A bg:base0B)"
        "$git_branch"
        "$git_status"
        "[](fg:base0B bg:base0D)"
        # Языки — starship показывает только те, что реально в PATH/файле.
        "$c$rust$golang$nodejs$python$java$kotlin$haskell$php$ruby$scala$dart$deno$bun$elixir$lua$nim$ocaml$perl$purescript$swift$zig$dotnet$elm$erlang$gleam$julia$raku$red$vlang$typst"
        "$nix_shell"
        "[](fg:base0D bg:base0C)"
        "$docker_context$kubernetes$terraform$package$conda$aws$gcloud$azure"
        "[](fg:base0C bg:base0E)"
        "$cmd_duration"
        "$time"
        "[](fg:base0E)"
        "$fill"
        "$line_break"
        "$character"
      ];

      fill = { symbol = " "; };

      # --- Левая капсула: OS + user@host (base09) ---------------------------
      os = {
        disabled = false;
        style = "bg:base09 fg:base00";
        symbols = {
          NixOS   = " ";
          Linux   = " ";
          Macos   = " ";
          Windows = " ";
          Arch    = " ";
          Debian  = " ";
          Ubuntu  = " ";
          Fedora  = " ";
          Alpine  = " ";
        };
        format = "[ $symbol]($style)";
      };

      username = {
        show_always = true;
        style_user = "bg:base09 fg:base00 bold";
        style_root = "bg:base08 fg:base00 bold";
        format = "[ $user ]($style)";
      };

      # --- Directory (base0A) -----------------------------------------------
      directory = {
        style = "bg:base0A fg:base00";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncate_to_repo = true;
        truncation_symbol = "…/";
        read_only = " ";
        substitutions = {
          "Documents"    = "󰈙 ";
          "Downloads"    = " ";
          "Music"        = " ";
          "Pictures"     = " ";
          "Videos"       = "󰕧 ";
          "nixos-config" = " nixos";
        };
      };

      # --- Git (base0B) — показывается только внутри repo -------------------
      git_branch = {
        symbol = "";
        style = "bg:base0B fg:base00";
        format = "[ $symbol $branch ]($style)";
      };

      git_status = {
        style = "bg:base0B fg:base00";
        format = "[$all_status$ahead_behind ]($style)";
        conflicted = "= ";
        ahead      = "⇡\${count} ";
        behind     = "⇣\${count} ";
        diverged   = "⇕ ";
        untracked  = "? ";
        stashed    = "≡ ";
        modified   = "! ";
        staged     = "+ ";
        renamed    = "» ";
        deleted    = "✘ ";
      };

      # --- Языки (base0D) — все шоу по detection ---------------------------
      # Общий стиль
      c        = { symbol = " ";   style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      rust     = { symbol = " ";  style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      golang   = { symbol = " ";   style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      nodejs   = { symbol = " ";  style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      python   = { symbol = " ";  style = "bg:base0D fg:base00"; format = "[ \${symbol}\${pyenv_prefix}(\${version} )(\\($virtualenv\\) )]($style)"; };
      java     = { symbol = " ";  style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      kotlin   = { symbol = " ";  style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      haskell  = { symbol = " ";  style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      php      = { symbol = " ";  style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      ruby     = { symbol = " ";  style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      scala    = { symbol = " ";  style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      dart     = { symbol = " ";  style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      deno     = { symbol = " ";  style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      bun      = { symbol = " ";  style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      elixir   = { symbol = " ";  style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      lua      = { symbol = " ";  style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      nim      = { symbol = "󰆥 ";  style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      ocaml    = { symbol = " ";  style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      perl     = { symbol = " ";  style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      purescript = { symbol = "<=> "; style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      swift    = { symbol = " ";  style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      zig      = { symbol = " ";   style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      dotnet   = { symbol = "󰪮 ";  style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      elm      = { symbol = " ";  style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      erlang   = { symbol = " ";  style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      gleam    = { symbol = "⭐ ";  style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      julia    = { symbol = " ";  style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      raku     = { symbol = "🦋 ";  style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      red      = { symbol = "🔺 ";  style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      vlang    = { symbol = "V ";  style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };
      typst    = { symbol = "t ";  style = "bg:base0D fg:base00"; format = "[ $symbol($version) ]($style)"; };

      nix_shell = {
        symbol = " ";
        style = "bg:base0D fg:base00";
        format = "[ $symbol$state( \\($name\\)) ]($style)";
      };

      # --- Cloud / контейнеры (base0C) --------------------------------------
      docker_context = { symbol = " "; style = "bg:base0C fg:base00"; format = "[ $symbol$context ]($style)"; };
      kubernetes     = { disabled = false; symbol = "󱃾 "; style = "bg:base0C fg:base00"; format = "[ $symbol$context( \\($namespace\\)) ]($style)"; };
      terraform      = { symbol = "󱁢 "; style = "bg:base0C fg:base00"; format = "[ $symbol$version$workspace ]($style)"; };
      package        = { symbol = "󰏗 "; style = "bg:base0C fg:base00"; format = "[ $symbol$version ]($style)"; };
      conda          = { symbol = " "; style = "bg:base0C fg:base00"; format = "[ $symbol$environment ]($style)"; };
      aws            = { symbol = "󰸏 "; style = "bg:base0C fg:base00"; format = "[ $symbol($profile )(\\($region\\) )]($style)"; };
      gcloud         = { symbol = "󱇶 "; style = "bg:base0C fg:base00"; format = "[ $symbol$account(@$domain)(\\($region\\)) ]($style)"; };
      azure          = { symbol = "󰠅 "; style = "bg:base0C fg:base00"; format = "[ $symbol($subscription) ]($style)"; };

      # --- Правая часть: cmd_duration + clock (base0E) ---------------------
      cmd_duration = {
        min_time = 500;
        style = "bg:base0E fg:base00";
        format = "[ 󱎫 $duration ]($style)";
      };

      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:base0E fg:base00";
        format = "[ 󰥔 $time ]($style)";
      };

      # --- Prompt символ ----------------------------------------------------
      character = {
        success_symbol = "[❯](bold fg:base0B)";
        error_symbol   = "[❯](bold fg:base08)";
        vimcmd_symbol  = "[❮](bold fg:base0D)";
      };

      line_break = { disabled = false; };
    };
  };
}
