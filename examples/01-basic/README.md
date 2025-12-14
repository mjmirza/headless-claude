# Basic Headless Claude Code Examples

This directory contains foundational examples for running Claude Code in headless mode. These examples demonstrate essential patterns for non-interactive automation.

## Table of Contents

1. [Simple One-Shot Execution](#simple-one-shot-execution)
2. [Multi-User Execution](#multi-user-execution)
3. [Output Formatting](#output-formatting)
4. [Input Methods](#input-methods)
5. [Permission Management](#permission-management)

---

## Simple One-Shot Execution

### Basic Command

The simplest form of headless execution:

```bash
claude -p "Explain what this directory contains"
```

**Breakdown:**
- `-p` or `--print`: Runs in non-interactive mode and outputs result
- Query in quotes: Your prompt/task for Claude

### With Specific Model

```bash
claude -p "Analyze this codebase structure" --model sonnet
```

**Available models:**
- `sonnet` (default) - Claude Sonnet 4.5
- `opus` - Claude Opus (more capable, slower)
- `haiku` - Claude Haiku (faster, lighter tasks)

---

## Multi-User Execution

### Running as Different User (Isolated Environment)

This is critical for security and isolation in production environments:

```bash
# Create dedicated user (one-time setup)
sudo useradd -m -s /bin/bash claudeuser

# Execute as claudeuser
su - claudeuser -c 'claude --dangerously-skip-permissions -p "Analyze the /tmp/project directory"'
```

**Why use a dedicated user?**
- **Security isolation**: Limits file system access
- **Resource control**: Easier to monitor and limit resources
- **Clean environment**: Predictable, controlled execution context
- **Production safety**: Prevents accidental modifications to system files

### Advanced Multi-User Pattern

```bash
# Execute with specific working directory
su - claudeuser -c 'cd /path/to/project && claude -p "Review recent changes"'

# With environment variables
su - claudeuser -c 'CLAUDE_API_KEY=sk-xxx claude -p "Deploy latest version"'

# Combined with timeout for safety
timeout 300 su - claudeuser -c 'claude -p "Run comprehensive tests"'
```

---

## Output Formatting

### Text Output (Default)

```bash
claude -p "Summarize this project" --output-format text
```

Returns plain text response - ideal for:
- Human-readable output
- Simple script integration
- Logging to files

### JSON Output

```bash
claude -p "List all TypeScript files" --output-format json
```

**Example JSON structure:**
```json
{
  "result": "Here are the TypeScript files...",
  "metadata": {
    "totalCost": 0.0123,
    "duration": 4500,
    "turns": 3,
    "sessionId": "abc123xyz"
  }
}
```

**Use cases:**
- Parsing responses programmatically
- Extracting metadata (cost, duration, session ID)
- Building dashboards and analytics
- Chain operations based on structured data

### Streaming JSON Output

```bash
claude -p "Analyze large codebase" --output-format stream-json
```

**Benefits:**
- Real-time progress monitoring
- Process partial results before completion
- Better UX for long-running operations
- Lower memory footprint

**Example stream:**
```json
{"type":"message","content":"Starting analysis..."}
{"type":"tool_use","tool":"Grep","status":"running"}
{"type":"tool_result","tool":"Grep","output":"..."}
{"type":"message","content":"Analysis complete"}
```

### Capturing Output to File

```bash
# Basic capture
claude -p "Generate test cases" > output.txt

# JSON to file for processing
claude -p "Audit dependencies" --output-format json > audit.json

# Both stdout and stderr
claude -p "Build and test" 2>&1 | tee build-log.txt

# Process JSON with jq
claude -p "List issues" --output-format json | jq '.result'
```

---

## Input Methods

### Direct Argument (Simple Prompts)

```bash
claude -p "What is the main function in src/index.ts?"
```

**Best for:** Short, simple queries

### Stdin Pipe (File Content)

```bash
# Pipe file content
cat config.json | claude -p "Validate this configuration"

# Multiple files
cat src/*.ts | claude -p "Find potential bugs"

# With heredoc for complex prompts
cat <<'EOF' | claude -p
Analyze the following code and provide:
1. Security vulnerabilities
2. Performance issues
3. Best practice violations
EOF
```

### File-Based Prompts

```bash
# Store prompt in file
cat > prompt.txt <<'EOF'
Review the authentication implementation in this project.
Focus on:
- JWT token handling
- Password hashing
- Session management
- CSRF protection
EOF

# Execute with file prompt
claude -p "$(cat prompt.txt)"
```

### Multi-Line Prompts with Variables

```bash
# Using heredoc with variable substitution
PROJECT_PATH="/path/to/project"
FOCUS_AREA="authentication"

claude -p "$(cat <<EOF
Analyze the ${FOCUS_AREA} system in ${PROJECT_PATH}.
Provide detailed security assessment.
EOF
)"
```

---

## Permission Management

### Skip Permissions (Automation Mode)

```bash
claude --dangerously-skip-permissions -p "Refactor helper functions"
```

**⚠️ WARNING:** Only use in trusted, controlled environments!

**When to use:**
- CI/CD pipelines
- Scheduled automation tasks
- Read-only analysis
- Isolated sandbox environments

**When NOT to use:**
- Production systems with write access
- Untrusted code analysis
- Multi-tenant environments

### Controlled Permissions (Safer Automation)

```bash
# Allow only read operations
claude -p "Analyze code quality" \
  --allowedTools "Read,Grep,Glob,Bash"

# Explicitly disallow dangerous tools
claude -p "Review configuration" \
  --disallowedTools "Write,Edit,Bash"
```

### Permission Modes

```bash
# Start in specific permission mode
claude -p "Update documentation" --permission-mode acceptEdits

# Combination with allowed tools
claude -p "Search and report issues" \
  --permission-mode default \
  --allowedTools "Read,Grep,Glob"
```

**Available permission modes:**
- `default` - Prompt for all permissions
- `acceptEdits` - Auto-accept file edits
- `bypassPermissions` - Skip all prompts (dangerous!)
- `plan` - Planning mode (read-only)

---

## Practical Examples

### Example 1: Code Review Automation

```bash
#!/bin/bash
# review-pr.sh

PR_NUMBER="$1"
OUTPUT_FILE="review-${PR_NUMBER}.json"

# Fetch PR diff
git fetch origin pull/${PR_NUMBER}/head:pr-${PR_NUMBER}
git diff main...pr-${PR_NUMBER} > /tmp/pr-${PR_NUMBER}.diff

# Run Claude review
su - claudeuser -c "claude -p 'Review this PR diff for:
1. Security issues
2. Code quality
3. Test coverage
4. Performance concerns' \
--output-format json \
--allowedTools Read,Grep,Glob" < /tmp/pr-${PR_NUMBER}.diff > "${OUTPUT_FILE}"

# Extract and display results
jq -r '.result' "${OUTPUT_FILE}"
```

**Usage:**
```bash
./review-pr.sh 123
```

### Example 2: Scheduled Code Analysis

```bash
#!/bin/bash
# daily-analysis.sh

DATE=$(date +%Y%m%d)
LOG_FILE="analysis-${DATE}.log"

{
  echo "=== Daily Code Analysis: ${DATE} ==="

  # Security scan
  echo "Running security scan..."
  timeout 600 claude -p "Scan for security vulnerabilities in src/" \
    --output-format text \
    --allowedTools "Read,Grep,Glob"

  # Dependency audit
  echo "Auditing dependencies..."
  timeout 300 claude -p "Audit package.json for outdated or vulnerable packages" \
    --output-format text

  # Code quality metrics
  echo "Analyzing code quality..."
  timeout 300 claude -p "Analyze code quality and suggest improvements" \
    --output-format text

} | tee "${LOG_FILE}"

# Send to monitoring system
cat "${LOG_FILE}" | send-to-slack.sh
```

**Cron entry:**
```cron
0 2 * * * /path/to/daily-analysis.sh
```

### Example 3: Multi-Step Processing Pipeline

```bash
#!/bin/bash
# process-pipeline.sh

# Step 1: Extract information
EXTRACTED=$(claude -p "Extract all API endpoints from src/" \
  --output-format json | jq -r '.result')

# Step 2: Analyze with context
ANALYSIS=$(echo "$EXTRACTED" | claude -p "Analyze these API endpoints for:
- RESTful design compliance
- Security best practices
- Documentation completeness" \
  --output-format json)

# Step 3: Generate report
echo "$ANALYSIS" | claude -p "Generate a markdown report" \
  --output-format text > api-analysis-report.md

echo "Report generated: api-analysis-report.md"
```

---

## Best Practices

### 1. Always Set Timeouts

```bash
# Prevent hung processes
timeout 300 claude -p "Long running task"

# With custom timeout handler
timeout --signal=TERM --kill-after=10 300 claude -p "Task"
```

### 2. Handle Errors Gracefully

```bash
#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures

if ! claude -p "Validate config"; then
  echo "Claude execution failed!" >&2
  exit 1
fi
```

### 3. Log Everything

```bash
# Timestamped logging
claude -p "Deploy application" 2>&1 | while read line; do
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) $line"
done >> deployment.log
```

### 4. Use JSON for Programmatic Access

```bash
# Extract specific data
RESULT=$(claude -p "List TODO items" --output-format json | jq -r '.result')
SESSION_ID=$(claude -p "Analyze code" --output-format json | jq -r '.metadata.sessionId')
COST=$(claude -p "Generate tests" --output-format json | jq -r '.metadata.totalCost')
```

### 5. Isolate Execution Environments

```bash
# Use dedicated user
su - claudeuser -c 'claude -p "task"'

# Or use containers
docker run --rm -v $(pwd):/workspace claude-env claude -p "task"

# Or use systemd-run for resource limits
systemd-run --scope -p MemoryLimit=2G -p CPUQuota=50% \
  su - claudeuser -c 'claude -p "task"'
```

---

## Troubleshooting

### Issue: "Permission denied"

```bash
# Ensure user has access to required files
sudo chown -R claudeuser:claudeuser /path/to/project

# Or add to group
sudo usermod -a -G projectgroup claudeuser
```

### Issue: Output is truncated

```bash
# Increase max turns for complex tasks
claude -p "Complex analysis" --max-turns 50
```

### Issue: API rate limits

```bash
# Add delays between requests
for task in task1 task2 task3; do
  claude -p "$task"
  sleep 2  # 2 second delay
done
```

### Issue: Debugging execution

```bash
# Enable verbose mode
claude -p "Debug this" --verbose

# Enable debug mode with categories
claude -p "Debug this" --debug mcp,tools

# Full debug output
claude -p "Debug this" --debug all 2>&1 | tee debug.log
```

---

## Next Steps

- **Intermediate Examples** → See [../02-intermediate/](../02-intermediate/) for multi-turn conversations
- **Advanced Examples** → See [../03-advanced/](../03-advanced/) for complex orchestration
- **Agent Examples** → See [../04-agents/](../04-agents/) for sub-agent usage
