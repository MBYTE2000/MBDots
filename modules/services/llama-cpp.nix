{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.myConfig.services.llama-cpp.enable {
    nixpkgs.config.allowUnfree = true;

    # Бинарники llama-cli, llama-server в PATH
    environment.systemPackages = [
      (pkgs.llama-cpp.override { cudaSupport = true; })
    ];

    # Сервис установлен, но не стартует автоматически
    services.llama-cpp = {
      enable = true;
      package = pkgs.llama-cpp.override { cudaSupport = true; };
      settings = {
        host = "127.0.0.1";
        port = 8080;
        # model = "/path/to/your/model.gguf";
      };
    };

    systemd.services.llama-cpp.wantedBy = lib.mkForce [ ];
  };
}
