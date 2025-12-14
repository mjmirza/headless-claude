# Intermediate Headless Claude Code Examples

This directory covers multi-turn conversations, session management, and stateful automation patterns that build upon basic headless usage.

## Table of Contents

1. [Session Continuation](#session-continuation)
2. [Multi-Turn Conversations](#multi-turn-conversations)
3. [Streaming JSON Interactions](#streaming-json-interactions)
4. [Custom System Prompts](#custom-system-prompts)
5. [Advanced Tool Configuration](#advanced-tool-configuration)

---

## Session Continuation

### Resume Most Recent Conversation

```bash
# First execution
claude -p "Start analyzing the authentication module"

# Continue from where it left off
claude -c -p "Now check for SQL injection vulnerabilities"

# Further continuation
claude --continue -p "Generate a security report"
```

**Use cases:**
- Multi-step analysis workflows
- Iterative code reviews
- Progressive refactoring tasks
- Building context over multiple commands

### Resume Specific Session by ID

```bash
# Initial execution - capture session ID
RESULT=$(claude -p "Begin code audit" --output-format json)
SESSION_ID=$(echo "$RESULT" | jq -r '.metadata.sessionId')

echo "Session ID: $SESSION_ID"
# Output: Session ID: abc123def456

# Resume specific session later
claude -r "$SESSION_ID" -p "Continue the audit with database queries"

# Multiple resumes of same session
claude --resume "$SESSION_ID" -p "Final recommendations"
```

**Advanced pattern - Session tracking:**
```bash
#!/bin/bash
# session-workflow.sh

SESSION_FILE=".claude-session"

# Start new analysis
RESULT=$(claude -p "Analyze API security" --output-format json)
SESSION_ID=$(echo "$RESULT" | jq -r '.metadata.sessionId')
echo "$SESSION_ID" > "$SESSION_FILE"

echo "Analysis started. Session: $SESSION_ID"

# Later, resume the session
resume_analysis() {
  SESSION_ID=$(cat "$SESSION_FILE")
  claude -r "$SESSION_ID" -p "$1"
}

# Usage
resume_analysis "Check authentication implementation"
resume_analysis "Review authorization logic"
```

### Fork Sessions for Parallel Exploration

```bash
# Original session
claude -p "Review user authentication" --session-id "auth-review"

# Fork for different approaches
claude -r "auth-review" --fork-session -p "Explore JWT implementation"
claude -r "auth-review" --fork-session -p "Explore OAuth2 flow"

# Original remains unchanged
claude -r "auth-review" -p "Continue original review"
```

---

## Multi-Turn Conversations

### Controlling Conversation Depth

```bash
# Limit turns for simple tasks
claude -p "Quick security scan" --max-turns 5

# Allow deeper investigation
claude -p "Comprehensive architecture review" --max-turns 50

# Unlimited turns (use cautiously)
claude -p "Refactor entire module" --max-turns 999
```

**Turn limits by use case:**
- **Quick queries:** 1-5 turns
- **Standard analysis:** 10-20 turns
- **Complex refactoring:** 30-50 turns
- **Full audits:** 50+ turns

### Multi-Turn Pipeline Pattern

```bash
#!/bin/bash
# multi-stage-analysis.sh

PROJECT_DIR="$1"
REPORT_FILE="analysis-report.md"

# Stage 1: Initial scan (capture session)
echo "Stage 1: Initial Security Scan"
RESULT=$(claude -p "Perform initial security scan of $PROJECT_DIR" \
  --output-format json \
  --max-turns 10)

SESSION=$(echo "$RESULT" | jq -r '.metadata.sessionId')
FINDINGS=$(echo "$RESULT" | jq -r '.result')

echo "$FINDINGS" > /tmp/stage1.txt

# Stage 2: Deep dive on findings
echo "Stage 2: Deep Analysis"
claude -r "$SESSION" -p "For each security issue found, provide:
1. Severity level (Critical/High/Medium/Low)
2. Detailed explanation
3. Proof of concept exploit
4. Remediation steps" \
  --max-turns 20 > /tmp/stage2.txt

# Stage 3: Generate comprehensive report
echo "Stage 3: Report Generation"
claude -r "$SESSION" -p "Generate a comprehensive security report in markdown format with:
- Executive summary
- Detailed findings with code examples
- Risk assessment matrix
- Prioritized remediation roadmap" \
  > "$REPORT_FILE"

echo "Analysis complete. Report: $REPORT_FILE"
echo "Session ID: $SESSION (for future reference)"
```

### Contextual Multi-Turn Workflow

```bash
#!/bin/bash
# iterative-refactor.sh

FILE_TO_REFACTOR="$1"

# Turn 1: Analysis
echo "Analyzing $FILE_TO_REFACTOR..."
ANALYSIS=$(claude -p "Analyze $FILE_TO_REFACTOR and identify refactoring opportunities" \
  --output-format json)

SESSION=$(echo "$ANALYSIS" | jq -r '.metadata.sessionId')

# Turn 2: Plan refactoring
echo "Planning refactoring..."
claude -r "$SESSION" -p "Create a detailed refactoring plan with:
- Current issues
- Proposed changes
- Risk assessment
- Testing strategy"

# Turn 3: Execute changes (with user approval checkpoint)
read -p "Proceed with refactoring? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Executing refactoring..."
  claude -r "$SESSION" -p "Implement the refactoring plan" \
    --dangerously-skip-permissions
fi

# Turn 4: Verification
echo "Verifying changes..."
claude -r "$SESSION" -p "Review the refactored code and run tests to verify correctness"
```

---

## Streaming JSON Interactions

### Real-Time Progress Monitoring

```bash
# Stream output for long-running tasks
claude -p "Comprehensive codebase analysis" \
  --output-format stream-json | while read -r line; do

  # Parse each JSON message
  TYPE=$(echo "$line" | jq -r '.type')

  case "$TYPE" in
    "message")
      CONTENT=$(echo "$line" | jq -r '.content')
      echo "[MESSAGE] $CONTENT"
      ;;
    "tool_use")
      TOOL=$(echo "$line" | jq -r '.tool')
      echo "[TOOL] Using $TOOL..."
      ;;
    "tool_result")
      TOOL=$(echo "$line" | jq -r '.tool')
      echo "[RESULT] $TOOL completed"
      ;;
    "error")
      ERROR=$(echo "$line" | jq -r '.message')
      echo "[ERROR] $ERROR" >&2
      ;;
  esac
done
```

### Streaming Input Pattern (Advanced)

```bash
#!/bin/bash
# streaming-workflow.sh

# Create named pipe for bidirectional communication
PIPE=/tmp/claude-stream-$$
mkfifo "$PIPE"

# Start Claude with streaming
claude --output-format stream-json < "$PIPE" | \
while read -r response; do
  echo "[RESPONSE] $response"

  # Process response and generate next prompt
  TYPE=$(echo "$response" | jq -r '.type')

  if [[ "$TYPE" == "request_input" ]]; then
    # Send next instruction
    echo "Continue analysis" > "$PIPE"
  fi
done &

# Send initial prompt
echo "Start multi-stage analysis" > "$PIPE"

# Cleanup
sleep 60
rm "$PIPE"
```

### Progress Bar Implementation

```bash
#!/bin/bash
# progress-monitor.sh

TASK="$1"
TOTAL_STEPS=10
CURRENT_STEP=0

claude -p "$TASK" --output-format stream-json | while read -r line; do
  TYPE=$(echo "$line" | jq -r '.type')

  if [[ "$TYPE" == "tool_use" ]]; then
    ((CURRENT_STEP++))
    PERCENT=$((CURRENT_STEP * 100 / TOTAL_STEPS))

    # Draw progress bar
    printf "\rProgress: ["
    printf "%-${TOTAL_STEPS}s" "$(printf '#%.0s' $(seq 1 $CURRENT_STEP))"
    printf "] %d%%" "$PERCENT"
  fi

  if [[ "$TYPE" == "message" ]]; then
    echo ""  # New line after progress
    echo "$line" | jq -r '.content'
  fi
done
```

---

## Custom System Prompts

### Append Custom Instructions

```bash
# Add custom context to default system prompt
claude -p "Review authentication code" \
  --append-system-prompt "This project follows the OWASP ASVS v4.0 standard. Focus on ASVS requirements in your analysis."

# Multiple custom instructions
claude -p "Refactor API endpoints" \
  --append-system-prompt "Follow our coding standards:
1. Use TypeScript strict mode
2. All functions must have JSDoc comments
3. Maximum cyclomatic complexity: 10
4. Minimum test coverage: 80%"
```

### Replace Entire System Prompt

```bash
# Create custom system prompt file
cat > custom-prompt.txt <<'EOF'
You are a specialized security auditor for financial applications.

Your analysis must:
1. Focus on PCI DSS compliance
2. Identify all data flows involving payment information
3. Flag any unencrypted sensitive data transmission
4. Verify input validation on all user inputs
5. Check for proper authentication on all financial operations

Output format: Structured report with severity ratings and remediation steps.
EOF

# Use custom system prompt
claude -p "Audit payment processing module" \
  --system-prompt-file custom-prompt.txt
```

### Domain-Specific System Prompts

**Example: Medical Device Software Auditor**
```bash
cat > medical-auditor-prompt.txt <<'EOF'
You are a medical device software compliance auditor specializing in FDA 21 CFR Part 11 and IEC 62304 standards.

For each code review:
1. Verify electronic signature implementation
2. Check audit trail completeness
3. Validate data integrity controls
4. Assess software risk classification
5. Review validation documentation

Provide citations to specific regulatory requirements in your findings.
EOF

claude -p "Review patient data handling module" \
  --system-prompt-file medical-auditor-prompt.txt \
  --allowedTools "Read,Grep,Glob"
```

**Example: Infrastructure as Code Security**
```bash
INFRA_PROMPT="You are an IaC security expert specializing in Terraform and CloudFormation.
Focus on:
- Least privilege IAM policies
- Encryption at rest and in transit
- Public exposure risks
- Compliance with CIS benchmarks
- Cost optimization opportunities

Flag all findings with severity and AWS Well-Architected Framework pillar."

claude -p "Audit Terraform configurations in ./terraform/" \
  --append-system-prompt "$INFRA_PROMPT"
```

---

## Advanced Tool Configuration

### Precise Tool Allowlists

```bash
# Read-only analysis (safe for untrusted code)
claude -p "Analyze code structure" \
  --allowedTools "Read,Grep,Glob"

# Allow file operations but no command execution
claude -p "Refactor code" \
  --allowedTools "Read,Write,Edit,Grep,Glob"

# Enable bash for testing but nothing else
claude -p "Run test suite" \
  --allowedTools "Bash"
```

### Tool Denylists

```bash
# Allow everything except Write operations
claude -p "Explore codebase" \
  --disallowedTools "Write,Edit"

# Prevent network access via WebFetch
claude -p "Local analysis only" \
  --disallowedTools "WebFetch,WebSearch"

# Prevent agent spawning
claude -p "Simple task without agents" \
  --disallowedTools "Task"
```

### Complex Tool Configurations

```bash
#!/bin/bash
# role-based-tools.sh

ROLE="$1"
TASK="$2"

case "$ROLE" in
  analyst)
    TOOLS="Read,Grep,Glob,Bash"
    PROMPT="Analyze: $TASK (read-only)"
    ;;
  developer)
    TOOLS="Read,Write,Edit,Grep,Glob,Bash"
    PROMPT="Develop: $TASK"
    ;;
  reviewer)
    TOOLS="Read,Grep,Glob"
    PROMPT="Review: $TASK (no modifications)"
    ;;
  admin)
    TOOLS=""  # All tools allowed
    PROMPT="Execute: $TASK (full access)"
    ;;
  *)
    echo "Unknown role: $ROLE"
    exit 1
    ;;
esac

if [[ -n "$TOOLS" ]]; then
  claude -p "$PROMPT" --allowedTools "$TOOLS"
else
  claude -p "$PROMPT"
fi
```

**Usage:**
```bash
./role-based-tools.sh analyst "security assessment"
./role-based-tools.sh developer "implement feature X"
./role-based-tools.sh reviewer "code review PR #123"
```

### MCP Server Configuration

```bash
# Create MCP configuration
cat > mcp-config.json <<'EOF'
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/workspace"]
    }
  }
}
EOF

# Use MCP configuration
claude -p "Fetch GitHub issues and analyze" \
  --mcp-config mcp-config.json

# Strict MCP mode (only use specified servers)
claude -p "Task requiring GitHub access" \
  --mcp-config mcp-config.json \
  --strict-mcp-config
```

---

## Practical Examples

### Example 1: Incremental Code Migration

```bash
#!/bin/bash
# migrate-javascript-to-typescript.sh

# Stage 1: Inventory
echo "=== Stage 1: Creating inventory ==="
RESULT=$(claude -p "List all JavaScript files in src/ and categorize by complexity" \
  --output-format json)

SESSION=$(echo "$RESULT" | jq -r '.metadata.sessionId')
echo "Session: $SESSION"

# Stage 2: Migration plan
echo "=== Stage 2: Planning migration ==="
claude -r "$SESSION" -p "Create a migration plan with:
1. Recommended migration order (simple to complex)
2. Type definitions needed
3. Potential type conflicts
4. Estimated effort per file"

# Stage 3: Execute migration (file by file)
echo "=== Stage 3: Executing migration ==="

# Get file list
FILES=$(echo "$RESULT" | jq -r '.result' | grep -oP 'src/[^\s]+\.js')

for file in $FILES; do
  echo "Migrating $file..."

  claude -r "$SESSION" -p "Migrate $file to TypeScript:
1. Add type annotations
2. Convert to .ts extension
3. Fix any type errors
4. Run type checker" \
    --max-turns 15

  # Verify
  npx tsc --noEmit "${file%.js}.ts" && echo "✓ $file migrated successfully"

  # Wait between files to avoid rate limits
  sleep 2
done

echo "=== Migration complete ==="
```

### Example 2: Automated Incident Response

```bash
#!/bin/bash
# incident-response.sh

INCIDENT_TYPE="$1"  # e.g., "high-cpu", "memory-leak", "security-breach"
SEVERITY="$2"       # e.g., "critical", "high", "medium"

LOG_DIR="/var/log/incidents"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
INCIDENT_LOG="$LOG_DIR/incident-${INCIDENT_TYPE}-${TIMESTAMP}.log"

{
  echo "=== INCIDENT RESPONSE: $INCIDENT_TYPE ==="
  echo "Severity: $SEVERITY"
  echo "Time: $(date)"
  echo ""

  # Step 1: Initial assessment
  echo "Step 1: Initial Assessment"
  ASSESSMENT=$(claude -p "Assess $INCIDENT_TYPE incident:
1. Gather relevant system metrics
2. Check recent logs for errors
3. Identify affected components
4. Estimate user impact" \
    --output-format json \
    --max-turns 10)

  SESSION=$(echo "$ASSESSMENT" | jq -r '.metadata.sessionId')
  echo "$ASSESSMENT" | jq -r '.result'

  # Step 2: Root cause analysis
  echo ""
  echo "Step 2: Root Cause Analysis"
  claude -r "$SESSION" -p "Perform root cause analysis:
1. Analyze system logs in detail
2. Correlate events timeline
3. Identify probable cause
4. Suggest verification tests" \
    --max-turns 20

  # Step 3: Mitigation steps
  echo ""
  echo "Step 3: Mitigation Strategy"

  if [[ "$SEVERITY" == "critical" ]]; then
    claude -r "$SESSION" -p "Provide immediate mitigation steps:
1. Emergency actions to stabilize system
2. Rollback procedures if needed
3. Communication template for stakeholders
4. Monitoring checkpoints" \
      --max-turns 15
  else
    claude -r "$SESSION" -p "Provide mitigation plan:
1. Recommended fixes
2. Implementation steps
3. Testing approach
4. Deployment strategy"
  fi

  # Step 4: Post-incident recommendations
  echo ""
  echo "Step 4: Prevention Recommendations"
  claude -r "$SESSION" -p "Provide recommendations to prevent recurrence:
1. Code changes needed
2. Infrastructure improvements
3. Monitoring enhancements
4. Process improvements"

  echo ""
  echo "=== INCIDENT RESPONSE COMPLETE ==="
  echo "Session ID: $SESSION"

} | tee "$INCIDENT_LOG"

# Send alert
echo "Incident response completed. Log: $INCIDENT_LOG"

# For critical incidents, page on-call
if [[ "$SEVERITY" == "critical" ]]; then
  cat "$INCIDENT_LOG" | mail -s "CRITICAL: Incident Response $INCIDENT_TYPE" oncall@company.com
fi
```

**Usage:**
```bash
./incident-response.sh "memory-leak" "high"
./incident-response.sh "security-breach" "critical"
```

### Example 3: Continuous Documentation Updates

```bash
#!/bin/bash
# update-documentation.sh

DOCS_DIR="docs"
SESSION_FILE=".docs-session"

# Start or resume documentation session
if [[ -f "$SESSION_FILE" ]]; then
  SESSION=$(cat "$SESSION_FILE")
  echo "Resuming documentation session: $SESSION"
  RESUME_FLAG="-r $SESSION"
else
  echo "Starting new documentation session"
  RESUME_FLAG=""
fi

# Run documentation update
RESULT=$(claude $RESUME_FLAG -p "Update project documentation:
1. Review recent code changes (last 7 days)
2. Identify undocumented features
3. Update API documentation
4. Refresh examples
5. Update changelog" \
  --output-format json \
  --max-turns 30 \
  --allowedTools "Read,Write,Edit,Grep,Glob,Bash")

# Save session for next run
NEW_SESSION=$(echo "$RESULT" | jq -r '.metadata.sessionId')
echo "$NEW_SESSION" > "$SESSION_FILE"

echo "Documentation updated. Session: $NEW_SESSION"

# Commit changes
if git diff --quiet "$DOCS_DIR"; then
  echo "No documentation changes needed"
else
  git add "$DOCS_DIR"
  git commit -m "docs: automated documentation update

$(echo "$RESULT" | jq -r '.result' | head -20)"
  echo "Documentation committed"
fi
```

---

## Best Practices

### 1. Session Management

```bash
# Always capture session IDs for multi-stage work
save_session() {
  local result="$1"
  local session_file="$2"
  echo "$result" | jq -r '.metadata.sessionId' > "$session_file"
}

# Use descriptive session IDs
claude -p "Task" --session-id "feature-auth-$(date +%Y%m%d)"
```

### 2. Error Handling in Multi-Turn

```bash
#!/bin/bash
set -euo pipefail

SESSION_FILE=".session"

cleanup() {
  if [[ -f "$SESSION_FILE" ]]; then
    echo "Session saved: $(cat $SESSION_FILE)"
  fi
}
trap cleanup EXIT

# Your multi-turn workflow
# If it fails, session ID is preserved for debugging
```

### 3. Cost Management

```bash
# Monitor costs across sessions
track_costs() {
  local result="$1"
  local cost=$(echo "$result" | jq -r '.metadata.totalCost')
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ),$cost" >> costs.csv
}

RESULT=$(claude -p "Task" --output-format json)
track_costs "$RESULT"
```

### 4. Rate Limiting

```bash
# Implement backoff for multiple requests
execute_with_backoff() {
  local max_retries=3
  local delay=5

  for i in $(seq 1 $max_retries); do
    if claude -p "$1"; then
      return 0
    fi

    echo "Retry $i/$max_retries in ${delay}s..."
    sleep $delay
    delay=$((delay * 2))
  done

  return 1
}
```

---

## Next Steps

- **Advanced Examples** → [../03-advanced/](../03-advanced/) for complex orchestration
- **Agent Examples** → [../04-agents/](../04-agents/) for sub-agent patterns
- **Skills** → [../05-skills/](../05-skills/) for skill development
