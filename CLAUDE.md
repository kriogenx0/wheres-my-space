# Project Workflow

After every Claude Code request that changes app code:
1. Run unit tests: `xcodebuild test -project WheresMySpace.xcodeproj -scheme WheresMySpace -destination 'platform=macOS'`
2. Run `make dev` to build and open the app.
3. Commit the change with a short, one-line commit message. Do not wait for approval before committing in this project (overrides the global CLAUDE.md approval rule).
