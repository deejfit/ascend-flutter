# Ascend

A **Hunter Rank** finance app for tracking revenue and climbing the ranks. macOS desktop app built with Flutter.

## What it does

- **Revenue entries** — Log income by source (Freelance, App, Book, Coaching, etc.), with optional notes and date.
- **Hunter ranks** — Your rank (F → E → D → C → B → A → S → SS → SSS) is based on monthly revenue. Progress bars show how close you are to the next tier.
- **VAT** — Freelance amounts are stored excl. VAT (display shows incl. = ×1.21). Other sources are stored incl. VAT (excl. = ÷1.21). All totals and goals use incl. VAT.
- **Dashboard** — Current month vs. previous month, cumulative chart, source breakdown, monthly target (default €30,000), and a list of entries with edit/delete.
- **Hunter Pass** — Card with your best rank ever, best month, lifetime revenue, and first entry date.

Data is stored locally in SQLite. No cloud or account required.

## Requirements

- Flutter SDK (see `pubspec.yaml` for SDK constraint)
- macOS (app is currently targeting macOS only)

## Run

```bash
flutter pub get
flutter run -d macos
```

Release build:

```bash
flutter build macos
open build/macos/Build/Products/Release/ascend.app
```

## Data

Database path on macOS:

```
~/Library/Application Support/Ascend/ascend.db
```

## Project structure

- `lib/main.dart` — Entry point, DB init, locale, runApp
- `lib/app.dart` — MaterialApp and theme
- `lib/config/rank_config.dart` — Rank ladder (F–SSS) and default monthly target
- `lib/data/` — SQLite DB, models (RevenueEntry, RevenueSource), repositories
- `lib/domain/` — RankEngine, MetricsEngine (rank progress, VAT, totals)
- `lib/ui/` — App shell, dashboard (KPI, chart, month selector, entries list), Hunter Pass, add-entry modal
- `lib/utils/` — Formatters (currency), dates
- `lib/theme/` — Dark theme

## License

Private project. Not published to pub.dev.
