{ config, lib, ... }:
# Второй SSD (Samsung 1TB, ext4) — куда выгружаются тяжёлые пользовательские
# каталоги. Монтируется только когда myConfig.hardware.dataDisk.enable = true
# (у этого хоста есть второй NVMe; на других машинах его нет).
lib.mkIf config.myConfig.hardware.dataDisk.enable {
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/145e45fc-f562-44f7-a7f7-17799b1b4e54";
    fsType = "ext4";
    # noatime — меньше пишем на SSD; nofail — не блокирует boot если диск отвалился.
    options = [ "noatime" "nofail" "x-systemd.device-timeout=10s" ];
  };
}
