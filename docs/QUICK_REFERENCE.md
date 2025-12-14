# Claude Code Headless Quick Reference

Ultra-compact reference for common headless patterns and commands.

## Basic Commands

```bash
# Simple execution
claude -p "your prompt here"

# JSON output
claude -p "your prompt" --output-format json

# Continue last conversation
claude -c -p "next step"

# Resume specific session
claude -r SESSION_ID -p "continue"

# Specific model
claude -p "task" --model haiku|sonnet|opus

# Skip permissions (automation)
claude --dangerously-skip-permissions -p "task"
```

## Multi-User Execution

```bash
# As dedicated user
su - claudeuser -c 'claude -p "task"'

# With environment
su - claudeuser -c 'ANTHROPIC_API_KEY=sk-xxx claude -p "task"'

# With timeout
timeout 300 su - claudeuser -c 'claude -p "task"'
```

## Output Formats

```bash
# Text (default)
claude -p "task"

# JSON (for parsing)
claude -p "task" --output-format json | jq -r '.result'

# Streaming (real-time)
claude -p "task" --output-format stream-json | \
while read line; do
  echo "$line" | jq -r '.type'
done
```

## Session Management

```bash
# Capture session ID
RESULT=$(claude -p "start" --output-format json)
SESSION=$(echo "$RESULT" | jq -r '.metadata.sessionId')

# Resume
claude -r "$SESSION" -p "continue"

# Continue last
claude -c -p "next"

# Custom session ID
claude -p "task" --session-id "my-session-123"
```

## Tool Configuration

```bash
# Allow specific tools only
claude -p "task" --allowedTools "Read,Grep,Glob"

# Disallow specific tools
claude -p "task" --disallowedTools "Write,Edit"

# Read-only analysis
claude -p "analyze" --allowedTools "Read,Grep,Glob"

# Implementation with limits
claude -p "implement" --allowedTools "Read,Write,Edit"
```

## System Prompts

```bash
# Append to default
claude -p "task" --append-system-prompt "Follow PEP 8 style guide"

# Replace entirely
claude -p "task" --system-prompt "You are a security expert..."

# From file
claude -p "task" --system-prompt-file custom-prompt.txt
```

## Agent Usage

```bash
# Explore agent (fast search)
claude -p "Use Explore agent to find API files"

# Explore with thoroughness
claude -p "Use Explore agent (very thorough) to locate all tests"

# Custom agent
claude -p "Use security-auditor agent to scan for vulnerabilities"

# Agent with specific task
claude -p "Use performance-optimizer agent to analyze database queries"

# Resume agent
claude -p "Resume agent agent-abc123 and continue analysis"
```

## Remote Execution

```bash
# Simple SSH
ssh user@server "claude -p 'task'"

# As dedicated user
ssh user@server "su - claudeuser -c 'claude -p \"task\"'"

# With output capture
ssh user@server "claude -p 'task' --output-format json" > result.json

# Parallel across hosts
for host in host{1..10}; do
  ssh user@$host "claude -p 'task'" &
done
wait
```

## Error Handling

```bash
# With timeout
timeout 300 claude -p "task"

# With retry
for i in {1..3}; do
  claude -p "task" && break || sleep 5
done

# With error capture
if ! claude -p "task" 2>&1 | tee error.log; then
  echo "Failed, see error.log"
fi

# Exit on any error
set -e
claude -p "task"
```

## Common Patterns

### Code Review
```bash
PR_DIFF=$(git diff main...feature)
claude -p "Review this code: $PR_DIFF" --output-format json > review.json
```

### Security Scan
```bash
claude -p "Scan for security vulnerabilities in src/" \
  --allowedTools "Read,Grep,Glob" \
  --output-format json > security.json
```

### Multi-Stage Analysis
```bash
SESSION=$(claude -p "Stage 1: Analyze" --output-format json | jq -r '.metadata.sessionId')
claude -r "$SESSION" -p "Stage 2: Design fix"
claude -r "$SESSION" -p "Stage 3: Generate report"
```

### Parallel Tasks
```bash
{
  claude -p "Security audit" > security.txt
} &
{
  claude -p "Performance check" > performance.txt
} &
{
  claude -p "Code quality review" > quality.txt
} &
wait
```

### Cost Tracking
```bash
RESULT=$(claude -p "task" --output-format json)
COST=$(echo "$RESULT" | jq -r '.metadata.totalCost')
echo "$COST" >> costs.log
```

## Debugging

```bash
# Verbose output
claude -p "task" --verbose

# Debug mode
claude -p "task" --debug

# Debug specific categories
claude -p "task" --debug mcp,tools

# Full debug
claude -p "task" --debug all 2>&1 | tee debug.log
```

## Performance Optimization

```bash
# Fast model for simple tasks
claude -p "find files" --model haiku

# Limit turns
claude -p "quick scan" --max-turns 5

# Use Explore agent for searches
claude -p "Use Explore agent (quick) to find configs"

# Parallel execution
for task in task{1..5}; do
  claude -p "$task" &
done
wait
```

## CI/CD Integration

### GitHub Actions
```yaml
- run: |
    claude -p "Review changes" --output-format json > review.json
    jq -r '.result' review.json
```

### GitLab CI
```yaml
script:
  - claude -p "Security scan" --output-format json | tee scan.json
artifacts:
  paths:
    - scan.json
```

### Jenkins
```groovy
sh 'claude -p "Analyze code" --output-format json > analysis.json'
def result = readJSON file: 'analysis.json'
```

