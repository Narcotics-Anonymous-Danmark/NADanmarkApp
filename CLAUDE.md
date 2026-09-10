# CLAUDE.md

Read `AGENTS.md` first; it is the source of truth for how to work here.

- Coding rules: `docs/CODING_GUIDELINES.md`. They are enforced by `./bin/na check`; do not argue with the linter, fix the code.
- Specs: `openspec/specs/<capability>/spec.md`. New work starts with `/opsx:propose`, is implemented with `/opsx:apply`, and ends with `/opsx:archive`.
- Legacy reference implementation: `../App/src/app` (Ionic). Port behaviour, not code.
- Before saying a task is done run `./bin/na check && ./bin/na test unit widget acceptance --coverage` and report the real output.
- Use `./bin/na` for every build, run, test and release action. Never raw `flutter`, `gradle` or `pod`.
- Never commit `env/release.json`, `app/ios/Flutter/Secrets.xcconfig`, keystores or anything under `.na-release/`.
- Never change version numbers except through `./bin/na release version`.
- Commit messages and PR titles follow Conventional Commits.
