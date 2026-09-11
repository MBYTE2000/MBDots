{ config, pkgs, lib, ... }:
# Wazuh agent — не является пакетом nixpkgs, ставится через wazuh-setup из .deb.
# Здесь только окружение nix-ld, пользователь и helper-скрипты.
{
  config = lib.mkIf config.myConfig.services.wazuh.enable {
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
      glibc
      zlib
      openssl
      libgcc
      stdenv.cc.cc.lib
      libpcap
      libxml2
      curl
    ];

    users.users.wazuh = {
      isSystemUser = true;
      group = "wazuh";
      home = "/var/ossec";
      createHome = true;
      shell = pkgs.bash;
      uid = 500;
      description = "Wazuh Agent User";
    };
    users.groups.wazuh = { gid = 500; };

    system.activationScripts.wazuh-config = {
      text = ''
        mkdir -p /var/ossec/etc /var/ossec/logs /var/ossec/var/run /var/ossec/var/db /var/ossec/queue
        chown -R wazuh:wazuh /var/ossec
        chmod 750 /var/ossec
        chmod 770 /var/ossec/var/run
        chmod 770 /var/ossec/var/db
        chmod 770 /var/ossec/queue
        chmod 770 /var/ossec/logs
        chmod 770 /var/ossec/etc

        if [ -f "/var/ossec/etc/ossec.conf" ]; then
          sed -i 's/MANAGER_IP/10.50.0.25/g' /var/ossec/etc/ossec.conf
          if ! grep -q "<address>.*</address>" /var/ossec/etc/ossec.conf; then
            cat > /var/ossec/etc/ossec.conf << 'EOF'
      <ossec_config>
        <user>wazuh</user>
        <group>wazuh</group>
        <client>
          <server>
            <address>10.50.0.25</address>
            <protocol>tcp</protocol>
            <port>1514</port>
          </server>
          <config-profile>nixos</config-profile>
          <notify_time>10</notify_time>
          <time-reconnect>60</time-reconnect>
          <auto_restart>yes</auto_restart>
          <crypto_method>aes</crypto_method>
        </client>
        <logging>
          <log_format>plain</log_format>
          <level>2</level>
        </logging>
      </ossec_config>
      EOF
          fi
        else
          cat > /var/ossec/etc/ossec.conf << 'EOF'
      <ossec_config>
        <user>wazuh</user>
        <group>wazuh</group>
        <client>
          <server>
            <address>10.50.0.25</address>
            <protocol>tcp</protocol>
            <port>1514</port>
          </server>
          <config-profile>nixos</config-profile>
          <notify_time>10</notify_time>
          <time-reconnect>60</time-reconnect>
          <auto_restart>yes</auto_restart>
          <crypto_method>aes</crypto_method>
        </client>
        <logging>
          <log_format>plain</log_format>
          <level>2</level>
        </logging>
      </ossec_config>
      EOF
        fi

        chown wazuh:wazuh /var/ossec/etc/ossec.conf
        chmod 660 /var/ossec/etc/ossec.conf
      '';
      deps = [];
    };

    system.activationScripts.wazuh-links = {
      text = ''
        mkdir -p /usr/local/bin
        ln -sf /var/ossec/bin/wazuh-control /usr/local/bin/wazuh-control 2>/dev/null || true
        ln -sf /var/ossec/bin/manage_agents /usr/local/bin/manage_agents 2>/dev/null || true
      '';
      deps = [];
    };

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "wazuh-setup" ''
        echo "=== Установка Wazuh агента на NixOS ==="
        if [ -f "/var/ossec/bin/wazuh-control" ]; then
          echo "Wazuh агент уже установлен"
          sudo /var/ossec/bin/wazuh-control status
          exit 0
        fi
        INSTALL_DIR="/tmp/wazuh-install-$(date +%s)"
        mkdir -p "$INSTALL_DIR"; cd "$INSTALL_DIR"
        wget -q --show-progress -O wazuh-agent.deb https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.14.3-1_amd64.deb
        [ ! -f "wazuh-agent.deb" ] && { echo "Ошибка скачивания"; exit 1; }
        ar x wazuh-agent.deb
        DATA_FILE=""
        for ext in xz gz zst; do
          [ -f "data.tar.$ext" ] && DATA_FILE="data.tar.$ext" && break
        done
        [ -z "$DATA_FILE" ] && { echo "Нет data.tar"; exit 1; }
        tar -xf "$DATA_FILE"
        [ -d "var/ossec" ] || { echo "Плохая структура пакета"; exit 1; }
        sudo cp -r var/ossec /var/
        sudo chmod -R 755 /var/ossec
        cd /; sudo rm -rf "$INSTALL_DIR"
        [ -f "/var/ossec/etc/ossec.conf" ] && sudo sed -i 's/MANAGER_IP/10.50.0.25/g' /var/ossec/etc/ossec.conf
        sudo /var/ossec/bin/wazuh-control start
        sleep 2
        sudo /var/ossec/bin/wazuh-control status
      '')
      (pkgs.writeShellScriptBin "wazuh-service" ''
        case "$1" in
          start)   sudo /var/ossec/bin/wazuh-control start ;;
          stop)    sudo /var/ossec/bin/wazuh-control stop ;;
          restart) sudo /var/ossec/bin/wazuh-control restart ;;
          status)  sudo /var/ossec/bin/wazuh-control status ;;
          logs)    sudo tail -f /var/ossec/logs/ossec.log ;;
          *) echo "Использование: wazuh-service {start|stop|restart|status|logs}" ;;
        esac
      '')
    ];
  };
}
