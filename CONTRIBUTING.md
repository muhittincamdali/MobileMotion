# Contributing to MobileMotion

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing.

## Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to uphold this code. Please be respectful and constructive in all interactions.

## How to Contribute

### Reporting Bugs

1. Check existing issues to avoid duplicates
2. Use the bug report template
3. Include reproduction steps
4. Provide environment details and platform

### Suggesting Features

1. Check existing feature requests
2. Use the feature request template
3. Explain the use case and benefits
4. Consider multi-platform implications

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Write clean, documented code
4. Add tests for new functionality
5. Commit with conventional commits (`feat:`, `fix:`, `docs:`, etc.)
6. Push and open a Pull Request

## Development Setup

### Swift

```bash
cd swift
open Package.swift
swift test
```

### Dart

```bash
cd dart
flutter pub get
flutter test
```

### TypeScript

```bash
cd typescript
npm install
npm test
```

## Code Style

### Swift
- Follow Swift API Design Guidelines
- Use SwiftLint for consistency

### Dart
- Follow Dart style guide
- Use `dart format`

### TypeScript
- Use Prettier and ESLint

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation only
- `style:` Formatting, no code change
- `refactor:` Code restructuring
- `test:` Adding tests
- `chore:` Maintenance tasks

## Testing

- Write unit tests for physics calculations
- Test animation behavior at different frame rates
- Verify cross-platform consistency

## Questions?

Open a discussion or reach out via issues. We're happy to help!

---

Thank you for contributing! 🎉
