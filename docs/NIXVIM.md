# NIXVIM — как пользоваться

Конфиг живёт в `home/nixvim.nix`. Запуск: `nvim` в любом терминале.

Ниже — всё что настроено сверх базового vim, с примерами workflow.

## Опции редактора

| Опция | Значение | Что делает |
|---|---|---|
| `number` + `relativenumber` | true | Абсолютный номер на текущей строке; относительные — вокруг. `5j` прыгнет ровно 5 вниз |
| `shiftwidth` / `tabstop` | 2 | Отступ 2 пробела, Tab → 2 пробела |
| `expandtab` | true | Всегда пробелы, никаких `\t` |
| `signcolumn = "yes"` | | Колонка слева всегда видна (для LSP-diagnostics) |
| `cursorline` | true | Подсветка текущей строки |
| `scrolloff` | 6 | Скролл начинается за 6 строк до края |
| `wrap` | false | Длинные строки не переносятся |
| `<leader>` | `<Space>` | Все команды `<Leader>xx` начинаются пробелом |

## Кастомные горячие клавиши

Всё, что добавлено сверх обычного vim:

### Neo-tree (файловое дерево)
| Клавиша | Действие |
|---|---|
| `Ctrl+n` | Открыть/закрыть панель дерева слева |
| `Ctrl+b` | Всплывающий overlay со списком открытых буферов |

**Внутри дерева** (когда фокус на панели):
- `<Enter>` / `o` — открыть файл
- `s` — открыть в вертикальном split, `S` — в горизонтальном
- `t` — открыть в новом табе
- `a` — создать файл (закончи имя `/` — будет каталог)
- `d` — удалить, `r` — переименовать, `m` — переместить
- `c` — copy, `p` — paste (после `y` — yank)
- `H` — показать/скрыть скрытые файлы
- `R` — refresh
- `?` — help с полным списком команд
- `q` или `Ctrl+n` — закрыть

### ToggleTerm (терминал внутри nvim)
| Клавиша | Действие |
|---|---|
| `Ctrl+t` | Открыть/закрыть terminal-split снизу (30% высоты) |
| `Esc` (в терминале) | Из терминального режима в normal-mode (навигация по выводу) |
| `i` / `a` | Обратно в терминальный ввод |
| `:2ToggleTerm` | Открыть второй независимый терминал |

Полезно для быстрого `git status`, запуска тестов, `nixos-rebuild dry-build` без выхода из nvim.

### Claude Code (`<Leader>a…`)
| Клавиша | Действие |
|---|---|
| `<Space>ac` | Toggle Claude Code panel (справа, 40% ширины) |
| `<Space>af` | Focus на Claude panel (курсор туда) |
| `<Space>as` (visual mode) | Отправить выделение в Claude |
| `<Space>aa` | Accept diff который Claude предлагает |
| `<Space>ad` | Deny diff |

**Workflow с Claude:**
1. Открой файл. Выдели визуальным режимом (`v` или `V`) кусок.
2. `<Space>as` — код летит в Claude как контекст.
3. `<Space>ac` открывает панель — задай вопрос "рефактори" / "объясни" / "напиши тесты".
4. Claude предлагает diff → `<Space>aa` применить или `<Space>ad` отклонить.

Бинарь `claude` в PATH обязателен — у тебя он стоит через `home/packages.nix`.

## LSP (Language Server Protocol)

Включены серверы:
- **nixd** — для `.nix` файлов (авто-completion атрибутов, jump-to-definition в nixpkgs)
- **clangd** — для C/C++

По умолчанию nvim привязывает стандартные LSP-клавиши (можно и переопределить):

| Клавиша | Действие |
|---|---|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | Show references |
| `gi` | Go to implementation |
| `K` | Hover-документация |
| `<Ctrl-o>` | Назад по jump-list |
| `<Ctrl-i>` | Вперёд |
| `[d` / `]d` | Prev/next diagnostic |
| `<leader>ca` | Code action (если настроено) |

Открой `flake.nix` — попробуй `gd` на `nixpkgs.lib.nixosSystem`.

## Treesitter

Автоматическая подсветка синтаксиса, indent, folding для языков:
`kdl`, `nix`, `bash`, `lua`, `json`, `yaml`, `toml`, `markdown`(+inline), `javascript`, `typescript`, `python`, `rust`, `c`, `cpp`.

Значит: `.kdl` файлы niri, `home/niri/sections/*.nix` (KDL-строки внутри Nix) — цветные. Nothing to configure — работает.

## lualine

Статус-строка внизу (mode, файл, git branch, LSP-diagnostic count, позиция). Ничего нажимать не надо, просто смотри.

## Cheat sheet для новичка

Если базовый vim знаешь, эти вещи полезны как next-level:

