# Contributing to Aegis-AI Omni-Crisis Intelligence Swarm

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Commit Guidelines](#commit-guidelines)

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Collaborate openly

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/aegis-omni.git`
3. Create a branch: `git checkout -b feature/your-feature-name`

## Development Setup

### Prerequisites

- Python 3.10+
- Poetry
- Docker (optional)

### Installation

```bash
# Install dependencies
poetry install

# Set up pre-commit hooks (recommended)
poetry run pre-commit install
```

## Coding Standards

### Python Style Guide

We follow PEP 8 with these specifics:
- Line length: 100 characters
- Use type hints
- Docstrings for public functions/classes

### Linting

Before committing, ensure your code passes linting:

```bash
poetry run ruff check src/
poetry run ruff format src/
```

### Code Organization

- Keep modules focused and single-purpose
- Use meaningful variable/function names
- Add comments for complex logic

## Testing

### Running Tests

```bash
# All tests
poetry run pytest

# With coverage
poetry run pytest --cov=src --cov-report=html

# Specific test file
poetry run pytest tests/unit/test_specific.py
```

### Writing Tests

- Write unit tests for new functionality
- Maintain or improve code coverage
- Test edge cases and error conditions

## Pull Request Process

1. **Update Documentation**: Ensure README and relevant docs are updated
2. **Add Tests**: Include tests for new features
3. **Pass CI**: Ensure all checks pass
4. **Request Review**: Tag maintainers for review

### PR Checklist

- [ ] Code follows style guidelines
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No linting errors
- [ ] Commit messages are clear

## Commit Guidelines

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding/updating tests
- `chore`: Maintenance tasks

### Examples

```
feat(agents): add validation analyst node

Implemented zero-trust validation agent that cross-references
multiple data sources to eliminate false positives.

Closes #123
```

```
fix(api): resolve timeout in websocket connections

Increased timeout threshold and added retry logic.
```

## Questions?

Open an issue for any questions or suggestions about contributing.

---

Thank you for helping make Aegis-Omni better!
