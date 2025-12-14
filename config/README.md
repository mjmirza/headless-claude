# Configuration Examples

Example configuration files for Claude Code headless usage.

## Files

### mcp-config.json

Model Context Protocol (MCP) server configuration for external integrations.

**Usage:**
```bash
# Use MCP configuration
claude -p "Fetch GitHub issues" --mcp-config config/mcp-config.json

# Use only specified MCP servers (strict mode)
claude -p "Query database" \
  --mcp-config config/mcp-config.json \
  --strict-mcp-config
```

**Available Servers:**

1. **GitHub** - Repository, issues, PRs
   - Requires: `GITHUB_TOKEN`
   - Example: `claude -p "List open issues in my repo"`

2. **Filesystem** - File operations
   - Provides access to `/workspace`
   - Example: `claude -p "Read all JSON files"`

3. **PostgreSQL** - Database access
   - Requires: `DATABASE_URL`
   - Example: `claude -p "Show table schema"`

4. **Slack** - Messaging
   - Requires: `SLACK_BOT_TOKEN`, `SLACK_TEAM_ID`
   - Example: `claude -p "Post to #general channel"`

5. **Brave Search** - Web search
   - Requires: `BRAVE_API_KEY`
   - Example: `claude -p "Search for Claude Code docs"`

**Environment Variables:**

Set these before using MCP config:

```bash
export GITHUB_TOKEN="ghp_..."
export DATABASE_URL="postgresql://user:pass@host/db"
export SLACK_BOT_TOKEN="xoxb-..."
export SLACK_TEAM_ID="T..."
export BRAVE_API_KEY="BSA..."

claude -p "Task using MCP" --mcp-config config/mcp-config.json
```

---

## Custom MCP Configuration

Create your own MCP configuration:

```json
{
  "mcpServers": {
    "your-server": {
      "command": "node",
      "args": ["path/to/your/mcp-server.js"],
      "env": {
        "YOUR_API_KEY": "${YOUR_API_KEY}"
      },
      "description": "Your custom MCP server"
    }
  }
}
```

---

## Claude Settings

Example settings.json for Claude Code:

```json
{
  "model": "sonnet",
  "maxTurns": 30,
  "permissionMode": "default",
  "allowedTools": [
    "Read",
    "Write",
    "Edit",
    "Grep",
    "Glob",
    "Bash"
  ],
  "logLevel": "info",
  "outputFormat": "text"
}
```

**Usage:**
```bash
claude -p "Task" --settings config/settings.json
```

---

## Agent Configuration Examples

### Security Auditor Agent

`.claude/agents/security-auditor.md`:

```markdown
---
name: security-auditor
description: Performs comprehensive security audits including OWASP Top 10, authentication analysis, and cryptographic review
model: sonnet
tools: Read, Grep, Glob
permissionMode: plan
---

# Security Auditor Agent

Specialized in application security analysis.

## Process

1. **Reconnaissance**: Map attack surface
2. **Vulnerability Scan**: Check OWASP Top 10
3. **Authentication Review**: Analyze auth mechanisms
4. **Crypto Analysis**: Verify encryption usage
5. **Report**: Generate findings with severity ratings
```

### Performance Optimizer Agent

`.claude/agents/performance-optimizer.md`:

```markdown
---
name: performance-optimizer
description: Identifies performance bottlenecks, analyzes complexity, and suggests optimizations
model: sonnet
tools: Read, Grep, Glob, Bash
permissionMode: plan
---

# Performance Optimizer Agent

Analyzes and optimizes code performance.

## Analysis

1. Time complexity analysis
2. Memory usage profiling
3. Database query optimization
4. Caching opportunities
5. Async/parallel opportunities
```

---

## Skill Configuration Examples

### API Security Check Skill

`.claude/skills/api-security/SKILL.md`:

```markdown
---
name: api-security-check
description: Validates API endpoints for security including authentication, authorization, input validation, and rate limiting
allowed-tools: Read, Grep, Glob
---

# API Security Check

Comprehensive API security validation.

## Checks

1. Authentication implementation
2. Authorization controls
3. Input validation
4. Rate limiting
5. Error handling
6. Data exposure
```

---

## System Prompt Templates

### Security Focus

`config/prompts/security-focused.txt`:

```
You are a security expert specializing in application security.

Your analysis must:
1. Focus on OWASP Top 10 vulnerabilities
2. Flag all potential security issues
3. Provide proof-of-concept exploits
4. Suggest secure remediation with code examples
5. Rate severity (Critical/High/Medium/Low)

Be thorough and assume adversarial mindset.
```

**Usage:**
```bash
claude -p "Audit auth module" \
  --system-prompt-file config/prompts/security-focused.txt
```

### Performance Focus

`config/prompts/performance-focused.txt`:

```
You are a performance optimization expert.

Your analysis must:
1. Identify algorithmic complexity issues
2. Find memory inefficiencies
3. Spot database performance problems
4. Suggest caching strategies
5. Recommend async/parallel opportunities

Provide benchmarks and concrete optimizations.
```

---

## Docker Configuration

### Dockerfile

