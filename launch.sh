#!/bin/bash

echo "🚀 Launching BD & IPO Scoring Platform..."
echo "========================================="

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js first."
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install npm first."
    exit 1
fi

echo "📦 Installing dependencies..."
npm install

if [ $? -eq 0 ]; then
    echo "✅ Dependencies installed successfully!"
    echo ""
    echo "🌐 Starting development server..."
    echo "Platform will be available at: http://localhost:3000"
    echo "Press Ctrl+C to stop the server"
    echo ""
    npm run start
else
    echo "❌ Failed to install dependencies. Please check the error messages above."
    exit 1
fi