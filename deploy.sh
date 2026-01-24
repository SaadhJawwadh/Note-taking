#!/bin/bash
# Release Automation Script (CI/CD Trigger)

echo "🚀 Triggering Remote Release Pipeline..."

# 1. Stage and Commit
VERSION="v1.7.0+2"
git add .
# Commit if changes exist, otherwise ignore error
git commit -m "chore(release): trigger build for $VERSION" || echo "⚠️ No changes to commit, proceeding to tag..."

# 2. Tag (Force update to ensure it points to latest)
echo "🏷️ Tagging version $VERSION..."
git tag -f -a "$VERSION" -m "Release $VERSION"

# 3. Push
echo "📤 Pushing to GitHub..."
git push origin main
# Force push tag to update remote if it exists
git push -f origin "$VERSION"

echo "✅ DONE! GitHub Action has been triggered."
echo "🔗 Check progress at: https://github.com/SaadhJawwadh/Note-taking/actions"
