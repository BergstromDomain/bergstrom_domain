#!/bin/bash

echo "🔧 Setting up git hooks..."

git config core.hooksPath .githooks

chmod +x .githooks/*

echo "✅ Done"