# PEAK Russia Helper

Небольшой Windows-helper для ошибки **`Photon: ClientTimeout`** в PEAK, которая у части пользователей в России проявляется так: игра успевает подключиться, но через 10–15 секунд сессия обрывается.

Решение проверено на реальной проблемной установке: рабочая комбинация использует [Flowseal/zapret-discord-youtube](https://github.com/Flowseal/zapret-discord-youtube) с обработкой игрового TCP/UDP-трафика, `IPSet Filter = any` и стратегией `ALT10`.

## Быстрый запуск

1. Скачайте два файла из этого репозитория:
   - `PEAK_Photon_FIX.bat`
   - `PEAK_Photon_STOP.bat`
2. Запустите `PEAK_Photon_FIX.bat`.
3. Подтвердите запрос UAC / запуск от администратора.
4. Скрипт сам скачает официальный Flowseal `zapret-discord-youtube 1.10.2`, проверит SHA256, настроит нужный режим и запустит PEAK через Steam.
5. После игры запустите `PEAK_Photon_STOP.bat`.

## Что делает FIX

- создаёт отдельную папку `C:\PEAK-Photon-zapret`;
- скачивает только официальный архив Flowseal `1.10.2` с GitHub;
- проверяет SHA256 архива;
- включает **Game Filter = TCP + UDP**;
- включает **IPSet Filter = any**;
- запускает `general (ALT10).bat`;
- временно останавливает другой `winws.exe` / службу `zapret`, чтобы не запускать две конфликтующие стратегии одновременно;
- запускает PEAK через `steam://rungameid/3527290`.

## SHA256

Для официального архива `zapret-discord-youtube-1.10.2.zip` ожидается:

```text
5EAAC9FB2E4B1ABD693487452A3FF3F4DFE9578A45F9DDD DFA4BC1F5A6BB62D5
```

В скрипте этот же SHA256 хранится с техническим пробелом и перед сравнением пробел удаляется. Фактическое значение без пробелов:

```text
5EAAC9FB2E4B1ABD693487452A3FF3F4DFE9578A45F9DDDDFA4BC1F5A6BB62D5
```

## Windows Defender

`winws.exe` / WinDivert иногда определяется защитными продуктами как RiskTool/PUA. FIX **не отключает Defender целиком**. Он добавляет временное исключение только для:

```text
C:\PEAK-Photon-zapret
```

`PEAK_Photon_STOP.bat` удаляет это исключение, если оно было создано helper'ом.

## Остановка и восстановление

`PEAK_Photon_STOP.bat`:

- завершает `winws.exe`;
- восстанавливает исходный `ipset-all.txt`, если helper сделал резервную копию;
- удаляет `game_filter.enabled`;
- снова запускает службу `zapret`, если до старта helper'а она уже работала;
- удаляет временное исключение Microsoft Defender.

## Важно

Это не официальный инструмент PEAK, Photon, Landfall или Flowseal. Репозиторий содержит только небольшой wrapper/launcher. Сам `zapret-discord-youtube` скачивается напрямую из официального репозитория Flowseal и проверяется по SHA256 перед использованием.

Режим `IPSet Filter = any` специально широкий, поэтому не стоит оставлять его включённым без необходимости. После игры используйте `PEAK_Photon_STOP.bat`.

## Credits

- [Flowseal/zapret-discord-youtube](https://github.com/Flowseal/zapret-discord-youtube)
- [bol-van/zapret](https://github.com/bol-van/zapret)

---

Если PEAK снова изменит сетевую логику или Flowseal поменяет структуру релизов, helper может потребовать обновления.
