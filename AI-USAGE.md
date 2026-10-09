# AI usage

_TODO (author): this is a template. Record every place AI tools helped, and what you changed or checked yourself._

| Tool | What it was used for | What you changed or checked yourself |
| --- | --- | --- |
| Claude | Reviewed the project, drafted fixes for authentication, card deletion, the trade list, and the delete UI | _describe how you tested and edited it_ |
| Claude | Added maximum lengths to every text field (`lib/config/field_limits.dart`), matching database check constraints in `supabase/schema.sql`, a darker placeholder color that meets 4.5:1 contrast, tests in `test/field_limits_test.dart`, and the matching documentation (October 9, 2026). The Flutter app could not be built or run in that session; the SQL was run against a local PostgreSQL 16 | _describe how you ran `flutter analyze`, `flutter test` and tried the app, and the screens you checked_ |
| Claude | Reviewed and updated the documentation in `docs/` and the `.md` files against the code (October 9, 2026) | _describe what you checked yourself_ |
