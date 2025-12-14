# Remote Execution Patterns

Advanced patterns for executing Claude Code on remote servers, distributed systems, and cloud infrastructure.

## Table of Contents

1. [SSH-Based Remote Execution](#ssh-based-remote-execution)
2. [Distributed Multi-Host Patterns](#distributed-multi-host-patterns)
3. [Cloud Integration](#cloud-integration)
4. [Container-Based Execution](#container-based-execution)
5. [CI/CD Integration](#cicd-integration)

---

## SSH-Based Remote Execution

### Basic Remote Execution

```bash
# Execute Claude on remote host
ssh user@remote-server "claude -p 'Analyze /opt/app/logs for errors'"

# With dedicated Claude user
ssh user@remote-server "su - claudeuser -c 'claude -p \"Audit security configurations\"'"

# Using key-based authentication
ssh -i ~/.ssh/deploy_key user@remote-server \
  "claude --dangerously-skip-permissions -p 'Deploy latest version'"
```

### Remote Execution with Output Capture

```bash
# Capture and process remote output
REMOTE_ANALYSIS=$(ssh user@server "claude -p 'Analyze system metrics' --output-format json")

echo "$REMOTE_ANALYSIS" | jq -r '.result'
```

### Advanced Remote Patterns

#### Pattern 1: Remote with Local Context

```bash
#!/bin/bash
# Execute Claude remotely with local file context

LOCAL_FILE="config.yaml"
REMOTE_SERVER="app-server-01"

# Send file to remote and analyze
cat "$LOCAL_FILE" | ssh user@"$REMOTE_SERVER" \
  "cat > /tmp/config.yaml && claude -p 'Validate this configuration file at /tmp/config.yaml' --output-format json"
```

#### Pattern 2: Multi-Stage Remote Execution

```bash
#!/bin/bash
# Complex remote workflow

REMOTE_HOST="prod-server"
SSH_USER="deployer"

{
  echo "=== Stage 1: Pre-deployment Check ==="
  ssh $SSH_USER@$REMOTE_HOST "claude -p 'Check system health and disk space before deployment' --output-format json"

  echo "=== Stage 2: Backup Current Version ==="
  ssh $SSH_USER@$REMOTE_HOST "claude -p 'Create backup of /opt/app to /backup/' --dangerously-skip-permissions"

  echo "=== Stage 3: Deploy ==="
  ssh $SSH_USER@$REMOTE_HOST "claude -p 'Deploy application from /staging to /opt/app' --max-turns 20"

  echo "=== Stage 4: Verification ==="
  ssh $SSH_USER@$REMOTE_HOST "claude -p 'Verify deployment by checking application health' --output-format json"

} | tee "deployment-$(date +%Y%m%d-%H%M%S).log"
```

#### Pattern 3: Remote Session Management

```bash
#!/bin/bash
# Manage remote Claude sessions

REMOTE_HOST="$1"
COMMAND="$2"
SESSION_FILE=".remote-session-${REMOTE_HOST}"

# Start or resume session
if ssh $USER@$REMOTE_HOST "test -f ~/.claude-session"; then
  # Resume existing session
  SESSION_ID=$(ssh $USER@$REMOTE_HOST "cat ~/.claude-session")

  ssh $USER@$REMOTE_HOST \
    "claude -r '$SESSION_ID' -p '$COMMAND' --output-format json" | \
    tee -a "remote-${REMOTE_HOST}.log"
else
  # Start new session
  RESULT=$(ssh $USER@$REMOTE_HOST \
    "claude -p '$COMMAND' --output-format json")

  # Save session ID
  SESSION_ID=$(echo "$RESULT" | jq -r '.metadata.sessionId')
  ssh $USER@$REMOTE_HOST "echo '$SESSION_ID' > ~/.claude-session"

  echo "$RESULT" | tee "remote-${REMOTE_HOST}.log"
fi
```

---

## Distributed Multi-Host Patterns

### Parallel Execution Across Multiple Hosts

```bash
#!/bin/bash
# Execute Claude on multiple servers in parallel

# Server inventory
SERVERS=(
  "web-01.example.com"
  "web-02.example.com"
  "web-03.example.com"
  "api-01.example.com"
  "api-02.example.com"
)

TASK="Analyze system logs for anomalies in the past hour"

# Execute in parallel
for server in "${SERVERS[@]}"; do
  {
    echo "=== $server ==="
    ssh user@$server "claude -p '$TASK' --output-format json" | \
      jq --arg host "$server" '{host: $host, result: .result}'
  } &
done

# Wait for all to complete
wait

echo "All servers analyzed"
```

### Load-Balanced Distribution

```bash
#!/bin/bash
# Distribute tasks across servers based on load

get_server_load() {
  local server="$1"
  ssh user@$server "uptime | awk '{print \$(NF-2)}' | tr -d ','"
}

SERVERS=("server1" "server2" "server3")
TASK="$1"

# Find least loaded server
min_load=999
selected_server=""

for server in "${SERVERS[@]}"; do
  load=$(get_server_load "$server")

  if (( $(echo "$load < $min_load" | bc -l) )); then
    min_load=$load
    selected_server=$server
  fi
done

echo "Executing on $selected_server (load: $min_load)"
ssh user@$selected_server "claude -p '$TASK'"
```

### Map-Reduce Pattern

```bash
#!/bin/bash
# Distribute analysis across servers, then combine results

LOG_SERVERS=(
  "log-collector-01"
  "log-collector-02"
  "log-collector-03"
)

ANALYSIS_PROMPT="Analyze logs in /var/log/app for security events"

# Map: Execute on each server
echo "=== Map Phase ==="
for server in "${LOG_SERVERS[@]}"; do
  {
    ssh user@$server "claude -p '$ANALYSIS_PROMPT' --output-format json" > \
      "analysis-${server}.json"
  } &
done
wait

# Reduce: Combine results
echo "=== Reduce Phase ==="
cat analysis-*.json | jq -s '
  {
    total_servers: length,
    combined_findings: map(.result) | add,
    metadata: {
      total_cost: map(.metadata.totalCost) | add,
      total_duration: map(.metadata.duration) | add
    }
  }
' > combined-analysis.json

# Final analysis
claude -p "Analyze these combined security findings and provide executive summary: $(cat combined-analysis.json)" \
  --output-format text > final-report.md

echo "Analysis complete: final-report.md"

# Cleanup
rm analysis-*.json
```

---

## Cloud Integration

### AWS EC2 Fleet Execution

```bash
#!/bin/bash
# Execute Claude across AWS EC2 instances

# Get all running instances with specific tag
INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag:Role,Values=app-server" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].InstanceId' \
  --output text)

TASK="Perform security audit of application configuration"

for instance_id in $INSTANCE_IDS; do
  {
    # Get instance IP
    INSTANCE_IP=$(aws ec2 describe-instances \
      --instance-ids $instance_id \
      --query 'Reservations[0].Instances[0].PublicIpAddress' \
      --output text)

    echo "=== Instance: $instance_id ($INSTANCE_IP) ==="

    # Execute via SSM (no SSH required)
    aws ssm send-command \
      --instance-ids "$instance_id" \
      --document-name "AWS-RunShellScript" \
      --parameters commands="[\"su - claudeuser -c 'claude -p \\\"$TASK\\\" --output-format json'\"]" \
      --output text \
      --query 'Command.CommandId' > "command-${instance_id}.txt"

  } &
done

wait

echo "Commands sent to all instances"

# Retrieve results
for instance_id in $INSTANCE_IDS; do
  COMMAND_ID=$(cat "command-${instance_id}.txt")

  # Wait for command completion and get output
  aws ssm wait command-executed \
    --command-id "$COMMAND_ID" \
    --instance-id "$instance_id"

  aws ssm get-command-invocation \
    --command-id "$COMMAND_ID" \
    --instance-id "$instance_id" \
    --query 'StandardOutputContent' \
    --output text > "result-${instance_id}.json"

  echo "Results from $instance_id:"
  cat "result-${instance_id}.json" | jq -r '.result'
done

# Cleanup
rm command-*.txt result-*.json
```

### Google Cloud Platform (GCP) Execution

```bash
#!/bin/bash
# Execute Claude across GCP Compute Engine instances

PROJECT_ID="my-project"
ZONE="us-central1-a"

# Get all instances with label
INSTANCES=$(gcloud compute instances list \
  --project=$PROJECT_ID \
  --filter="labels.type=app-server" \
  --format="value(name)")

TASK="Analyze application performance metrics"

for instance in $INSTANCES; do
  {
    echo "=== Instance: $instance ==="

    # Execute via gcloud ssh
    gcloud compute ssh $instance \
      --project=$PROJECT_ID \
      --zone=$ZONE \
      --command="su - claudeuser -c 'claude -p \"$TASK\" --output-format json'" \
      > "result-${instance}.json"

    cat "result-${instance}.json" | jq -r '.result'

  } &
done

wait

echo "All instances processed"
```

### Azure VM Execution

```bash
#!/bin/bash
# Execute Claude across Azure VMs

RESOURCE_GROUP="my-resource-group"

# Get all VMs with tag
VM_NAMES=$(az vm list \
  --resource-group $RESOURCE_GROUP \
  --query "[?tags.role=='app-server'].name" \
  --output tsv)

TASK="Check compliance with security baseline"

for vm_name in $VM_NAMES; do
  {
    echo "=== VM: $vm_name ==="

    # Execute command using Azure Run Command
    az vm run-command invoke \
      --resource-group $RESOURCE_GROUP \
      --name $vm_name \
      --command-id RunShellScript \
      --scripts "su - claudeuser -c 'claude -p \"$TASK\" --output-format json'" \
      --query 'value[0].message' \
      --output tsv > "result-${vm_name}.json"

    cat "result-${vm_name}.json" | jq -r '.result'

  } &
done

wait
```

---

## Container-Based Execution

### Docker Container Execution

```bash
# Create Claude Docker image
cat > Dockerfile <<'EOF'
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code (adjust based on actual installation method)
RUN curl -fsSL https://releases.claude.com/claude-code/install.sh | bash

# Create claudeuser
RUN useradd -m -s /bin/bash claudeuser

# Set working directory
WORKDIR /workspace

# Default command
CMD ["claude"]
EOF

# Build image
docker build -t claude-headless:latest .

# Run Claude in container
docker run --rm \
  -v $(pwd):/workspace \
  claude-headless:latest \
  claude -p "Analyze this codebase structure" --output-format json
```

### Docker Compose for Multi-Container Analysis

```yaml
# docker-compose.yml
version: '3.8'

services:
  claude-security:
    image: claude-headless:latest
    volumes:
      - ./:/workspace
    command: >
      claude -p "Perform security audit"
      --allowedTools "Read,Grep,Glob"
      --output-format json
    user: claudeuser

  claude-performance:
    image: claude-headless:latest
    volumes:
      - ./:/workspace
    command: >
      claude -p "Analyze performance bottlenecks"
      --output-format json
    user: claudeuser

  claude-tests:
    image: claude-headless:latest
    volumes:
      - ./:/workspace
    command: >
      claude -p "Review test coverage and generate missing tests"
      --output-format json
    user: claudeuser
```

```bash
# Run all analyses in parallel
docker-compose up

# Get results
docker-compose logs claude-security | jq -r '.result'
docker-compose logs claude-performance | jq -r '.result'
docker-compose logs claude-tests | jq -r '.result'
```

### Kubernetes Job Execution

```yaml
# claude-analysis-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: claude-code-analysis
spec:
  parallelism: 3
  completions: 3
  template:
    spec:
      containers:
      - name: claude
        image: claude-headless:latest
        command:
        - /bin/bash
        - -c
        - |
          case $TASK_ID in
            0)
              claude -p "Security audit" --output-format json > /results/security.json
              ;;
            1)
              claude -p "Performance analysis" --output-format json > /results/performance.json
              ;;
            2)
              claude -p "Code quality review" --output-format json > /results/quality.json
              ;;
          esac
        env:
        - name: TASK_ID
          valueFrom:
            fieldRef:
              fieldPath: metadata.annotations['batch.kubernetes.io/job-completion-index']
        volumeMounts:
        - name: workspace
          mountPath: /workspace
        - name: results
          mountPath: /results
      volumes:
      - name: workspace
        persistentVolumeClaim:
          claimName: code-workspace
      - name: results
        persistentVolumeClaim:
          claimName: analysis-results
      restartPolicy: Never
```

```bash
# Deploy job
kubectl apply -f claude-analysis-job.yaml

# Monitor progress
kubectl get jobs claude-code-analysis -w

# Get results
kubectl exec -it <pod-name> -- cat /results/security.json
```

---

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/claude-review.yml
name: Claude Code Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  claude-review:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - name: Install Claude Code
        run: |
          curl -fsSL https://releases.claude.com/claude-code/install.sh | bash
          echo "$HOME/.claude/bin" >> $GITHUB_PATH

      - name: Run Claude Analysis
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          # Get changed files
          CHANGED_FILES=$(git diff --name-only origin/${{ github.base_ref }}...HEAD)

          # Run analysis
          claude -p "Review these changed files for:
          1. Security vulnerabilities
          2. Code quality issues
          3. Best practice violations

          Changed files:
          $CHANGED_FILES" \
          --output-format json > review.json

      - name: Post Review Comment
        uses: actions/github-script@v6
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          script: |
            const fs = require('fs');
            const review = JSON.parse(fs.readFileSync('review.json', 'utf8'));

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## Claude Code Review\n\n${review.result}`
            });
```

### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - analysis

claude-security-scan:
  stage: analysis
  image: claude-headless:latest
  script:
    - |
      claude -p "Perform security audit of all code changes in this MR" \
        --output-format json > security-scan.json

      # Extract findings
      jq -r '.result' security-scan.json > security-report.md
  artifacts:
    reports:
      security: security-scan.json
    paths:
      - security-report.md
  only:
    - merge_requests

claude-performance-check:
  stage: analysis
  image: claude-headless:latest
  script:
    - |
      claude -p "Analyze code for performance issues" \
        --output-format json > performance.json
  artifacts:
    paths:
      - performance.json
  only:
    - merge_requests
```

### Jenkins Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent any

    environment {
        ANTHROPIC_API_KEY = credentials('anthropic-api-key')
    }

    stages {
        stage('Claude Analysis') {
            parallel {
                stage('Security') {
                    steps {
                        script {
                            sh '''
                                claude -p "Security audit" \\
                                  --output-format json > security.json
                            '''

                            def security = readJSON file: 'security.json'
                            echo "Security findings: ${security.result}"
                        }
                    }
                }

                stage('Code Quality') {
                    steps {
                        script {
                            sh '''
                                claude -p "Code quality review" \\
                                  --output-format json > quality.json
                            '''

                            def quality = readJSON file: 'quality.json'
                            echo "Quality findings: ${quality.result}"
                        }
                    }
                }

                stage('Performance') {
                    steps {
                        script {
                            sh '''
                                claude -p "Performance analysis" \\
                                  --output-format json > performance.json
                            '''

                            def performance = readJSON file: 'performance.json'
                            echo "Performance findings: ${performance.result}"
                        }
                    }
                }
            }
        }

        stage('Generate Report') {
            steps {
                script {
                    sh '''
                        claude -p "Combine findings from security.json, quality.json, and performance.json into comprehensive report" \\
                          --output-format text > final-report.md
                    '''

                    archiveArtifacts artifacts: '*.json,final-report.md'
                }
            }
        }
    }

    post {
        always {
            publishHTML([
                reportDir: '.',
                reportFiles: 'final-report.md',
                reportName: 'Claude Analysis Report'
            ])
        }
    }
}
```

---

## Best Practices

### 1. SSH Configuration for Remote Execution

```bash
# ~/.ssh/config
Host app-server-*
    User deployer
    IdentityFile ~/.ssh/deploy_key
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
    LogLevel ERROR
    ServerAliveInterval 60
    ServerAliveCountMax 3

# Usage
ssh app-server-01 "claude -p 'task'"
```

### 2. Error Handling in Remote Execution

```bash
#!/bin/bash
set -euo pipefail

remote_claude() {
  local host="$1"
  local prompt="$2"
  local max_retries=3
  local retry=0

  while [[ $retry -lt $max_retries ]]; do
    if ssh "$host" "claude -p '$prompt' --output-format json"; then
      return 0
    else
      ((retry++))
      echo "Retry $retry/$max_retries for $host" >&2
      sleep 5
    fi
  done

  echo "Failed after $max_retries attempts on $host" >&2
  return 1
}

# Usage
remote_claude "server1" "Analyze logs" || echo "Server1 failed"
```

### 3. Secure Credential Management

```bash
# Never hardcode API keys
# Use environment variables or secret managers

# AWS Secrets Manager
ANTHROPIC_API_KEY=$(aws secretsmanager get-secret-value \
  --secret-id anthropic-api-key \
  --query SecretString \
  --output text)

export ANTHROPIC_API_KEY

# Or use SSH agent forwarding
ssh -A user@remote "claude -p 'task'"
```

### 4. Logging and Auditing

```bash
#!/bin/bash
# Centralized logging for remote execution

LOG_SERVER="logs.example.com"

execute_and_log() {
  local host="$1"
  local task="$2"

  {
    echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
    echo "Host: $host"
    echo "Task: $task"
    echo "---"

    ssh "$host" "claude -p '$task' --output-format json"

    echo "==="
  } | ssh logger@$LOG_SERVER "cat >> /var/log/claude-remote.log"
}
```

---

## Troubleshooting

### SSH Connection Issues

```bash
# Test SSH connectivity
ssh -v user@remote-server echo "Connection OK"

# Check SSH agent
ssh-add -l

# Test with key
ssh -i ~/.ssh/key user@remote-server echo "Key works"
```

### Permission Issues on Remote

```bash
# Ensure Claude user exists
ssh user@remote "sudo useradd -m -s /bin/bash claudeuser"

# Grant necessary permissions
ssh user@remote "sudo usermod -aG docker claudeuser"
```

### Network Timeouts

```bash
# Increase timeout
ssh -o ConnectTimeout=30 user@remote "claude -p 'long task'"

# Use persistent connection
ssh -o ControlMaster=auto -o ControlPath=/tmp/ssh-%r@%h:%p user@remote
```

---

## Next Steps

- **Pipelines** → [../07-pipelines/](../07-pipelines/) for orchestrating remote workflows
- **Monitoring** → [../08-monitoring/](../08-monitoring/) for tracking remote executions