**Навигация**
- `%` — прыгнуть на парный `()`, `{}`, `[]`
- `*` / `#` — искать слово под курсором вперёд/назад
- `f<char>` / `F<char>` — прыгнуть на символ в строке (вперёд/назад)
- `t<char>` — прыгнуть до символа (не на)
- `;` / `,` — повторить f/t вперёд/назад
- `%` — 50% файла, `100%` — конец, `gg` — начало, `G` — конец, `<N>G` — строка N
- `Ctrl+d` / `Ctrl+u` — полстраницы вниз/вверх
- `zz` / `zt` / `zb` — центрировать/наверх/вниз текущую строку

**Правка**
- `ci"` / `ci(` / `cit` — change-inside "…" / (…) / `<tag>…</tag>`
- `di"` / `da"` — delete-inside / delete-around
- `yi(` / `ya{` — yank-inside/around
- `>>` / `<<` — сдвинуть строку вправо/влево на shiftwidth
- `.` — повторить последнюю правку
- `u` / `Ctrl+r` — undo / redo
- `J` — склеить строку со следующей

**Multi-cursor подобное (без плагина)**
- `Ctrl+v` — visual block (столбец). Выдели → `I<text><Esc>` — вставить в начало каждой строки.
- `:%s/foo/bar/gc` — replace-all с подтверждением

**Окна**
- `Ctrl+w s` / `Ctrl+w v` — split horizontal / vertical
- `Ctrl+w h/j/k/l` — переключение между split'ами
- `Ctrl+w q` — закрыть split
- `Ctrl+w =` — уравнять размеры

**Буферы vs таблицы vs окна**
- Buffer — открытый файл (не путь, а состояние). `:ls` — список.
- `:b <part-of-name>` — переключиться на буфер по подстроке.
- `:bd` — закрыть буфер.
- Табы — контейнер для окон. `gt` / `gT` — next/prev tab.

**Регистры**
- `"ay` — yank в регистр `a`. `"ap` — paste оттуда.
- `"+y` / `"+p` — системный clipboard.
- `:reg` — посмотреть все регистры.

**Marks (закладки)**
- `ma` — поставить mark `a` на текущей строке.
- `'a` — прыгнуть на строку с mark. `` `a `` — на точную позицию.

## Типичный workflow под этот конфиг

**Правка Nix-конфига:**
1. `nvim /etc/nixos` — открыт flake.
2. `Ctrl+n` — дерево слева.
3. Стрелками/`j`/`k` до нужного `.nix`, `<Enter>`.
4. Правишь. Treesitter подсвечивает.
5. `gd` на `pkgs.foo` — прыгаешь в определение из nixpkgs.
6. `:w` сохранить.
7. `Ctrl+t` — открывается терминал внизу.
8. `update` — пересборка. Смотришь diagnostics.
9. `Esc` из терминала (в normal-mode), `Ctrl+t` — прячется.

**Debug/refactor с Claude:**
1. Открой файл. Найди проблемный кусок.
2. `V` (visual line) + движение вниз, выдели функцию.
3. `<Space>as` → код в Claude.
4. `<Space>ac` → панель справа. Пиши "объясни этот код" / "оптимизируй".
5. Если Claude предложил замену → диф покажется → `<Space>aa` accept.

**Быстрая ориентация в чужом коде:**
1. `nvim <path>`.
2. `Ctrl+n` — структура каталога.
3. `<Space>as` на непонятный фрагмент → Claude объяснит.
4. `gd` на функцию → её определение.
5. `Ctrl+o` — назад.

## Полезные команды в normal-mode

```
:e <file>        открыть файл
:w               сохранить
:wq / :x         сохранить и выйти
:q!              выйти без сохранения
:sp / :vsp       split (h/v)
:tabnew          новый таб
:%s/A/B/g        replace всех A → B в файле
:noh             убрать подсветку последнего поиска
:LspInfo         статус LSP серверов
:TSPlaygroundToggle — не установлен, но `:TSHighlightCapturesUnderCursor` — что подсвечивает treesitter под курсором
:Neotree focus   переключиться в дерево
:ClaudeCode      = <Space>ac
```

## Куда лезть править

- `home/nixvim.nix` — весь конфиг.
- Добавить keymap → массив `keymaps`, формат:
  ```nix
  { key = "<C-x>"; mode = "n"; action = ":Foo<CR>"; options.desc = "..."; }
  ```
- Включить ещё один LSP → `plugins.lsp.servers.<lang>.enable = true`.
- Добавить treesitter грамматику → в `grammarPackages` список.
- Свой Lua-снипет → в `extraConfigLua = ''...''`.

После правок: `update` → nvim подхватит новую конфигурацию при следующем запуске.
