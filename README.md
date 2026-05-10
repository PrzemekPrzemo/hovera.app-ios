# hovera.app-ios

Natywna aplikacja iOS dla systemu **Hovera** (zarządzanie ośrodkami
jeździeckimi). Jedna binarka, cztery role (Klient/Właściciel,
Instruktor, Stajenny, Manager) wybierane na podstawie
`tenant_memberships.role` po zalogowaniu.

## Stack

- iOS 17+, Swift 5.9+
- SwiftUI (UIKit tylko gdzie wymagane: AppDelegate dla APNs)
- GRDB.swift jako lokalna baza (offline-first)
- URLSession + async/await dla API
- BGTaskScheduler + NWPathMonitor dla auto-sync po powrocie sieci
- UserNotifications + APNs dla pushy
- String Catalogs (`.xcstrings`) dla i18n PL/EN
- XcodeGen do generowania `Hovera.xcodeproj`

## Architektura

```
Hovera/                       # main app target (SwiftUI lifecycle)
  HoveraApp.swift
  AppDelegate.swift           # APNs hooks
  RootView.swift              # routing: Login → TenantPicker → RoleHome
  Resources/
    Localizable.xcstrings     # PL (default) + EN
    Assets.xcassets           # brand colors + app icon

Packages/Core/                # local SPM package z 5 produktami
  Sources/CoreNetworking/     # APIClient, AuthInterceptor, Endpoint, APIError
  Sources/CorePersistence/    # GRDB Database, Records, MutationQueue, SyncCursor
  Sources/CoreSync/           # SyncEngine (actor), Reachability, BackgroundSync
  Sources/CoreAuth/           # AuthService, KeychainStore, Session
  Sources/CoreDesignSystem/   # HoveraTheme (Ochre #A8956B + Deep Brown #3D2E22)

Packages/Features/            # local SPM package z 5 produktami
  Sources/SharedFeature/      # RoleSwitcher, TenantPicker, AvatarView
  Sources/ClientFeature/      # ekrany klienta
  Sources/InstructorFeature/  # ekrany instruktora
  Sources/GroomFeature/       # ekrany stajennego (offline-first)
  Sources/ManagerFeature/     # ekrany managera (split-view na iPadzie)
```

## Branding

1:1 z panelu Filament (`AppPanelProvider`):

| Token | Hex | Zastosowanie |
|---|---|---|
| `brand/primary` | `#A8956B` | Ochre — akcent, CTA, aktywne stany |
| `brand/onPrimary` | `#FFFFFF` | tekst na primary |
| `brand/secondary` | `#3D2E22` | Deep Brown — nagłówki, sidebar, `gray` ekwiwalent |
| `brand/background` | `#FBF8F1` | tło domyślne (cream) |
| `brand/surface` | `#FFFFFF` | karty |
| `brand/textPrimary` | `#1F1611` | tekst |
| `brand/textMuted` | `#6F5F52` | tekst drugorzędny |

Nazwa marki: **`hovera`** (małymi literami, jak w panelu).

## Build

```sh
brew install xcodegen
xcodegen generate
open Hovera.xcodeproj
```

Lub z linii komend:

```sh
xcodebuild -scheme Hovera -destination 'platform=iOS Simulator,name=iPhone 15' build
xcodebuild test -scheme Hovera -destination 'platform=iOS Simulator,name=iPhone 15'
xcodebuild test -scheme Hovera -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch)'
```

## API

Apka rozmawia z `hovera.app-sys` przez `/api/v1/...` (Bearer token,
nagłówek `X-Tenant-Id`). Pełen kontrakt: `docs/API.md` w repo `hovera.app-sys`.

- `BASE_URL` w `Hovera/Configuration/Production.xcconfig` (i `Staging.xcconfig`)
- token w Keychain (`kSecAttrAccessibleAfterFirstUnlock`)
- `X-Tenant-Id` dokładany przez `AuthInterceptor`

## Sync

- `pull` cyklicznie (15 min, BGAppRefreshTask) + na każde silent push
  (`content-available: 1`).
- `push` drenuje `mutation_queue` z exponential backoff (1/2/4/8s, cap 5 min).
- konflikty surface'owane przez `AsyncStream<ConflictEvent>` do UI.
- zdjęcia: sha256 + presigned PUT, mutacja referuje `storage_key`.

## CI

`.github/workflows/ios.yml` — buduje + testuje na macOS runnerze
(iPhone 15 + iPad Pro destinations).
