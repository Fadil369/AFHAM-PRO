# 🚀 AFHAM - Quick Start Guide

Get up and running with AFHAM in less than 10 minutes!

## Prerequisites Check

```bash
# Check Xcode version (need 15.0+)
xcodebuild -version

# Check Swift version (need 5.9+)
swift --version

# Check if you have Ruby & Bundler
ruby --version
bundle --version
```

## 5-Minute Setup

### Step 1: Open Project (1 minute)
```bash
cd /Users/fadil369/AFHAM-PRO-CORE
open AFHAM.xcodeproj
```

### Step 2: Configure API Key (2 minutes)
1. Get your Gemini API key from: https://makersuite.google.com/app/apikey
2. Create `Config/Environment.plist` file
3. Add your API key:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>GEMINI_API_KEY</key>
    <string>YOUR_API_KEY_HERE</string>
</dict>
</plist>
```

### Step 3: Select Target (30 seconds)
1. In Xcode, select "AFHAM" scheme
2. Choose iPhone 15 Pro simulator (or your device)

### Step 4: Build & Run (1.5 minutes)
```bash
# Press ⌘+R in Xcode
# Or run from terminal:
xcodebuild -project AFHAM.xcodeproj -scheme AFHAM -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
```

## First Run Checklist

✅ App launches successfully  
✅ Welcome screen appears  
✅ Language selector works (Arabic/English)  
✅ Upload document button visible  
✅ Chat interface accessible  

## Troubleshooting

**Problem**: Build fails with "No such module"
```bash
# Solution: Resolve Swift packages
swift package resolve
```

**Problem**: Code signing error
```bash
# Solution: In Xcode
# 1. Select AFHAM target
# 2. Signing & Capabilities
# 3. Enable "Automatically manage signing"
# 4. Select your team
```

**Problem**: API key not working
```bash
# Solution: Verify Environment.plist
# 1. Check file exists in Config folder
# 2. Verify API key is correct
# 3. Rebuild project (⌘+Shift+K then ⌘+B)
```

## Next Steps

1. **Read Documentation**: `README.md`
2. **Build Guide**: `BUILD_GUIDE.md`
3. **User Guide**: `AFHAM/Documentation/UserGuide.md`
4. **Developer Guide**: `AFHAM/Documentation/DeveloperGuide.md`

## Need Help?

- **Email**: developer@brainsait.com
- **Docs**: https://docs.brainsait.com/afham
- **Issues**: https://github.com/brainsait/afham-pro-core/issues

Happy coding! 🎉
