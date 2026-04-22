# Agent E-6 — Russian-Language Government Resources

**Target audience:** русскоязычные жители Эстонии (largest immigrant
language group; Advocat priority №1).
**Sources:** all Estonian government portals that publish Russian
versions.
**Fetched:** 2026-04-21.

## Государственные порталы с русской версией

| Ведомство / сайт | Русская версия |
|-------------------|----------------|
| Портал госуслуг eesti.ee | https://www.eesti.ee/ru |
| PPA (Департамент полиции и погранохраны) | https://www.politsei.ee/ru |
| MTA (Налогово-таможенный департамент) + e-MTA | https://www.emta.ee/ru |
| Sotsiaalkindlustusamet (Соцстрах) | https://sotsiaalkindlustusamet.ee/ru |
| Töötukassa (Биржа труда) | https://www.tootukassa.ee/ru |
| Tervisekassa (Мед. страхование) | https://www.tervisekassa.ee/ru |
| TTJA (Защита потребителей) | https://ttja.ee/ru |
| Integratsiooni Sihtasutus (Фонд интеграции) | https://www.integratsioon.ee/ru |

## Riigi Teataja (официальный вестник)

- Адрес: https://www.riigiteataja.ee/
- Ключевые законы переведены на русский. Поиск по
  estonian-russian (язык → "en-ru") в интерфейсе вестника.
- Не все акты переведены; некоторые переводы устарели —
  всегда проверять дату "consolidated version".

## Сервисы адаптации

### Integratsiooni Sihtasutus (MISA / INSA)

- https://www.integratsioon.ee/ru
- Бесплатные курсы эстонского A1 → B1 (программа Settle in Estonia
  для лиц, проживших в Эстонии < 5 лет)
- Курсы для получения гражданства: 160 часов на уровень
- Инфотелефон: 800 9999 (бесплатно в Эстонии), +372 6599 025 из-за рубежа
- Email: info@integratsiooniinfo.ee

### Settle in Estonia

- https://settleinestonia.ee/ru
- Программа модульная: Базовый модуль, Рабочий, Учебный, Семейный,
  Исследовательский, Модуль международной защиты
- Бесплатно для большинства новоприбывших

## Русскоязычные СМИ о эстонском праве

- **ERR.ee на русском** (Общественное вещание) — https://rus.err.ee
- **Postimees на русском** — https://rus.postimees.ee
- **Delfi на русском** — https://rus.delfi.ee

Хотя эти ресурсы **не являются официальными источниками права** (не
заменяют Riigi Teataja), они часто первыми сообщают о изменениях,
комментируют судебные решения и дают переводы. Использовать как
вторичные/популяризаторские источники.

## Экстренные службы на русском

См. `docs/estonia-max/05-emergency.md`. Ключевые:
- **112** — общая экстренная служба (русский)
- **1247** — государственная инфолиния (24/7, русский)
- **116 006** — помощь жертвам (24/7, русский, анонимно)
- **116 111** — детская линия (24/7, русский)

## Бесплатная юрпомощь на русском

- **HUGO.legal / JURIST AITAB** — https://www.juristaitab.ee
  - 2 часа бесплатной консультации
  - Требование по доходу: ≤ €1200/мес брутто
  - ET/EN/RU
- **Eesti Advokatuur** — поиск русскоязычных адвокатов:
  https://www.advokatuur.ee/en/search-attorney

## Практика для AI Advocat

Когда пользователь пишет на русском:

1. **Подтверждать** доступность официальных источников на русском —
   снимает страх "я плохо знаю эстонский".
2. **Ссылаться** на русские версии порталов в первую очередь.
3. **Предупреждать**, что официальное делопроизводство в судах
   ведётся **на эстонском** — потребуется перевод документов или
   адвокат.
4. **Указывать** телефоны экстренных служб с русскоязычной поддержкой,
   если ситуация острая.

Машиночитаемый источник: `assets/legal/estonia/russian_resources.json`
+ константа `EstonianMaxResources.russianResourceNotice` в
`lib/services/estonian_max_resources.dart`.
