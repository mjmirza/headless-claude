# Contributing to Headless Claude Code Guide

First off, thank you for considering contributing to this project! 🎉

This guide aims to be the most comprehensive resource for headless Claude Code usage. Your contributions help make it even better.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Style Guidelines](#style-guidelines)
- [Pull Request Process](#pull-request-process)

## Code of Conduct

This project adheres to a Code of Conduct that we expect all contributors to follow. Please read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before contributing.

## How Can I Contribute?

### Reporting Issues

- **Check existing issues** before creating a new one
- **Use a clear, descriptive title**
- **Provide detailed information**:
  - What you expected to happen
  - What actually happened
  - Steps to reproduce
  - Your environment (OS, Claude Code version, etc.)

### Suggesting Enhancements

We welcome suggestions for:
- New examples and use cases
- Additional agent templates
- New skill templates
- Cloud platform integrations
- Best practices
- Performance optimizations

**When suggesting enhancements:**
- Use a clear, descriptive title
- Provide a detailed description of the enhancement
- Explain why this would be useful
- Provide examples if applicable

### Contributing Code

We accept contributions for:

1. **New Examples**
   - Basic, intermediate, or advanced patterns
   - Real-world use cases
   - Cloud platform integrations

2. **Documentation Improvements**
   - Fixing typos or errors
   - Clarifying existing content
   - Adding missing information

3. **Templates**
   - New agent templates
   - New skill templates
   - Configuration examples

4. **Best Practices**
   - Security patterns
   - Performance optimizations
   - Production deployment strategies

## Style Guidelines

### Documentation Style

- **Use clear, concise language**
- **Provide actual commands**, not just scripts
- **Include examples** for every concept
- **Add context** - explain why, not just how
- **Use proper markdown formatting**

### Command Examples

✅ **Good Example:**
```bash
# Execute Claude with security focus
claude -p "Scan for vulnerabilities" \
  --allowedTools "Read,Grep,Glob" \
  --output-format json > security.json

# Parse results
jq -r '.result' security.json
```

❌ **Bad Example:**
```bash
# Run scan
run_scan.sh
```

### Code Style

- Use **bash** for shell scripts
- Include **comments** for complex logic
- Add **error handling**
- Use **meaningful variable names**
- Follow **shellcheck** recommendations

### Documentation Structure

When adding new examples:

```markdown
# Title

Brief introduction explaining what this covers.

## Table of Contents

1. [Section 1](#section-1)
2. [Section 2](#section-2)

---

## Section 1

### Subsection

Explanation of concept.

**Example:**
```bash
actual command here
```

**Use cases:**
- Use case 1
- Use case 2

**Best practices:**
- Practice 1
- Practice 2
```

## Pull Request Process

### Before Submitting

1. **Test all commands** - Ensure every command works
2. **Check formatting** - Use proper markdown
3. **Update relevant docs** - If adding features, update README
4. **Follow existing patterns** - Match the style of existing content

### Submitting

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-new-example
   ```

3. **Make your changes**
   - Follow style guidelines
   - Add examples
   - Update documentation

4. **Commit with clear messages**
   ```bash
   git commit -m "feat: add AWS Lambda integration example"
   ```

   **Commit message format:**
   - `feat:` New feature or example
   - `fix:` Bug fix or correction
   - `docs:` Documentation only
   - `style:` Formatting changes
   - `refactor:` Code restructuring
   - `test:` Adding tests
   - `chore:` Maintenance

5. **Push to your fork**
   ```bash
   git push origin feature/amazing-new-example
   ```

6. **Open a Pull Request**
   - Use a clear title
   - Describe your changes
   - Reference any related issues
   - Add examples of the changes

### PR Review Process

1. **Automated checks** will run
2. **Maintainers will review** your PR
3. **Address feedback** if requested
4. **Merge** once approved

## Types of Contributions We're Looking For

### High Priority

- ✅ Real-world use case examples
- ✅ Production deployment patterns
- ✅ Cloud platform integrations (AWS, GCP, Azure)
- ✅ Performance optimization techniques
- ✅ Security best practices

### Medium Priority

- ✅ Additional agent templates
- ✅ New skill examples
- ✅ Troubleshooting guides
- ✅ Advanced patterns

### Always Welcome

- ✅ Documentation improvements
- ✅ Typo fixes
- ✅ Clarifications
- ✅ Example enhancements

## Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/headless-claude.git
   cd headless-claude
   ```

2. **Create a branch**
   ```bash
   git checkout -b your-feature-name
   ```

3. **Make changes**
   - Edit files
   - Add examples
   - Update documentation

4. **Test your changes**
   - Run all command examples
   - Verify markdown formatting
   - Check links

5. **Commit and push**
   ```bash
   git add .
   git commit -m "feat: your changes"
   git push origin your-feature-name
   ```

## Example Contributions

### Adding a New Example

```markdown
## New Pattern: Database Migration Automation

### Overview

Automate database migrations using headless Claude Code with validation.

### Example

```bash
# Stage 1: Analyze current schema
SESSION=$(claude -p "Analyze PostgreSQL schema in db/schema.sql" \
  --output-format json | jq -r '.metadata.sessionId')

# Stage 2: Generate migration
claude -r "$SESSION" -p "Generate migration to add user roles table"

# Stage 3: Validate migration
claude -r "$SESSION" -p "Validate migration for potential issues"
```

### Use Cases

- Automated schema migrations
- Database refactoring
- Multi-environment deployments

### Best Practices

- Always validate before applying
- Use transactions
- Test in staging first
```

### Adding a Template

Create a new template in `templates/agents/`:

```markdown
---
name: database-migration-assistant
description: Assists with database schema migrations, validation, and rollback planning
model: sonnet
tools: Read, Grep, Glob, Bash
permissionMode: plan
---

# Database Migration Assistant

Specialized agent for database migration tasks...
```

## Questions?

Feel free to:
- Open an issue for questions
- Start a discussion
- Reach out to maintainers

## Recognition

Contributors will be:
- Listed in the README
- Credited in release notes
- Forever appreciated 💙

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

## Thank You! 🙏

Every contribution, no matter how small, helps make this guide better for everyone.

**Made with ❤️ by the community**
