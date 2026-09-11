# Кастомизация

## Добавить новый пакет

**Системный** — в `modules/programs/system-packages.nix`:

```nix
environment.systemPackages = with pkgs; [
  ...
  htop        # <-- сюда
];
```

**Пользовательский (home-manager)** — в `home/packages.nix`:

```nix
home.packages = with pkgs; [
  ...
  discord     # <-- сюда
];
```

## Добавить новый сервис

1. Создай `modules/services/foo.nix`:

    ```nix
    { config, lib, ... }:
    {
      config = lib.mkIf config.myConfig.services.foo.enable {
        services.foo.enable = true;
        # ... остальные опции
      };
    }
    ```

2. Зарегистрируй опцию в `modules/core/options.nix`:

    ```nix
    services.foo.enable = lib.mkEnableOption "Foo daemon";
    ```

3. Включи на хосте в `hosts/nixos/default.nix`:

    ```nix
    myConfig.services.foo.enable = true;
    ```

4. `update`

Файл `foo.nix` автоматически попадёт в imports через `importDir`.

## Добавить новый категорийный подкаталог

```bash
mkdir /etc/nixos/modules/my-category
```

Создай `modules/my-category/default.nix`:

```nix
{ lib, ... }:
let myLib = import ../../lib { inherit lib; };
in { imports = myLib.importDir ./.; }
```

Затем клади туда любые `.nix` файлы — они подхватятся автоматически, потому что
`modules/default.nix` уже импортирует все поддиректории.

## Добавить второй хост (ноутбук и т.п.)

1. Скопируй `hosts/nixos` в `hosts/laptop`.
2. Замени `hardware-configuration.nix` и `gpu/current.nix` на актуальные для ноута.
3. Добавь в `flake.nix`:

    ```nix
    nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [ ./hosts/laptop /* + home-manager block */ ];
    };
    ```

4. Собирай через `nixos-rebuild switch --flake /etc/nixos#laptop`.

## Смена GPU

Скрипт `install.sh` умеет класть один из `gpu/{nvidia,intel,amd,none}.nix`
в `gpu/current.nix`. Вручную:

```bash
sudo cp gpu/amd.nix gpu/current.nix
update
```

## Смена темы Stylix

Обои: замени `WP.png` рядом с `flake.nix` или поменяй путь в
`modules/desktop/stylix.nix`. Полярность: `polarity = "dark"|"light"`.

## Как временно отключить фичу

В `hosts/nixos/default.nix`:

```nix
myConfig.desktop.stylix.enable = false;    # выключит Stylix
myConfig.programs.zsh.enable = false;      # выключит zsh полностью
```

## Полезное

```bash
# Показать все опции моего конфига:
nix eval /etc/nixos#nixosConfigurations.nixos.options.myConfig --apply builtins.attrNames

# Собрать в отдельную директорию (не переключаться):
nixos-rebuild build --flake /etc/nixos#nixos && ls -l result/

# Откатиться на предыдущее поколение:
sudo nixos-rebuild switch --rollback

# Список поколений:
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```
