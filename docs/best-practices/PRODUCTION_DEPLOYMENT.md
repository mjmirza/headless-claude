# Production Deployment Best Practices

Enterprise-grade patterns for deploying Claude Code in production environments.

## Table of Contents

1. [Security](#security)
2. [Reliability](#reliability)
3. [Performance](#performance)
4. [Cost Optimization](#cost-optimization)
5. [Monitoring](#monitoring)
6. [Error Handling](#error-handling)

---

## Security

### 1. User Isolation

**Always use a dedicated user for Claude execution:**

```bash
# Create dedicated user (one-time setup)
sudo useradd -m -s /bin/bash claudeuser
sudo usermod -L claudeuser  # Lock password (no login)

# Grant minimal necessary permissions
sudo usermod -aG docker claudeuser  # If Docker access needed

# Execute as dedicated user
su - claudeuser -c 'claude --dangerously-skip-permissions -p "task"'
```

**Why:**
- Limits blast radius of any issues
- Prevents accidental system file modifications
- Easier resource monitoring and limits
- Clean separation of concerns

### 2. File System Permissions

```bash
# Restrict Claude user to specific directories
sudo mkdir -p /opt/claude-workspace
sudo chown claudeuser:claudeuser /opt/claude-workspace
sudo chmod 750 /opt/claude-workspace

# Execute with restricted access
su - claudeuser -c 'cd /opt/claude-workspace && claude -p "task"'
```

### 3. API Key Management

**Never hardcode API keys:**

```bash
# ❌ Bad
export ANTHROPIC_API_KEY="sk-ant-..."
claude -p "task"

# ✓ Good - AWS Secrets Manager
export ANTHROPIC_API_KEY=$(aws secretsmanager get-secret-value \
  --secret-id anthropic-api-key \
  --query SecretString \
  --output text | jq -r '.key')

claude -p "task"

# ✓ Good - HashiCorp Vault
export ANTHROPIC_API_KEY=$(vault kv get -field=key secret/anthropic)

# ✓ Good - Kubernetes Secret
# In pod spec:
env:
  - name: ANTHROPIC_API_KEY
    valueFrom:
      secretKeyRef:
        name: anthropic-secret
        key: api-key
```

### 4. Tool Restriction

**Always use minimum necessary tools:**

```bash
# For read-only analysis
claude -p "Analyze code" --allowedTools "Read,Grep,Glob"

# For specific tasks
claude -p "Run tests" --allowedTools "Bash"

# Never use --dangerously-skip-permissions in production without careful consideration
# Only use in fully isolated, controlled environments
```

### 5. Network Isolation

```bash
# Use network namespaces for isolation
sudo ip netns add claude-isolated
sudo ip netns exec claude-isolated su - claudeuser -c 'claude -p "task"'

# Or use containers
docker run --rm \
  --network none \  # No network access
  -v $(pwd):/workspace:ro \  # Read-only mount
  claude-image claude -p "task"
```

### 6. Audit Logging

```bash
# Log all executions
exec > >(tee -a /var/log/claude/audit.log)
exec 2>&1

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) | User: $(whoami) | Task: $TASK"
claude -p "$TASK"
```

---

## Reliability

### 1. Timeout Protection

```bash
# Always set timeouts
timeout 300 claude -p "task"

# With custom cleanup
timeout --signal=TERM --kill-after=10 300 \
  claude -p "task" || {
    echo "Task timed out, cleaning up..."
    cleanup_function
  }
```

### 2. Retry Logic

```bash
# Exponential backoff retry
retry_with_backoff() {
  local max_attempts=5
  local timeout=1
  local attempt=1

  while [ $attempt -le $max_attempts ]; do
    if claude -p "$1"; then
      return 0
    fi

    echo "Attempt $attempt failed, retrying in ${timeout}s..."
    sleep $timeout
    timeout=$((timeout * 2))
    attempt=$((attempt + 1))
  done

  echo "Failed after $max_attempts attempts"
  return 1
}

# Usage
retry_with_backoff "Analyze codebase"
```

### 3. Health Checks

```bash
# Pre-execution health check
health_check() {
  # Check API connectivity
  if ! claude -p "echo test" --max-turns 1 >/dev/null 2>&1; then
    echo "Claude API unhealthy"
    return 1
  fi

  # Check disk space
  local available=$(df /opt/claude-workspace | awk 'NR==2 {print $4}')
  if [ "$available" -lt 1048576 ]; then  # Less than 1GB
    echo "Insufficient disk space"
    return 1
  fi

  # Check memory
  local mem_available=$(free -m | awk 'NR==2 {print $7}')
  if [ "$mem_available" -lt 512 ]; then  # Less than 512MB
    echo "Insufficient memory"
    return 1
  fi

  return 0
}

# Use before execution
if health_check; then
  claude -p "production task"
else
  echo "Health check failed, aborting"
  exit 1
fi
```

### 4. Circuit Breaker Pattern

```bash
# Prevent cascading failures
FAILURE_THRESHOLD=3
FAILURE_COUNT=0
CIRCUIT_OPEN=false

execute_with_circuit_breaker() {
  if [ "$CIRCUIT_OPEN" = true ]; then
    echo "Circuit breaker open, rejecting request"
    return 1
  fi

  if claude -p "$1"; then
    FAILURE_COUNT=0
    return 0
  else
    FAILURE_COUNT=$((FAILURE_COUNT + 1))

    if [ $FAILURE_COUNT -ge $FAILURE_THRESHOLD ]; then
      CIRCUIT_OPEN=true
      echo "Circuit breaker opened after $FAILURE_COUNT failures"

      # Schedule reset (in real impl, use proper scheduling)
      (sleep 60 && CIRCUIT_OPEN=false && FAILURE_COUNT=0) &
    fi

    return 1
  fi
}
```

### 5. Graceful Degradation

```bash
# Primary execution with fallback
claude -p "Complex analysis" --max-turns 30 || {
  echo "Primary execution failed, trying simpler approach..."
  claude -p "Simple analysis" --max-turns 10 --model haiku
}
```

---

## Performance

### 1. Model Selection

```bash
# Use appropriate model for task complexity
fast_task() {
  claude -p "$1" --model haiku  # Fast, cheap
}

standard_task() {
  claude -p "$1" --model sonnet  # Balanced
}

complex_task() {
  claude -p "$1" --model opus  # Most capable
}

# Example
fast_task "Find configuration files"
standard_task "Analyze authentication flow"
complex_task "Design new microservice architecture"
```

### 2. Turn Limits

```bash
# Set appropriate turn limits
claude -p "Quick scan" --max-turns 5       # Simple tasks
claude -p "Standard analysis" --max-turns 20   # Typical tasks
claude -p "Deep audit" --max-turns 50      # Complex tasks
```

### 3. Parallel Execution

```bash
# Run independent tasks in parallel
TASKS=(
  "Analyze security"
  "Check performance"
  "Review tests"
  "Audit dependencies"
)

for task in "${TASKS[@]}"; do
  {
    claude -p "$task" --output-format json > "${task// /-}.json"
  } &
done

wait
echo "All analyses complete"
```

### 4. Caching

```bash
# Cache expensive operations
CACHE_DIR="/var/cache/claude"
mkdir -p "$CACHE_DIR"

execute_with_cache() {
  local task="$1"
  local cache_key=$(echo -n "$task" | md5sum | awk '{print $1}')
  local cache_file="$CACHE_DIR/$cache_key"

  # Check cache (24 hour TTL)
  if [ -f "$cache_file" ] && [ $(($(date +%s) - $(stat -c %Y "$cache_file"))) -lt 86400 ]; then
    echo "Cache hit for: $task"
    cat "$cache_file"
    return 0
  fi

  # Execute and cache
  claude -p "$task" | tee "$cache_file"
}
```

### 5. Resource Limits

```bash
# CPU and memory limits via systemd-run
systemd-run --scope \
  -p MemoryLimit=2G \
  -p CPUQuota=50% \
  su - claudeuser -c 'claude -p "task"'

# Or use ulimit
ulimit -v 2097152  # 2GB virtual memory
ulimit -t 300      # 5 minutes CPU time
claude -p "task"
```

---

## Cost Optimization

### 1. Cost Tracking

```bash
# Track costs per execution
COST_LOG="/var/log/claude/costs.csv"

execute_and_track() {
  local task="$1"
  local start_time=$(date +%s)

  local result=$(claude -p "$task" --output-format json)
  local cost=$(echo "$result" | jq -r '.metadata.totalCost')
  local duration=$(echo "$result" | jq -r '.metadata.duration')

  # Log cost data
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ),$task,$cost,$duration" >> "$COST_LOG"

  echo "$result" | jq -r '.result'
}

# Generate cost report
generate_cost_report() {
  echo "=== Cost Report ==="
  echo "Total cost: $(awk -F, '{sum+=$3} END {print sum}' "$COST_LOG")"
  echo "Total executions: $(wc -l < "$COST_LOG")"
  echo "Average cost: $(awk -F, '{sum+=$3; count++} END {print sum/count}' "$COST_LOG")"
}
```

### 2. Budget Limits

```bash
# Enforce budget limits
DAILY_BUDGET=10.00  # $10/day
COST_FILE="/var/log/claude/daily-cost.txt"

check_budget() {
  local today=$(date +%Y-%m-%d)
  local cost_today=0

  if [ -f "$COST_FILE" ]; then
    local file_date=$(head -1 "$COST_FILE")
    if [ "$file_date" = "$today" ]; then
      cost_today=$(tail -1 "$COST_FILE")
    else
      echo "$today" > "$COST_FILE"
      echo "0" >> "$COST_FILE"
    fi
  else
    echo "$today" > "$COST_FILE"
    echo "0" >> "$COST_FILE"
  fi

  if (( $(echo "$cost_today >= $DAILY_BUDGET" | bc -l) )); then
    echo "Daily budget exceeded: \$$cost_today / \$$DAILY_BUDGET"
    return 1
  fi

  return 0
}

# Usage
if check_budget; then
  claude -p "task"
else
  echo "Budget limit reached, deferring task"
fi
```

### 3. Efficient Batching

```bash
# Batch related tasks together
# ❌ Bad - multiple separate executions
claude -p "Analyze file1.js"
claude -p "Analyze file2.js"
claude -p "Analyze file3.js"

# ✓ Good - batch in one execution
claude -p "Analyze these files: file1.js, file2.js, file3.js"

# ✓ Better - use session for related work
SESSION=$(claude -p "Start code review" --output-format json | jq -r '.metadata.sessionId')
claude -r "$SESSION" -p "Review security"
claude -r "$SESSION" -p "Review performance"
claude -r "$SESSION" -p "Generate report"
```

### 4. Model Downgrading

```bash
# Try cheaper model first, upgrade if needed
claude -p "$TASK" --model haiku || \
  claude -p "$TASK" --model sonnet || \
  claude -p "$TASK" --model opus
```

---

## Monitoring

### 1. Metrics Collection

```bash
# Collect execution metrics
METRICS_FILE="/var/log/claude/metrics.jsonl"

collect_metrics() {
  local task="$1"
  local start=$(date +%s.%N)

  local result=$(claude -p "$task" --output-format json 2>&1)
  local exit_code=$?

  local end=$(date +%s.%N)
  local duration=$(echo "$end - $start" | bc)

  # Extract metadata
  local cost=$(echo "$result" | jq -r '.metadata.totalCost // 0')
  local turns=$(echo "$result" | jq -r '.metadata.turns // 0')

  # Write metrics
  jq -n \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg task "$task" \
    --argjson duration "$duration" \
    --argjson cost "$cost" \
    --argjson turns "$turns" \
    --argjson exit_code "$exit_code" \
    '{timestamp: $timestamp, task: $task, duration: $duration, cost: $cost, turns: $turns, exit_code: $exit_code}' \
    >> "$METRICS_FILE"
}

# Usage
collect_metrics "Production analysis task"
```

### 2. Alerting

```bash
# Alert on failures
ALERT_THRESHOLD=3
FAILURE_COUNT=0

execute_with_alerting() {
  if ! claude -p "$1"; then
    FAILURE_COUNT=$((FAILURE_COUNT + 1))

    if [ $FAILURE_COUNT -ge $ALERT_THRESHOLD ]; then
      send_alert "Claude execution failed $FAILURE_COUNT times"
    fi

    return 1
  fi

  FAILURE_COUNT=0
  return 0
}

send_alert() {
  local message="$1"

  # Slack
  curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK \
    -H 'Content-Type: application/json' \
    -d "{\"text\": \"$message\"}"

  # Email
  echo "$message" | mail -s "Claude Alert" ops@company.com

  # PagerDuty
  curl -X POST https://api.pagerduty.com/incidents \
    -H 'Authorization: Token token=YOUR_TOKEN' \
    -H 'Content-Type: application/json' \
    -d "{\"incident\": {\"type\": \"incident\", \"title\": \"$message\"}}"
}
```

### 3. Performance Monitoring

```bash
# Monitor execution time
SLOW_THRESHOLD=30  # seconds

execute_with_monitoring() {
  local start=$(date +%s)

  claude -p "$1"
  local exit_code=$?

  local duration=$(($(date +%s) - start))

  if [ $duration -gt $SLOW_THRESHOLD ]; then
    echo "WARN: Execution took ${duration}s (threshold: ${SLOW_THRESHOLD}s)"
    # Log slow query
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) | SLOW | ${duration}s | $1" >> /var/log/claude/slow-queries.log
  fi

  return $exit_code
}
```

---

## Error Handling

### 1. Comprehensive Error Handling

```bash
#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Trap errors
trap 'error_handler $? $LINENO' ERR

error_handler() {
  local exit_code=$1
  local line_number=$2

  echo "Error on line $line_number: exit code $exit_code"
  echo "Task: $CURRENT_TASK"
  echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # Log error
  logger -t claude-error "Exit code $exit_code on line $line_number"

  # Cleanup
  cleanup

  exit $exit_code
}

cleanup() {
  # Remove temp files
  rm -f /tmp/claude-*

  # Kill any background processes
  jobs -p | xargs -r kill
}

# Your code
CURRENT_TASK="Production analysis"
claude -p "$CURRENT_TASK"
```

### 2. Specific Error Cases

```bash
execute_with_error_handling() {
  local task="$1"
  local output

  if ! output=$(claude -p "$task" 2>&1); then
    local exit_code=$?

    case $exit_code in
      1)
        echo "General error, retrying..."
        sleep 5
        claude -p "$task"
        ;;
      124)
        echo "Timeout, using simpler approach..."
        claude -p "Simplified: $task" --max-turns 10
        ;;
      130)
        echo "Interrupted, cleaning up..."
        cleanup
        exit 130
        ;;
      *)
        echo "Unknown error (code: $exit_code)"
        send_alert "Claude failed with code $exit_code"
        return $exit_code
        ;;
    esac
  fi

  echo "$output"
}
```

### 3. Validation

```bash
# Validate output
validate_output() {
  local output="$1"
  local format="$2"

  case "$format" in
    json)
      if ! echo "$output" | jq empty 2>/dev/null; then
        echo "Invalid JSON output"
        return 1
      fi
      ;;
    markdown)
      if ! echo "$output" | grep -q '^#'; then
        echo "Invalid markdown output"
        return 1
      fi
      ;;
  esac

  return 0
}

# Usage
OUTPUT=$(claude -p "Generate report" --output-format json)
if validate_output "$OUTPUT" "json"; then
  process_output "$OUTPUT"
else
  echo "Output validation failed"
  exit 1
fi
```

---

## Complete Production Example

```bash
#!/bin/bash
# production-claude-executor.sh
# Enterprise-grade Claude Code execution wrapper

set -euo pipefail

# Configuration
readonly CLAUDE_USER="claudeuser"
readonly WORKSPACE="/opt/claude-workspace"
readonly LOG_DIR="/var/log/claude"
readonly METRICS_FILE="$LOG_DIR/metrics.jsonl"
readonly COST_FILE="$LOG_DIR/daily-cost.txt"
readonly DAILY_BUDGET=10.00
readonly TIMEOUT=300
readonly MAX_RETRIES=3

# Ensure directories exist
mkdir -p "$LOG_DIR" "$WORKSPACE"

# Logging
log() {
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) | $*" | tee -a "$LOG_DIR/execution.log"
}

# Error handling
trap 'log "ERROR on line $LINENO"' ERR

# Health check
health_check() {
  log "Performing health check..."

  # API connectivity
  if ! timeout 10 claude -p "test" --max-turns 1 >/dev/null 2>&1; then
    log "ERROR: Claude API unhealthy"
    return 1
  fi

  # Disk space (min 1GB)
  local available=$(df "$WORKSPACE" | awk 'NR==2 {print $4}')
  if [ "$available" -lt 1048576 ]; then
    log "ERROR: Insufficient disk space"
    return 1
  fi

  log "Health check passed"
  return 0
}

# Budget check
check_budget() {
  local today=$(date +%Y-%m-%d)
  local cost_today=0

  if [ -f "$COST_FILE" ]; then
    local file_date=$(head -1 "$COST_FILE")
    if [ "$file_date" = "$today" ]; then
      cost_today=$(tail -1 "$COST_FILE")
    else
      echo "$today" > "$COST_FILE"
      echo "0" >> "$COST_FILE"
    fi
  else
    echo "$today" > "$COST_FILE"
    echo "0" >> "$COST_FILE"
  fi

  if (( $(echo "$cost_today >= $DAILY_BUDGET" | bc -l) )); then
    log "ERROR: Daily budget exceeded: \$$cost_today / \$$DAILY_BUDGET"
    return 1
  fi

  log "Budget check passed: \$$cost_today / \$$DAILY_BUDGET"
  return 0
}

# Execute with retry
execute_with_retry() {
  local task="$1"
  local attempt=1
  local backoff=2

  while [ $attempt -le $MAX_RETRIES ]; do
    log "Attempt $attempt/$MAX_RETRIES: $task"

    if timeout "$TIMEOUT" su - "$CLAUDE_USER" -c "cd $WORKSPACE && claude -p '$task' --output-format json"; then
      log "Success on attempt $attempt"
      return 0
    fi

    if [ $attempt -lt $MAX_RETRIES ]; then
      log "Failed, retrying in ${backoff}s..."
      sleep $backoff
      backoff=$((backoff * 2))
    fi

    attempt=$((attempt + 1))
  done

  log "ERROR: Failed after $MAX_RETRIES attempts"
  return 1
}

# Main execution
main() {
  local task="$1"

  log "Starting execution: $task"

  # Pre-flight checks
  if ! health_check; then
    log "ERROR: Health check failed"
    exit 1
  fi

  if ! check_budget; then
    log "ERROR: Budget check failed"
    exit 1
  fi

  # Execute
  local start=$(date +%s)
  local result
  local exit_code=0

  result=$(execute_with_retry "$task") || exit_code=$?

  local duration=$(($(date +%s) - start))

  # Extract metadata
  local cost=$(echo "$result" | jq -r '.metadata.totalCost // 0')
  local turns=$(echo "$result" | jq -r '.metadata.turns // 0')

  # Update budget
  local today=$(date +%Y-%m-%d)
  local current_cost=$(tail -1 "$COST_FILE")
  local new_cost=$(echo "$current_cost + $cost" | bc)
  echo "$today" > "$COST_FILE"
  echo "$new_cost" >> "$COST_FILE"

  # Log metrics
  jq -n \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg task "$task" \
    --argjson duration "$duration" \
    --argjson cost "$cost" \
    --argjson turns "$turns" \
    --argjson exit_code "$exit_code" \
    '{timestamp: $timestamp, task: $task, duration: $duration, cost: $cost, turns: $turns, exit_code: $exit_code}' \
    >> "$METRICS_FILE"

  log "Execution complete: duration=${duration}s, cost=\$${cost}, turns=$turns"

  # Output result
  echo "$result" | jq -r '.result'

  return $exit_code
}

# Run
main "$@"
```

**Usage:**
```bash
./production-claude-executor.sh "Analyze production application for security issues"
```

---

## Checklist for Production Deployment

- [ ] Dedicated user created with minimal permissions
- [ ] API keys stored in secrets manager (not hardcoded)
- [ ] Tool access restricted to minimum necessary
- [ ] Timeouts configured for all executions
- [ ] Retry logic implemented with exponential backoff
- [ ] Health checks in place
- [ ] Error handling and logging comprehensive
- [ ] Cost tracking and budget limits enforced
- [ ] Monitoring and alerting configured
- [ ] Resource limits set (CPU, memory, disk)
- [ ] Network isolation if applicable
- [ ] Audit logging enabled
- [ ] Graceful degradation strategies defined
- [ ] Documentation complete for on-call
- [ ] Disaster recovery procedures documented

---

## Summary

Production deployment requires attention to:

1. **Security**: Isolation, least privilege, secret management
2. **Reliability**: Timeouts, retries, health checks, circuit breakers
3. **Performance**: Model selection, parallelization, caching
4. **Cost**: Tracking, budgets, optimization
5. **Monitoring**: Metrics, alerts, logging
6. **Error Handling**: Comprehensive handling, validation, recovery

Follow these patterns to ensure robust, secure, and cost-effective Claude Code deployments in production environments.
