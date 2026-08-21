# Everyday Wholesale

A grocery ordering app — customers browse products and order; admins/managers manage the catalog and fulfil orders. Single Flutter codebase targeting Android, iOS, and Web.

## Stack

- **Flutter** (single codebase, no platform-specific forks)
- **State management**: pure BLoC (`flutter_bloc`) — no Cubit
- **Architecture**: Clean Architecture (`data` / `domain` / `presentation`) + feature-first, under `lib/features/`
- **DI**: `get_it` + `injectable` (code-gen)
- **Routing**: `go_router`
- **Error handling**: `fpdart` (`Either<Failure, T>`)
- **Localization**: `easy_localization` (`assets/translations/`)
- **Backend**: Firebase (not yet integrated — see `docs/IMPLEMENTATION.md`)

## Project docs

- [`docs/PLAN.md`](docs/PLAN.md) — requirements, architecture decisions, tech-stack rationale, roadmap
- [`docs/IMPLEMENTATION.md`](docs/IMPLEMENTATION.md) — what's built vs. what's next, phase by phase

## Getting started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generates DI wiring
flutter run
```

## Project structure

```
lib/
  app/        # bootstrap + root widget
  config/     # DI container, routing
  core/       # cross-cutting: errors, usecase base, constants, utils
  shared/     # cross-feature theme, widgets, utils
  features/   # one folder per feature, each data/domain/presentation
```

Every feature follows the same pattern — see `lib/features/home` or `lib/features/product` for a fully-wired example before adding a new one.
