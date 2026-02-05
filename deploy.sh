#!/bin/bash
# Release Automation Script (CI/CD Trigger)
# Usage: ./deploy.sh <version> <build_number>

NEW_VERSION=$1
BUILD_NUMBER=$2

if [ -z "$NEW_VERSION" ] || [ -z "$BUILD_NUMBER" ]; then
  echo "Usage: ./deploy.sh <version> <build_number>"
  echo "Example: ./deploy.sh 1.9.0 1"
  exit 1
fi

echo "🚀 Preparing Release $NEW_VERSION+$BUILD_NUMBER..."

# 1. Update pubspec.yaml
echo "📝 Updating version in pubspec.yaml..."
sed -i '' "s/version: .*/version: $NEW_VERSION+$BUILD_NUMBER/" pubspec.yaml

# 2. Stage and Commit
echo "📦 Staging changes..."
git add .
git commit -m "chore(release): prepare release v$NEW_VERSION" || echo "⚠️ No changes to commit, proceeding..."

# 3. Tag (Force update to ensure it points to latest)
TAG="v$NEW_VERSION"
echo "🏷️ Tagging version $TAG..."
git tag -d "$TAG" 2>/dev/null # Delete local tag if exists
git push origin :refs/tags/"$TAG" 2>/dev/null # Delete remote tag if exists
git tag -a "$TAG" -m "Release $TAG"

# 4. Push
echo "📤 Pushing to GitHub..."
git push origin main
git push origin "$TAG"

echo "✅ DONE! GitHub Action has been triggered for $TAG."
echo "🔗 Check progress at: https://github.com/SaadhJawwadh/Note-taking/actions"
