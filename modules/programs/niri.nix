{ config, lib, ... }:
{
  config = lib.mkIf config.myConfig.programs.niriProgram.enable {
    programs.niri.enable = true;
  };
}
