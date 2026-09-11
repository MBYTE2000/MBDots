{ pkgs, ... }:
{
  users.users.mbyte = {
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [ "wheel" "lp" "scanner" "docker" "dialout" ];
    packages = with pkgs; [ tree ];
  };
}
