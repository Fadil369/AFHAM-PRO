#!/bin/bash

# AFHAM Testing Setup Script
# This script helps configure and run AFHAM feature tests

echo "🧪 AFHAM Feature Testing Setup"
echo "=============================="

# Check if API key is set
if [ -z "$GEMINI_API_KEY" ]; then
    echo ""
    echo "❌ GEMINI_API_KEY environment variable is not set"
    echo ""
    echo "📝 To set it up:"
    echo "1. Get your Gemini API key from: https://aistudio.google.com/app/apikey"
    echo "2. Set the environment variable:"
    echo "   export GEMINI_API_KEY='your_api_key_here'"
    echo ""
    echo "💡 For Xcode testing:"
    echo "1. Open your scheme (Product → Scheme → Edit Scheme)"
    echo "2. Go to Test → Environment Variables"
    echo "3. Add: GEMINI_API_KEY = your_api_key_here"
    echo ""
    read -p "Do you want to set the API key now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter your Gemini API key: " api_key
        export GEMINI_API_KEY="$api_key"
        echo "✅ API key set for this session"
    else
        echo "⚠️  Please set the API key before running tests"
        exit 1
    fi
else
    echo "✅ GEMINI_API_KEY is configured"
fi

echo ""
echo "🏗️  Building AFHAM for testing..."

# Build the project
xcodebuild -scheme AFHAM -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

if [ $? -eq 0 ]; then
    echo "✅ Build successful"
else
    echo "❌ Build failed"
    exit 1
fi

echo ""
echo "🧪 Running unit tests..."

# Run tests
xcodebuild -scheme AFHAM -destination 'platform=iOS Simulator,name=iPhone 15 Pro' test

echo ""
echo "📱 Manual Testing Checklist:"
echo ""
echo "1. 📄 File Upload Test:"
echo "   - Open Documents tab"
echo "   - Tap '+' button"
echo "   - Select a PDF or image file"
echo "   - Verify upload progress and success"
echo ""
echo "2. 💬 Chat Test:"
echo "   - Go to Chat tab"
echo "   - Type: 'What is this document about?'"
echo "   - Verify AI response and citations"
echo ""
echo "3. 🎙️ Voice Test:"
echo "   - Tap microphone button in chat"
echo "   - Grant permissions if prompted"
echo "   - Speak: 'Tell me about this document'"
echo "   - Verify voice recognition works"
echo ""
echo "4. 🌐 Language Test:"
echo "   - Go to Settings"
echo "   - Switch to Arabic"
echo "   - Test Arabic interface and voice"
echo ""
echo "✅ Testing setup complete!"
echo ""
echo "🚀 Next steps:"
echo "1. Run the app in Xcode"
echo "2. Follow the manual testing checklist above"
echo "3. Report any issues you find"
echo ""