```dockerfile
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code
RUN curl -fsSL https://releases.claude.com/claude-code/install.sh | bash

# Create claudeuser
RUN useradd -m -s /bin/bash claudeuser

# Set working directory
WORKDIR /workspace

# Default command
USER claudeuser
CMD ["claude", "--version"]
```

### docker-compose.yml

```yaml
version: '3.8'

services:
  claude-security:
    build: .
    volumes:
      - ./:/workspace:ro
    environment:
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
    command: >
      claude -p "Security audit of /workspace"
      --allowedTools "Read,Grep,Glob"
      --output-format json

  claude-performance:
    build: .
    volumes:
      - ./:/workspace:ro
    environment:
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
    command: >
      claude -p "Performance analysis of /workspace"
      --output-format json

  claude-tests:
    build: .
    volumes:
      - ./:/workspace
    environment:
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
    command: >
      claude -p "Generate missing tests"
      --allowedTools "Read,Write,Grep,Glob,Bash"
```

---

## CI/CD Configuration

### GitHub Actions

`.github/workflows/claude-review.yml`:

```yaml
name: Claude Code Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - name: Install Claude
        run: curl -fsSL https://releases.claude.com/install.sh | bash

      - name: Run Review
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          claude -p "Review PR changes for security and quality" \
            --output-format json > review.json

      - name: Comment on PR
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const review = JSON.parse(fs.readFileSync('review.json'));
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## Claude Review\n\n${review.result}`
            });
```

### GitLab CI

`.gitlab-ci.yml`:

```yaml
stages:
  - analyze

claude-review:
  stage: analyze
  image: ubuntu:22.04
  before_script:
    - apt-get update && apt-get install -y curl
    - curl -fsSL https://releases.claude.com/install.sh | bash
  script:
    - |
      claude -p "Analyze code changes" \
        --output-format json > analysis.json
  artifacts:
    reports:
      codequality: analysis.json
  only:
    - merge_requests
```

---

## Kubernetes Configuration

### ConfigMap for MCP

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: claude-mcp-config
data:
  mcp-config.json: |
    {
      "mcpServers": {
        "github": {
          "command": "npx",
          "args": ["-y", "@modelcontextprotocol/server-github"],
          "env": {
            "GITHUB_TOKEN": "${GITHUB_TOKEN}"
          }
        }
      }
    }
```

### Job Configuration

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: claude-analysis
spec:
  template:
    spec:
      containers:
      - name: claude
        image: claude-headless:latest
        command:
        - /bin/bash
        - -c
        - |
          claude -p "Analyze codebase" \
            --mcp-config /config/mcp-config.json \
            --output-format json
        env:
        - name: ANTHROPIC_API_KEY
          valueFrom:
            secretKeyRef:
              name: anthropic-secret
              key: api-key
        - name: GITHUB_TOKEN
          valueFrom:
            secretKeyRef:
              name: github-secret
              key: token
        volumeMounts:
        - name: workspace
          mountPath: /workspace
        - name: config
          mountPath: /config
      volumes:
      - name: workspace
        persistentVolumeClaim:
          claimName: code-workspace
      - name: config
        configMap:
          name: claude-mcp-config
      restartPolicy: Never
```

---

## SSH Configuration

`~/.ssh/config`:

```
Host claude-server-*
    User claudeuser
    IdentityFile ~/.ssh/claude-deploy-key
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ServerAliveInterval 60
    ServerAliveCountMax 3

Host claude-server-prod-*
    User claudeuser
    IdentityFile ~/.ssh/claude-prod-key
    ForwardAgent yes
    ProxyJump bastion.company.com
```

**Usage:**
```bash
ssh claude-server-01 "claude -p 'health check'"
```

---

## Systemd Service

`/etc/systemd/system/claude-worker.service`:

```ini
[Unit]
Description=Claude Code Worker
After=network.target

[Service]
Type=simple
User=claudeuser
Group=claudeuser
WorkingDirectory=/opt/claude-workspace
EnvironmentFile=/etc/claude/environment
ExecStart=/usr/local/bin/claude-worker.sh
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=claude-worker

# Security
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/claude-workspace /var/log/claude

# Resource limits
MemoryLimit=2G
CPUQuota=50%

[Install]
WantedBy=multi-user.target
```

`/etc/claude/environment`:

```bash
ANTHROPIC_API_KEY=sk-ant-...
CLAUDE_LOG_DIR=/var/log/claude
CLAUDE_WORKSPACE=/opt/claude-workspace
```

---

## Usage Examples

### With MCP Config
```bash
export GITHUB_TOKEN="ghp_..."
claude -p "List my GitHub repos" --mcp-config config/mcp-config.json
```

### With Custom Settings
```bash
claude -p "Analyze code" --settings config/settings.json
```

### With System Prompt
```bash
claude -p "Review security" --system-prompt-file config/prompts/security-focused.txt
```

### Docker Compose
```bash
docker-compose up claude-security
docker-compose logs claude-security | jq -r '.result'
```

### CI/CD
```bash
# GitHub Actions runs automatically on PR
# GitLab CI runs on merge request
```

---

## References

- **MCP Documentation**: https://code.claude.com/docs/en/mcp.md
- **Configuration Guide**: https://code.claude.com/docs
- **Examples**: See [../examples/](../examples/)
