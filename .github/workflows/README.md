# GitHub Actions Workflows

This repository includes several GitHub Actions workflows for automated testing, building, and releasing:

## 🚀 Automated Workflows

### 1. **Automatic Releases** (`release.yml`)
**Trigger:** Push to `main` branch
**What it does:**
- ✅ Creates automatic releases when code is pushed to main branch
- 📦 Builds separate packages for Linux and Windows
- 🏷️ Generates version tags based on date and commit SHA
- 📋 Creates detailed release notes with usage instructions
- ✨ Uploads both packaged archives and standalone scripts
- 🔍 Prevents duplicate releases with existing tag check

**Generated Assets:**
- `fivem-update-linux.tar.gz` - Complete Linux package
- `fivem-update-windows.zip` - Complete Windows package  
- `update_linux.sh` - Standalone Linux script
- `update_windows.ps1` - Standalone Windows script

### 2. **Script Testing** (`test.yml`)
**Trigger:** Pull requests and pushes to main
**What it does:**
- 🔍 Tests script syntax and validation
- 🐧 Validates Linux script with bash and shellcheck
- 🪟 Validates Windows PowerShell script syntax
- 📝 Checks GitHub Actions workflow YAML syntax
- 📦 Creates test packages to verify build process
- ⚡ Runs quick functionality tests

## 🔧 Setup Instructions

### Prerequisites
Your repository needs:
- ✅ Default `GITHUB_TOKEN` permissions (automatically available)
- ✅ Actions enabled in repository settings
- ✅ Write permissions for Actions (in repository settings)

### Repository Settings
1. **Enable Actions:**
   - Go to repository **Settings → Actions → General**
   - Select "Allow all actions and reusable workflows"

2. **Workflow Permissions:**
   - In **Settings → Actions → General → Workflow permissions**
   - Select "Read and write permissions"
   - Check "Allow GitHub Actions to create and approve pull requests"

### Branch Protection (Optional but Recommended)
- Go to **Settings → Branches**
- Add protection rule for `main` branch:
  - ✅ Require status checks to pass (select "test-linux-script", "test-windows-script")
  - ✅ Require branches to be up to date before merging

## 📋 Workflow Status Badges

Add these badges to your main README.md:

```markdown
[![Build Status](https://github.com/YOUR_USERNAME/YOUR_REPO/workflows/Test%20Scripts/badge.svg)](https://github.com/YOUR_USERNAME/YOUR_REPO/actions)
[![Latest Release](https://img.shields.io/github/v/release/YOUR_USERNAME/YOUR_REPO?style=flat-square)](https://github.com/YOUR_USERNAME/YOUR_REPO/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/YOUR_USERNAME/YOUR_REPO/total?style=flat-square)](https://github.com/YOUR_USERNAME/YOUR_REPO/releases)
```

## 🔄 Release Process

### Automatic Releases
1. Make your changes in a feature branch
2. Create a pull request to `main`
3. Once merged, a release is automatically created
4. Release will have format: `v2025.01.27-abc1234` (date + commit SHA)

### Manual Releases via UI
1. Go to **Actions → Create Release → Run workflow**
2. Release is created using the workflow_dispatch trigger
3. Same automated process as push-triggered releases

### Development Workflow
```bash
# Feature development
git checkout -b feature/new-feature
# Make changes...
git commit -m "feat: add new feature"
git push origin feature/new-feature

# Create PR → merge to main → automatic release created!
```

## 🐛 Troubleshooting

### Common Issues

**❌ "Resource not accessible by integration"**
- Fix: Enable write permissions in repository settings

**❌ Workflow fails on release creation**
- Check if tag already exists
- Ensure GITHUB_TOKEN has sufficient permissions

**❌ Assets not uploading**
- Verify upload_url is properly passed between jobs
- Check file paths are correct

### Debug Information
View detailed logs in the **Actions** tab of your repository. Each step shows:
- ✅ Success (green checkmark)
- ❌ Failure (red X)  
- ⚠️ Warning (yellow triangle)

## 🎯 Customization

### Modify Release Triggers
Edit `.github/workflows/release.yml`:
```yaml
on:
  push:
    branches: [ main, master, develop ]  # Add more branches
    tags: [ 'v*' ]                       # Trigger on version tags
```

### Change Package Contents
Modify the build steps to include additional files:
```yaml
- name: Create Linux archive
  run: |
    # Add additional files to the archive
    cp config.json .                     # Add config file
    cp -r templates/ .                   # Add template directory
    tar -czf fivem-update-linux.tar.gz --exclude='.git' --exclude='.github' --exclude='*.zip' --exclude='*.tar.gz' .
```

### Custom Version Format
Change version generation in `release.yml`:
```yaml
TAG="v$(date +'%Y.%m.%d')-build-$(git rev-parse --short HEAD)"
```

---

*This streamlined workflow ensures your FiveM Server Update Scripts are automatically tested, built, and released with every change!* 🚀
