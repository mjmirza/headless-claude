<div align="center">

# 🚀 The Ultimate Headless Claude Code Guide

[![OpenRoots ORA 2.3](https://openroots.org/badge/ora.svg)](https://openroots.org/licenses/ora/2.3)

### *Transform AI from a Tool into Infrastructure*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Made with Love](https://img.shields.io/badge/Made%20with-❤-red.svg)](https://github.com/mirzaiqbal/headless-claude)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Documentation](https://img.shields.io/badge/docs-comprehensive-blue.svg)](#documentation)

> **Ultra-Advanced, Production-Ready Patterns for Headless Execution**
>
> *35,000+ words • 200+ examples • Enterprise-tested • Ready to deploy*

**[Quick Start](#quick-start)** •
**[Why Headless?](WHY_HEADLESS.md)** •
**[Examples](#examples)** •
**[Best Practices](#best-practices)** •
**[Contributing](CONTRIBUTING.md)**

</div>

---

## Table of Contents

- [Overview](#overview)
- [What This Guide Covers](#what-this-guide-covers)
- [Quick Start](#quick-start)
- [Examples](#examples)
- [Architecture](#architecture)
- [Core Concepts](#core-concepts)
  - [Headless Mode](#headless-mode)
  - [Sub-Agents](#sub-agents)
  - [Skills](#skills)
  - [Remote Execution](#remote-execution)
- [Command Reference](#command-reference)
- [Use Cases](#use-cases)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [Resources](#resources)

---

## Overview

This repository provides an **extensive, production-ready guide** for using Claude Code in headless mode. Whether you're building CI/CD pipelines, automating code reviews, orchestrating distributed analysis, or creating custom AI-powered workflows, this guide covers every aspect with extreme depth and practical examples.

### What Makes This Guide Different?

- **Command-Based Examples**: All examples use actual commands—no unnecessary automation scripts
- **Production-Ready**: Patterns tested for real-world, enterprise scenarios
- **Ultra-Advanced**: Covers distributed execution, agent orchestration, custom skills, and complex workflows
- **Comprehensive**: From basics to advanced multi-agent systems
- **Security-Focused**: Best practices for secure, isolated execution
- **Cloud-Native**: Integration with AWS, GCP, Azure, Kubernetes, and CI/CD systems

---

## What This Guide Covers

### 1. Headless Execution Fundamentals
- Single-shot and multi-turn conversations
- Output formatting (text, JSON, streaming)
- Input methods (args, stdin, files)
- Permission management
- Session continuation and resumption
- Error handling and retry logic

### 2. Agent Orchestration
- Built-in agents (Explore, Plan, General-Purpose)
- Custom agent creation and configuration
- Agent chaining and pipelines
- Parallel agent execution
- Resumable agent workflows
- Supervisor patterns

### 3. Skills Development
- Creating reusable, modular capabilities
- Skill structure and best practices
- Integration with agents
- Multi-file skills with templates
- Tool restriction and security
- Team sharing and version control

### 4. Remote Execution
- SSH-based remote execution
- Distributed multi-host patterns
- Cloud integration (AWS, GCP, Azure)
- Container orchestration (Docker, Kubernetes)
- Load balancing and map-reduce
- CI/CD integration (GitHub Actions, GitLab CI, Jenkins)

### 5. Advanced Workflows
- Multi-stage pipelines
- Conditional execution
- Event-driven automation
- Monitoring and observability
- Cost optimization
- Rate limiting and throttling

---

## Quick Start

### Prerequisites

```bash
# Install Claude Code (if not already installed)
# Visit: https://code.claude.com for installation instructions

# Verify installation
claude --version

# Create dedicated user for isolated execution (recommended)
sudo useradd -m -s /bin/bash claudeuser
```

### Your First Headless Execution

```bash
# Simple query
claude -p "Analyze the structure of this project"

# With specific model
claude -p "Review security in src/auth/" --model sonnet

# JSON output for automation
claude -p "List all TODO items" --output-format json

# As dedicated user (isolated, secure)
su - claudeuser -c 'claude --dangerously-skip-permissions -p "Audit configurations"'
```

### Your First Multi-Turn Conversation

```bash
# Start analysis
claude -p "Begin comprehensive security audit" --output-format json > session.json

# Get session ID
SESSION_ID=$(cat session.json | jq -r '.metadata.sessionId')

# Continue with context
claude -r "$SESSION_ID" -p "Now check for SQL injection vulnerabilities"

# Final report
claude -r "$SESSION_ID" -p "Generate comprehensive security report"
```

### Your First Sub-Agent

```bash
# Use Explore agent for fast codebase search
claude -p "Use Explore agent (very thorough) to find all API endpoints"

# Use custom agent
claude -p "Use security-auditor agent to analyze authentication module"
```

---

## Examples

All examples are organized by complexity and use case:

### 📁 [01-basic/](examples/01-basic/)
**Foundational headless patterns**
- Simple one-shot execution
- Multi-user execution (security isolation)
- Output formatting (text, JSON, stream)
- Input methods (stdin, files, heredoc)
- Permission management
- Practical automation examples

**Start here if:** You're new to headless Claude Code

### 📁 [02-intermediate/](examples/02-intermediate/)
**Multi-turn conversations and session management**
- Session continuation (`--continue`, `--resume`)
- Multi-turn workflows
- Streaming JSON interactions
- Custom system prompts
- Advanced tool configuration
- MCP server integration

**Start here if:** You need stateful, multi-step automation

### 📁 [03-advanced/](examples/03-advanced/)
**Complex orchestration patterns**
- Conditional execution
- Event-driven workflows
- Complex state machines
- Error recovery patterns
- Cost optimization strategies

**Start here if:** You're building production automation

### 📁 [04-agents/](examples/04-agents/)
**Sub-agent orchestration and super-agents**
- Built-in agents (Explore, Plan, General-Purpose)
- Custom agent creation
- Agent chaining and pipelines
- Parallel agent execution
- Resumable agents
- Supervisor patterns

**Start here if:** You need specialized, isolated task execution

### 📁 [05-skills/](examples/05-skills/)
**Reusable skill development**
- Skill structure and format
- Custom skill creation
- Multi-file skills with templates
- Skill integration with agents
- Tool restriction patterns
- Team sharing strategies

**Start here if:** You want reusable, model-invoked capabilities

### 📁 [06-remote/](examples/06-remote/)
**Remote and distributed execution**
- SSH-based remote execution
- Multi-host parallel execution
- Cloud integration (AWS, GCP, Azure)
- Container orchestration
- CI/CD integration
- Map-reduce patterns

**Start here if:** You need to execute across multiple servers

### 📁 [07-pipelines/](examples/07-pipelines/)
**Complex workflow orchestration**
- Multi-stage pipelines
- Data flow patterns
- Dependency management
- Failure handling
- Pipeline monitoring

**Coming soon**

### 📁 [08-monitoring/](examples/08-monitoring/)
**Observability and metrics**
- Execution monitoring
- Cost tracking
- Performance metrics
- Logging strategies
- Alerting patterns

**Coming soon**

---

## Architecture

### Execution Models

```
┌─────────────────────────────────────────────────────────────┐
│                    Headless Execution Modes                  │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Single-Shot │  │  Multi-Turn  │  │   Streaming  │      │
│  │              │  │              │  │              │      │
│  │  claude -p   │  │  claude -r   │  │  --output-   │      │
│  │  "query"     │  │  SESSION_ID  │  │  format      │      │
│  │              │  │  -p "next"   │  │  stream-json │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                               │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                   Agent Orchestration                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Main Conversation                                           │
│  ┌────────────────────────────────────────────────────┐     │
│  │                                                      │     │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐         │     │
│  │  │ Explore  │  │   Plan   │  │  Custom  │         │     │
│  │  │  Agent   │  │  Agent   │  │  Agents  │         │     │
│  │  │ (Haiku)  │  │ (Sonnet) │  │ (Config) │         │     │
│  │  └──────────┘  └──────────┘  └──────────┘         │     │
│  │                                                      │     │
│  │  Isolated contexts, dedicated tools, resumable      │     │
│  └────────────────────────────────────────────────────┘     │
│                                                               │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    Distributed Execution                     │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Control Host                                                │
│  ┌────────────────────────────────────────────────────┐     │
│  │                                                      │     │
│  │   SSH / Cloud API / Kubernetes                      │     │
│  │   ┌────────┐  ┌────────┐  ┌────────┐              │     │
│  │   │ Host 1 │  │ Host 2 │  │ Host N │              │     │
│  │   │ Claude │  │ Claude │  │ Claude │              │     │
│  │   └────────┘  └────────┘  └────────┘              │     │
│  │                                                      │     │
│  │   Parallel / Sequential / Map-Reduce                │     │
│  └────────────────────────────────────────────────────┘     │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Skills System

```
┌─────────────────────────────────────────────────────────────┐
│                      Skills Architecture                     │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  .claude/skills/                                             │
│  ├── api-security-check/                                     │
│  │   ├── SKILL.md              ← Definition & instructions  │
│  │   ├── examples/             ← Reference implementations  │
│  │   ├── templates/            ← Output templates           │
│  │   └── scripts/              ← Helper utilities           │
│  │                                                            │
│  ├── database-optimizer/                                     │
│  │   ├── SKILL.md                                            │
│  │   └── scripts/                                            │
│  │                                                            │
│  └── code-reviewer/                                          │
│      ├── SKILL.md                                            │
│      └── templates/                                          │
│                                                               │
│  Skills are MODEL-INVOKED (automatic activation)             │
│  Based on description matching in SKILL.md                   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Core Concepts

### Headless Mode

**What it is:** Non-interactive execution mode for automation and scripting.

**Key flags:**
- `-p, --print`: Execute and output result
- `--output-format`: Control output (text/json/stream-json)
- `--continue, -c`: Resume most recent conversation
- `--resume, -r`: Resume specific session by ID
- `--max-turns`: Limit conversation depth
- `--dangerously-skip-permissions`: Skip permission prompts (use carefully!)

**When to use:**
- CI/CD pipelines
- Scheduled automation
- Batch processing
- Remote execution
- Programmatic integration

**Example:**
```bash
claude -p "Analyze security vulnerabilities" \
  --output-format json \
  --max-turns 20 \
  --allowedTools "Read,Grep,Glob"
```

### Sub-Agents

**What they are:** Specialized AI assistants with isolated context, custom prompts, and restricted tools.

**Built-in types:**
1. **Explore Agent** (Haiku) - Fast, read-only codebase exploration
2. **Plan Agent** (Sonnet) - Research during planning phase
3. **General-Purpose** (Sonnet) - Complex multi-step tasks with full access

**Why use them:**
- Task specialization
- Context isolation
- Performance optimization (use Haiku for simple tasks)
- Cost control
- Parallel execution

**Example:**
```bash
# Fast exploration
claude -p "Use Explore agent to find authentication files"

# Custom agent
claude -p "Use security-auditor agent for comprehensive security review"
```

**Learn more:** [04-agents/](examples/04-agents/)

### Skills

**What they are:** Reusable, modular capabilities that Claude automatically activates based on context.

**Key characteristics:**
- **Model-invoked**: Claude decides when to use them
- **Self-contained**: Each skill is independent
- **Team-shareable**: Via git or plugins
- **Context-aware**: Activated by description matching

**Skill locations:**
- **Project**: `.claude/skills/` (shared with team)
- **Personal**: `~/.claude/skills/` (your workflows)

**When to create:**
- Repetitive analysis patterns
- Domain-specific expertise
- Team conventions
- Complex multi-step procedures

**Example structure:**
```
.claude/skills/api-security-check/
├── SKILL.md              # Skill definition with YAML frontmatter
├── examples/             # Reference implementations
├── templates/            # Output templates
└── scripts/              # Helper utilities
```

**Learn more:** [05-skills/](examples/05-skills/)

### Remote Execution

**What it is:** Executing Claude Code on remote servers, cloud instances, or distributed systems.

**Methods:**
- SSH: Direct remote execution
- Cloud APIs: AWS SSM, GCP gcloud, Azure Run Command
- Containers: Docker, Kubernetes
- CI/CD: GitHub Actions, GitLab CI, Jenkins

**Patterns:**
- Parallel execution across hosts
- Load-balanced distribution
- Map-reduce for large datasets
- Centralized control, distributed execution

**Example:**
```bash
# Execute on remote server
ssh user@server "claude -p 'Analyze /var/log/app.log'"

# Parallel across multiple servers
for server in server{1..10}; do
  ssh user@$server "claude -p 'Security scan'" &
done
wait
```

**Learn more:** [06-remote/](examples/06-remote/)

---

## Command Reference

### Essential Commands

| Command | Description | Example |
|---------|-------------|---------|
| `claude -p "query"` | One-shot headless execution | `claude -p "Analyze code"` |
| `claude -c -p "next"` | Continue last conversation | `claude -c -p "Now check tests"` |
| `claude -r ID -p "query"` | Resume specific session | `claude -r abc123 -p "Continue audit"` |
| `claude --output-format json` | JSON output | `claude -p "Task" --output-format json` |
| `claude --model haiku` | Use specific model | `claude -p "Quick search" --model haiku` |

### Advanced Flags

| Flag | Purpose | Example |
|------|---------|---------|
| `--dangerously-skip-permissions` | Skip permission prompts | For CI/CD automation |
| `--allowedTools "Read,Grep"` | Whitelist tools | Read-only operations |
| `--disallowedTools "Write,Edit"` | Blacklist tools | Prevent modifications |
| `--max-turns 50` | Limit conversation depth | Control complexity |
| `--append-system-prompt "..."` | Add custom instructions | Domain-specific context |
| `--system-prompt-file file.txt` | Replace system prompt | Complete customization |
| `--mcp-config config.json` | Load MCP servers | External integrations |
| `--verbose` | Detailed logging | Debugging |

### Model Selection

| Model | When to Use | Cost | Speed |
|-------|-------------|------|-------|
| `haiku` | Simple searches, quick tasks | Lowest | Fastest |
| `sonnet` | Complex reasoning, implementation | Medium | Medium |
| `opus` | Most complex, creative tasks | Highest | Slowest |

---

## Use Cases

### 1. Automated Code Review

```bash
# Review pull request
PR_NUMBER=123
git fetch origin pull/${PR_NUMBER}/head:pr-${PR_NUMBER}
git diff main...pr-${PR_NUMBER} > /tmp/pr-diff.txt

claude -p "Review this PR for security, quality, and best practices:
$(cat /tmp/pr-diff.txt)" \
  --output-format json > review.json

# Post to GitHub (using gh CLI)
gh pr comment $PR_NUMBER --body "$(jq -r '.result' review.json)"
```

### 2. Security Auditing

```bash
# Comprehensive security scan
claude -p "Perform OWASP Top 10 security audit of src/" \
  --allowedTools "Read,Grep,Glob" \
  --output-format json \
  --max-turns 30 > security-audit.json

# Generate report
jq -r '.result' security-audit.json > security-report.md
```

### 3. Database Migration

```bash
# Multi-stage migration with checkpoints
SESSION=$(claude -p "Plan database migration from MySQL to PostgreSQL" \
  --output-format json | jq -r '.metadata.sessionId')

# Stage 1: Analysis
claude -r "$SESSION" -p "Analyze current schema and data"

# Stage 2: Generate migration
claude -r "$SESSION" -p "Generate PostgreSQL schema and migration scripts"

# Stage 3: Validation
claude -r "$SESSION" -p "Create validation queries to verify migration"
```

### 4. Distributed Log Analysis

```bash
# Analyze logs across 10 servers in parallel
LOG_SERVERS=(log-{01..10}.example.com)

for server in "${LOG_SERVERS[@]}"; do
  {
    ssh user@$server \
      "claude -p 'Analyze /var/log/app/*.log for errors in past hour' \
        --output-format json"
  } > "analysis-${server}.json" &
done
wait

# Aggregate results
cat analysis-*.json | jq -s '{
  total_errors: map(.result | scan("[0-9]+") | tonumber) | add,
  servers_analyzed: length
}'
```

### 5. CI/CD Integration

```bash
# GitHub Actions workflow snippet
- name: Claude Code Review
  run: |
    claude -p "Review changed files for security and quality" \
      --output-format json \
      --allowedTools "Read,Grep,Glob" > review.json

    # Fail if critical issues found
    if jq -e '.result | contains("CRITICAL")' review.json; then
      exit 1
    fi
```

### 6. Documentation Generation

```bash
# Auto-generate API documentation
claude -p "Generate OpenAPI/Swagger documentation for all REST endpoints in src/api/" \
  --output-format text > openapi.yaml

# Validate
swagger-cli validate openapi.yaml
```

---

## Best Practices

### Security

1. **Use dedicated user for isolation**
   ```bash
   sudo useradd -m -s /bin/bash claudeuser
   su - claudeuser -c 'claude -p "task"'
   ```

2. **Restrict tool access**
   ```bash
   # Read-only analysis
   claude -p "task" --allowedTools "Read,Grep,Glob"
   ```

3. **Never hardcode API keys**
   ```bash
   # Use environment variables
   export ANTHROPIC_API_KEY="sk-..."

   # Or use secret managers
   ANTHROPIC_API_KEY=$(aws secretsmanager get-secret-value ...)
   ```

4. **Skip permissions only in trusted environments**
   ```bash
   # Only in CI/CD or isolated containers
   claude --dangerously-skip-permissions -p "task"
   ```

### Performance

1. **Use appropriate models**
   ```bash
   # Fast searches: Haiku
   claude -p "Find files" --model haiku

   # Complex tasks: Sonnet
   claude -p "Refactor module" --model sonnet
   ```

2. **Limit turns for simple tasks**
   ```bash
   claude -p "Quick scan" --max-turns 5
   ```

3. **Use Explore agent for searches**
   ```bash
   claude -p "Use Explore agent (quick) to find config files"
   ```

### Cost Optimization

1. **Monitor costs via JSON output**
   ```bash
   RESULT=$(claude -p "task" --output-format json)
   COST=$(echo "$RESULT" | jq -r '.metadata.totalCost')
   echo "Cost: $COST" >> costs.log
   ```

2. **Use streaming to process partial results**
   ```bash
   claude -p "Large analysis" --output-format stream-json | \
   while read -r line; do
     # Process incrementally
   done
   ```

3. **Batch related tasks in one session**
   ```bash
   # More efficient than separate executions
   claude -p "Analyze A, then B, then C" --max-turns 30
   ```

### Reliability

1. **Always set timeouts**
   ```bash
   timeout 300 claude -p "task"
   ```

2. **Implement retry logic**
   ```bash
   for i in {1..3}; do
     claude -p "task" && break || sleep 5
   done
   ```

3. **Log everything**
   ```bash
   claude -p "task" 2>&1 | tee execution.log
   ```

4. **Use error handling**
   ```bash
   if ! claude -p "task"; then
     echo "Failed, triggering fallback"
     ./fallback-script.sh
   fi
   ```

---

## Troubleshooting

### Common Issues

#### 1. "Permission denied" in headless mode

**Problem:** Claude requesting permissions in non-interactive environment

**Solutions:**
```bash
# Option 1: Skip permissions (trusted environments only)
claude --dangerously-skip-permissions -p "task"

# Option 2: Use allowedTools
claude -p "task" --allowedTools "Read,Write,Edit"

# Option 3: Set permission mode
claude -p "task" --permission-mode acceptEdits
```

#### 2. Session not resuming

**Problem:** `--resume` or `--continue` not working

**Solutions:**
```bash
# Verify session ID format (must be from .metadata.sessionId)
RESULT=$(claude -p "task" --output-format json)
SESSION=$(echo "$RESULT" | jq -r '.metadata.sessionId')
claude -r "$SESSION" -p "continue"

# Check transcripts exist
ls -la ~/.claude/transcripts/
```

#### 3. Output is truncated

**Problem:** Large outputs cut off

**Solutions:**
```bash
# Increase max turns
claude -p "complex task" --max-turns 50

# Use streaming for large outputs
claude -p "task" --output-format stream-json
```

#### 4. Rate limiting / API errors

**Problem:** Too many requests

**Solutions:**
```bash
# Add delays between requests
for task in {1..10}; do
  claude -p "task $task"
  sleep 2
done

# Implement exponential backoff
retry_with_backoff() {
  local max_attempts=5
  local timeout=1
  for ((i=1; i<=max_attempts; i++)); do
    claude -p "$1" && return 0
    timeout=$((timeout * 2))
    sleep $timeout
  done
  return 1
}
```

#### 5. Agent not activating

**Problem:** Custom agent or skill not being used

**Solutions:**
```bash
# Check agent file exists
ls -la .claude/agents/your-agent.md

# Verify YAML frontmatter syntax
head -20 .claude/agents/your-agent.md

# Use explicit invocation
claude -p "Use your-agent agent to perform task"

# Check skills are discovered
claude -p "List all available skills"
```

#### 6. Remote execution fails

**Problem:** SSH or network issues

**Solutions:**
```bash
# Test SSH connectivity first
ssh user@remote echo "SSH works"

# Use verbose SSH for debugging
ssh -v user@remote "claude -p 'task'"

# Verify Claude installed on remote
ssh user@remote "which claude && claude --version"

# Check API key on remote
ssh user@remote "echo \$ANTHROPIC_API_KEY"
```

### Debug Mode

```bash
# Enable verbose logging
claude -p "task" --verbose

# Enable debug mode
claude -p "task" --debug

# Debug specific categories
claude -p "task" --debug mcp,tools

# Full debug output
claude -p "task" --debug all 2>&1 | tee debug.log
```

### Getting Help

```bash
# View all CLI options
claude --help

# Check version
claude --version

# View configuration
cat ~/.claude/config.json
```

---

## Documentation

### Additional Guides

- **[Architecture Guide](docs/architecture/)** - Deep dive into Claude Code internals
- **[Best Practices](docs/best-practices/)** - Production deployment patterns
- **[Troubleshooting](docs/troubleshooting/)** - Comprehensive problem-solving guide
- **[Security Guide](docs/security/)** - Security hardening and compliance

### Example Collections

- **[Basic Examples](examples/01-basic/)** - Foundational patterns
- **[Intermediate Examples](examples/02-intermediate/)** - Multi-turn workflows
- **[Agent Examples](examples/04-agents/)** - Sub-agent orchestration
- **[Skills Examples](examples/05-skills/)** - Custom skill development
- **[Remote Examples](examples/06-remote/)** - Distributed execution

---

## Resources

### Official Documentation

- **Claude Code Docs**: https://code.claude.com/docs
- **Headless Mode**: https://code.claude.com/docs/en/headless.md
- **Sub-Agents**: https://code.claude.com/docs/en/sub-agents.md
- **Skills**: https://code.claude.com/docs/en/skills.md
- **CLI Reference**: https://code.claude.com/docs/en/cli-reference.md

### Community

- **GitHub Issues**: https://github.com/anthropics/claude-code/issues
- **Discussions**: Join the Claude Code community

---

## Repository Structure

```
headless-claude/
├── README.md                          # This file - comprehensive overview
├── lib/                               # Library files (reference)
│   └── claude-headless.sh            # Shell library (for reference only)
├── examples/                          # All examples with commands
│   ├── 01-basic/                     # Basic headless patterns
│   │   └── README.md
│   ├── 02-intermediate/              # Multi-turn and session management
│   │   └── README.md
│   ├── 03-advanced/                  # Complex orchestration (coming soon)
│   │   └── README.md
│   ├── 04-agents/                    # Sub-agent examples
│   │   └── README.md
│   ├── 05-skills/                    # Skills framework
│   │   └── README.md
│   ├── 06-remote/                    # Remote execution
│   │   └── README.md
│   ├── 07-pipelines/                 # Workflow orchestration (coming soon)
│   │   └── README.md
│   └── 08-monitoring/                # Observability (coming soon)
│       └── README.md
├── docs/                              # Additional documentation
│   ├── architecture/                 # Architecture deep-dives
│   ├── best-practices/               # Production patterns
│   └── troubleshooting/              # Problem-solving guides
├── templates/                         # Template files
│   ├── agents/                       # Agent templates
│   └── skills/                       # Skill templates
└── config/                            # Configuration examples
    ├── mcp-config.json               # MCP server configuration
    └── settings.json                 # Claude settings examples
```

---

## Quick Navigation

### By Experience Level

- **Beginner**: Start with [01-basic/](examples/01-basic/)
- **Intermediate**: Move to [02-intermediate/](examples/02-intermediate/)
- **Advanced**: Explore [04-agents/](examples/04-agents/) and [05-skills/](examples/05-skills/)
- **Expert**: Dive into [06-remote/](examples/06-remote/) and distributed patterns

### By Use Case

- **Code Review**: [01-basic/](examples/01-basic/), [04-agents/](examples/04-agents/)
- **Security Auditing**: [05-skills/](examples/05-skills/) (api-security-check)
- **CI/CD Integration**: [06-remote/](examples/06-remote/)
- **Multi-Host Analysis**: [06-remote/](examples/06-remote/)
- **Custom Automation**: [02-intermediate/](examples/02-intermediate/), [04-agents/](examples/04-agents/)

### By Technology

- **SSH**: [06-remote/](examples/06-remote/)
- **Docker/Kubernetes**: [06-remote/](examples/06-remote/)
- **AWS/GCP/Azure**: [06-remote/](examples/06-remote/)
- **GitHub Actions/GitLab CI**: [06-remote/](examples/06-remote/)

---

## Contributing

Contributions are welcome! Please:

1. Read existing examples to understand the style
2. Ensure all examples use actual commands (not scripts)
3. Include comprehensive documentation
4. Test all commands before submitting
5. Follow security best practices

---

## License

MIT License - See [LICENSE](LICENSE) file for details

---

## Acknowledgments

This guide is built on the excellent official Claude Code documentation and community contributions.

Special thanks to the Claude Code team at Anthropic for building such a powerful tool.

---

<div align="center">

**[Back to Top](#the-ultimate-headless-claude-code-guide)** •
**[Examples](#examples)** •
**[Documentation](#documentation)**

Made with precision and depth for the Claude Code community

</div>