## Docker

```dockerfile
FROM ubuntu:22.04
RUN curl -fsSL https://releases.claude.com/install.sh | bash
RUN useradd -m claudeuser
WORKDIR /workspace
CMD ["claude"]
```

```bash
# Run
docker run --rm -v $(pwd):/workspace claude-image \
  claude -p "analyze /workspace"
```

## Kubernetes

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
        image: claude-image
        command: ["claude", "-p", "analyze code"]
        env:
        - name: ANTHROPIC_API_KEY
          valueFrom:
            secretKeyRef:
              name: anthropic
              key: api-key
```

## Environment Variables

```bash
# API key
export ANTHROPIC_API_KEY="sk-ant-..."

# Custom config
export CLAUDE_CONFIG_DIR="$HOME/.config/claude"

# Custom log dir
export CLAUDE_LOG_DIR="/var/log/claude"
```

## Flags Cheat Sheet

| Flag | Short | Description | Example |
|------|-------|-------------|---------|
| `--print` | `-p` | Non-interactive mode | `claude -p "task"` |
| `--continue` | `-c` | Resume last session | `claude -c -p "next"` |
| `--resume` | `-r` | Resume specific session | `claude -r ID -p "continue"` |
| `--output-format` | | Output format | `--output-format json` |
| `--model` | | Select model | `--model haiku` |
| `--max-turns` | | Limit turns | `--max-turns 20` |
| `--allowedTools` | | Whitelist tools | `--allowedTools "Read,Grep"` |
| `--disallowedTools` | | Blacklist tools | `--disallowedTools "Write"` |
| `--dangerously-skip-permissions` | | Skip prompts | (use carefully!) |
| `--verbose` | | Verbose logging | `--verbose` |
| `--debug` | | Debug mode | `--debug all` |
| `--append-system-prompt` | | Add to prompt | `--append-system-prompt "..."` |
| `--system-prompt-file` | | Prompt from file | `--system-prompt-file file.txt` |

## Model Selection

| Model | Use For | Speed | Cost |
|-------|---------|-------|------|
| `haiku` | Quick searches, simple tasks | Fast | Low |
| `sonnet` | Standard analysis, implementation | Medium | Medium |
| `opus` | Complex reasoning, architecture | Slow | High |

## Tool Sets by Use Case

```bash
# Read-only analysis
--allowedTools "Read,Grep,Glob"

# Safe execution
--allowedTools "Read,Grep,Glob,Bash"

# Implementation
--allowedTools "Read,Write,Edit,Grep,Glob"

# Testing
--allowedTools "Read,Write,Bash"

# Full access (default)
# No --allowedTools flag
```

## Quick Troubleshooting

```bash
# Session won't resume
# - Verify session ID from .metadata.sessionId
# - Check ~/.claude/transcripts/ for session file

# Permission errors
# - Use --dangerously-skip-permissions (carefully!)
# - Or: --allowedTools "..."
# - Or: --permission-mode acceptEdits

# Timeout issues
# - Add: timeout 600 claude -p "task"
# - Or: --max-turns 50

# Output truncated
# - Increase: --max-turns N
# - Or use: --output-format stream-json

# Agent not activating
# - Check .claude/agents/agent.md exists
# - Verify YAML frontmatter
# - Use explicit: "Use agent-name agent to..."

# Rate limits
# - Add delays: sleep 2
# - Implement backoff
# - Batch related tasks
```

## One-Liners

```bash
# Quick file search
claude -p "List all TypeScript files" --model haiku

# Security scan
claude -p "Scan for hardcoded secrets" --allowedTools "Read,Grep,Glob" --output-format json | jq -r '.result'

# Test all servers
for s in server{1..10}; do ssh $s "claude -p 'check health'"; done

# Cost report
grep cost logs/claude.json | jq -s 'map(.metadata.totalCost) | add'

# Parallel analysis
{ claude -p "security"; } & { claude -p "performance"; } & wait

# Session-based workflow
SID=$(claude -p "start" --output-format json | jq -r '.metadata.sessionId'); \
claude -r "$SID" -p "step 2"; \
claude -r "$SID" -p "step 3"

# With retry
until claude -p "task"; do sleep 5; done

# Docker execution
docker run --rm -v $(pwd):/w claude claude -p "analyze /w"

# Budget tracking
echo "$(date),$(claude -p 'task' --output-format json | jq .metadata.totalCost)" >> budget.csv
```

## Templates

### Retry Wrapper
```bash
retry() {
  for i in {1..3}; do
    $@ && return 0 || sleep 5
  done
  return 1
}

retry claude -p "unreliable task"
```

### Session Wrapper
```bash
with_session() {
  local task="$1"
  local session_file=".claude-session"

  if [ -f "$session_file" ]; then
    claude -r "$(cat $session_file)" -p "$task"
  else
    claude -p "$task" --output-format json | \
      tee >(jq -r '.metadata.sessionId' > "$session_file")
  fi
}

with_session "step 1"
with_session "step 2"
```

### Cost Tracker
```bash
track() {
  local result=$(claude -p "$@" --output-format json)
  echo "$result" | jq -r '[now, .metadata.totalCost] | @csv' >> costs.csv
  echo "$result" | jq -r '.result'
}

track "analyze code"
```

---

## Resources

- **Full Guide**: [../README.md](../README.md)
- **Examples**: [../examples/](../examples/)
- **Best Practices**: [best-practices/](best-practices/)
- **Official Docs**: https://code.claude.com/docs
