# Project Workflow

After every Claude Code request that changes app code:
1. Run unit tests: `xcodebuild test -project WheresMySpace.xcodeproj -scheme WheresMySpace -destination 'platform=macOS'`
2. Run `make dev` to build and open the app.
3. Propose a commit message and wait for explicit approval before committing (per global CLAUDE.md).
