# Kasm Zen Browser образы

Пользовательские образы [Kasm Workspaces](https://kasmweb.com) с [Zen Browser](https://zen-browser.app) в качестве рабочего стола.

## Образы

- `kasm-zen` — Zen Browser с предустановленными uBlock Origin и Dark Reader, тёмной GTK/xfwm4 темой, DuckDuckGo в качестве поисковой системы по умолчанию.
- `kasm-zen-mintcifra` — всё из `kasm-zen` плюс доверенные корневые/подчинённые сертификаты УЦ Минцифры России в системном хранилище и NSS-базе браузера.

## Возможности

- Zen Browser устанавливается из последнего релиза GitHub.
- uBlock Origin и Dark Reader предустановлены как управляемые расширения.
- Мастер первого запуска отключён; браузер открывается на пустой вкладке.
- Запрос «Сделать Zen браузером по умолчанию» отключён (`browser.shell.checkDefaultBrowser=false`).
- DuckDuckGo задаётся поисковой системой по умолчанию через `policies.json`.
- Тёмная тема GTK/xfwm4 `Greybird-dark`, чтобы заголовок окна совпадал с интерфейсом браузера.
- Оптимизация под одноприложный рабочий стол (без панели, развёрнутое окно, ограниченный выбор файлов, блокировка выхода через файловый менеджер).

## Требования

- Docker с BuildKit.
- Базовый образ `core-ubuntu-jammy` из реестра Kasm (автоматически определяется последний тег `rolling-weekly` либо задаётся через `BASE_TAG`).

## Сборка

```bash
OWNER=your-gh-user scripts/build.sh zen
OWNER=your-gh-user scripts/build.sh zen-mintcifra
```

Дополнительные переменные окружения:

| Переменная   | Значение по умолчанию | Описание                                     |
| ------------ | --------------------- | -------------------------------------------- |
| `BASE_IMAGE` | `core-ubuntu-jammy`   | Имя базового образа Kasm                     |
| `BASE_TAG`   | автоопределение       | Тег базового образа (например `1.19.0-rolling-weekly`) |
| `REGISTRY`   | `ghcr.io`             | Реестр образов                               |
| `OWNER`      | (обязательно)         | Владелец/организация в реестре               |
| `TAGS`       | `rolling-weekly`      | Список тегов через запятую                   |

## Смоук-тест

Запускает образ и проверяет, что KasmVNC отвечает на health-эндпоинте, а процесс Zen жив:

```bash
OWNER=your-gh-user scripts/smoke-test.sh
```

## Локальный запуск

```bash
docker run -d \
  --name kasm-zen \
  -p 6901:6901 \
  -e VNC_PW=kasmtest \
  --shm-size=512m \
  ghcr.io/your-gh-user/kasm-zen:rolling-weekly
```

Подключитесь к `https://localhost:6901` и войдите с VNC-паролем.

## Структура

```
dockerfile-kasm-zen               Стандартный образ Zen
dockerfile-kasm-zen-mintcifra     Образ Zen с сертификатами УЦ Минцифры
scripts/build.sh                  Обёртка сборки
scripts/detect-latest-core-tag.sh Определение последнего тега базового образа Kasm
scripts/smoke-test.sh             Смоук-тест здоровья контейнера
src/ubuntu/install/
  certificates/                   Корневые/подчинённые сертификаты УЦ Минцифры
  close_browser_breakout_via_file_manager/
  gtk/                            Ограниченный GTK-выбор файлов
  misc/                           Усиление безопасности одноприложного десктопа
  zen/                            Скрипты установки, расширения, скрипт запуска
.github/workflows/weekly-build.yml Еженедельная сборка в GHCR + смоук-тест
```

## GitHub Actions

Workflow `weekly-build.yml` собирает оба образа и публикует их в GHCR еженедельно (вторник, 04:00 UTC), с поддержкой ручного запуска через `workflow_dispatch` и переопределением тега через `base_tag`.
