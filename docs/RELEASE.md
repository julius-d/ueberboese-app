# Release Process

This document describes how to create releases for the Überböse Android app using GitHub Actions and semantic versioning.

## Overview

The release process is automated through GitHub Actions and uses semantic versioning based on conventional commits. Releases are triggered manually from the GitHub Actions interface.

## Prerequisites

Before you can create releases, you need to:

1. Generate an Android signing keystore
2. Configure GitHub repository secrets

### Step 1: Generate Keystore

Run the provided script to generate a signing keystore:

```bash
./scripts/generate-keystore.sh
```

The script will:
- Generate a new keystore at `android/app/upload-keystore.jks`
- Prompt you for certificate information (name, organization, etc.)
- Ask for passwords (store securely!)
- Optionally encode and copy the keystore to clipboard (macOS)

**Important:**
- Keep your keystore file safe and backed up
- Never commit the keystore to version control
- Store passwords in a password manager
- If you lose the keystore, you cannot update your app

### Step 2: Configure GitHub Secrets

Add the following secrets to your GitHub repository:

Go to: **Settings > Secrets and variables > Actions > New repository secret**

| Secret Name                 | Description             | How to get                                                                                                                  |
|-----------------------------|-------------------------|-----------------------------------------------------------------------------------------------------------------------------|
| `ANDROID_KEYSTORE_BASE64`   | Base64-encoded keystore | Run: `base64 -i android/app/upload-keystore.jks \| pbcopy` (macOS) or `base64 -w 0 android/app/upload-keystore.jks` (Linux) |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password       | Password you set when generating keystore                                                                                   |
| `ANDROID_KEY_PASSWORD`      | Key password            | Key password you set (usually same as keystore password)                                                                    |
| `ANDROID_KEY_ALIAS`         | Key alias               | Default: `upload`                                                                                                           |

## Creating a Release

### 1. Make Sure Commits Follow Convention

The version is automatically calculated from commit messages using [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>: <description>

[optional body]

[optional footer]
```

**Version Bumps:**
- `feat:` → Minor version (0.1.0 → 0.2.0)
- `fix:` → Patch version (0.1.0 → 0.1.1)
- `BREAKING CHANGE:` or `!` → Major version (0.1.0 → 1.0.0)
- Other types (docs:, style:, refactor:, etc.) → No version bump

**Examples:**
```bash
git commit -m "feat: add dark mode support"          # 0.1.0 → 0.2.0
git commit -m "fix: resolve crash on startup"        # 0.1.0 → 0.1.1
git commit -m "feat!: redesign user interface"       # 0.1.0 → 1.0.0
```

### 2. Trigger Release Workflow

1. Go to **Actions** tab in GitHub
2. Select **Android Release** workflow
3. Click **Run workflow**
4. Click the green **Run workflow** button

### 3. Monitor Progress

The workflow consists of three jobs:

1. **Calculate Semantic Version**
   - Analyzes commits since last tag
   - Determines new version number
   - Fails if no version bump needed

2. **Build Signed APK**
   - Updates version in pubspec.yaml (temporarily)
   - Builds signed release APK
   - Uploads artifact

3. **Create GitHub Release**
   - Creates git tag with new version
   - Creates GitHub release
   - Uploads APK to release
   - Generates changelog from commits

### 4. Download and Distribute

Once complete:
- Go to **Releases** tab in GitHub
- Find the new release
- Download the APK
- Distribute to users

## Versioning Strategy

The project uses **semantic versioning** (MAJOR.MINOR.PATCH):

- **MAJOR** (1.0.0): Breaking changes, incompatible API changes
- **MINOR** (0.1.0): New features, backwards compatible
- **PATCH** (0.0.1): Bug fixes, backwards compatible

Current version: **0.1.0**

## Troubleshooting

### No Version Bump

**Problem:** Workflow completes but no release is created.

**Cause:** No version-bumping commits since last release (only docs, style, etc.)

**Solution:** Ensure you have `feat:` or `fix:` commits, or add them:
```bash
git commit --allow-empty -m "feat: trigger release"
```

### Keystore Errors

**Problem:** Build fails with signing errors.

**Causes:**
- Keystore secret not set correctly
- Wrong password in secrets
- Keystore file corrupted during encoding

**Solution:**
1. Re-encode keystore: `base64 -i android/app/upload-keystore.jks`
2. Update `ANDROID_KEYSTORE_BASE64` secret
3. Verify all 4 secrets are set correctly

### Build Fails

**Problem:** Build step fails.

**Solution:**
1. Check the build logs in GitHub Actions
2. Test locally: `flutter build apk --release`
3. Ensure tests pass: `flutter test`
4. Check for Dart/Flutter version issues

## Local Testing

To test the signing configuration locally:

1. Create `android/key.properties`:
   ```properties
   storePassword=your-store-password
   keyPassword=your-key-password
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```

2. Build release APK:
   ```bash
   flutter build apk --release
   ```

3. Verify signing:
   ```bash
   keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
   ```

## Continuous Integration

The existing CI workflow (`flutter-ci.yml`) continues to run on every push/PR:
- Runs tests
- Builds debug APK
- No signing or releases

The release workflow (`release.yml`) is separate and manual:
- Manual trigger only
- Builds signed APK
- Creates releases

## Best Practices

1. **Commit Messages**: Always use conventional commits
2. **Testing**: Ensure tests pass before releasing
3. **Changelog**: Review auto-generated changelog
4. **Testing**: Test APK on device before distributing widely
5. **Backups**: Keep keystore backed up securely
6. **Versioning**: Follow semantic versioning principles

## References

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [Flutter Deployment](https://docs.flutter.dev/deployment/android)
