# New Members Check In

iOS app for tracking attendance in a new-members class.

## Stack

- SwiftUI
- Supabase (`supabase-swift`)
- Xcode project (no external build system)

## Quick Start

1. Copy the config template:

```bash
cp Config/Secrets.xcconfig.template Config/Secrets.xcconfig
```

2. Edit `Config/Secrets.xcconfig`:

```xcconfig
SUPABASE_URL = https:\/\/<your-project-ref>.supabase.co
SUPABASE_PUBLISHABLE_KEY = sb_publishable_...
```

Notes:
- `Config/Secrets.xcconfig` is git-ignored.
- Use a Supabase publishable key (`sb_publishable_...`), not legacy JWT anon keys.

3. Open and run in Xcode:

```bash
open "New Members Check In.xcodeproj"
```

Run scheme: `New Members Check In`.

## Tests

Unit tests live in `New Members Check InTests/`.

## Security

Please see [SECURITY.md](SECURITY.md) for vulnerability reporting.

## License

See [LICENSE](LICENSE).
