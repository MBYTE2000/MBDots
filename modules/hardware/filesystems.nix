{ ... }:
# Второй SSD (Samsung 1TB, ext4). Симлинки из ~ на /mnt/data больше не
# управляются Nix — если они есть, они остались от предыдущей активации
# модуля data-offload и продолжают работать.
{
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/145e45fc-f562-44f7-a7f7-17799b1b4e54";
    fsType = "ext4";
  };
}
