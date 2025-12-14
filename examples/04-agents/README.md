# Agent Orchestration Examples

Advanced patterns for using sub-agents, super-agents, and complex agent workflows in headless Claude Code.

## Table of Contents

1. [Understanding Sub-Agents](#understanding-sub-agents)
2. [Built-in Agent Types](#built-in-agent-types)
3. [Custom Agent Creation](#custom-agent-creation)
4. [Agent Orchestration Patterns](#agent-orchestration-patterns)
5. [Agent Chaining and Pipelines](#agent-chaining-and-pipelines)
6. [Resumable Agents](#resumable-agents)

---

## Understanding Sub-Agents

Sub-agents are specialized AI assistants that operate independently with their own:
- **Context window**: Isolated from main conversation
- **System prompt**: Customized for specific tasks
- **Tool access**: Restricted to relevant tools only
- **Model**: Can use different models (Haiku/Sonnet/Opus)

### Why Use Sub-Agents?

1. **Specialization**: Focused expertise for specific tasks
2. **Isolation**: Prevent context pollution in main conversation
3. **Performance**: Use faster models (Haiku) for simple tasks
4. **Cost optimization**: Lower costs with model-appropriate selection
5. **Parallel execution**: Run multiple agents simultaneously

---

## Built-in Agent Types

Claude Code provides three built-in sub-agent types:

### 1. Explore Agent (Fast, Read-Only)

**Purpose**: Rapid codebase exploration and search
**Model**: Haiku (fast and cost-effective)
**Tools**: Read, Glob, Grep, Bash
**Mode**: Read-only

**Basic usage:**
```bash
claude -p "Use the Explore agent to find all authentication-related files"

# Explicit thoroughness
claude -p "Use the Explore agent with very thorough search to locate all API endpoints"
```

**Thoroughness levels:**
- **quick**: Fast, surface-level search
- **medium**: Balanced thoroughness and speed
- **very thorough**: Comprehensive, deep exploration

**Advanced example:**
```bash
# Quick exploration for specific files
claude -p "Use Explore agent (quick) to find test files for authentication module"

# Thorough exploration with multiple criteria
claude -p "Use Explore agent (very thorough) to:
1. Find all files related to payment processing
2. Identify database query patterns
3. Locate configuration files
4. Map data flow between components"

# Chained exploration
claude -p "First use Explore agent to find API routes, then use it again to find corresponding test files"
```

### 2. Plan Agent (Research-Only)

**Purpose**: Researches codebase during planning phase
**Model**: Sonnet (capable analysis)
**Tools**: Read, Glob, Grep, Bash
**Mode**: Read-only, research-focused

**Automatic invocation:**
Plan agent is automatically invoked when Claude enters plan mode and needs codebase research.

**Manual usage:**
```bash
# Enter plan mode
claude -p "Plan a refactoring of the authentication system"
# Plan agent automatically activates for research

# Explicit plan agent request
claude -p "Use the Plan agent to research the current state of error handling patterns"
```

**Plan mode workflow:**
```bash
# Complex planning scenario
claude -p "Create a comprehensive plan to:
1. Migrate from REST to GraphQL
2. Maintain backward compatibility
3. Update all client code
4. Implement new testing strategy

Use Plan agent to research current API structure and client usage patterns"
```

### 3. General-Purpose Agent

**Purpose**: Complex multi-step tasks with read/write operations
**Model**: Sonnet (full capability)
**Tools**: All tools available
**Mode**: Full access

**Usage:**
```bash
# Complex refactoring
claude -p "Use general-purpose agent to refactor the authentication module:
1. Extract password hashing to utility
2. Implement JWT refresh tokens
3. Add rate limiting
4. Update tests"

# Multi-file operations
claude -p "Use general-purpose agent to implement feature flagging system across all API endpoints"
```

---

## Custom Agent Creation

### Agent Configuration File Structure

Agents are defined in Markdown files with YAML frontmatter:

**Location:**
- Project-level (highest priority): `.claude/agents/`
- User-level: `~/.claude/agents/`

### Creating a Custom Agent

#### Example 1: Security Auditor Agent

```bash
mkdir -p .claude/agents

cat > .claude/agents/security-auditor.md <<'EOF'
---
name: security-auditor
description: Specialized agent for security vulnerability analysis and penetration testing research. Use when scanning for security issues, analyzing authentication/authorization, or reviewing cryptographic implementations.
model: sonnet
tools: Read, Grep, Glob, Bash
permissionMode: plan
---

# Security Auditor Agent

You are an expert security auditor specializing in application security.

## Your Responsibilities

1. **Vulnerability Detection**: Identify OWASP Top 10 vulnerabilities
2. **Authentication Analysis**: Review auth mechanisms for weaknesses
3. **Cryptographic Review**: Verify proper encryption and hashing
4. **Input Validation**: Check for injection vulnerabilities
5. **Authorization**: Verify access control implementation

## Analysis Framework

For each security review:

1. **Reconnaissance**: Map attack surface
2. **Threat Modeling**: Identify potential attack vectors
3. **Vulnerability Analysis**: Find specific weaknesses
4. **Impact Assessment**: Rate severity (Critical/High/Medium/Low)
5. **Remediation**: Provide actionable fixes with code examples

## Output Format

Provide findings in this structure:

### Finding: [Vulnerability Name]
- **Severity**: Critical/High/Medium/Low
- **Location**: File and line numbers
- **Description**: Detailed explanation
- **Proof of Concept**: Demonstration of exploit
- **Remediation**: Step-by-step fix with code examples
- **References**: OWASP/CWE references

## Tools Usage

- Use **Grep** for pattern-based vulnerability searches
- Use **Read** for detailed code analysis
- Use **Glob** for finding relevant files
- Use **Bash** only for safe, read-only commands

## Security Principles

- Follow principle of least privilege
- Assume all user input is malicious
- Defense in depth
- Fail securely
- Don't trust, verify
EOF

# Use the agent
claude -p "Use security-auditor agent to analyze the authentication system"
```

#### Example 2: Performance Optimizer Agent

```bash
cat > .claude/agents/performance-optimizer.md <<'EOF'
---
name: performance-optimizer
description: Specializes in performance analysis, optimization opportunities, and efficiency improvements. Use for identifying bottlenecks, optimizing algorithms, or improving resource usage.
model: sonnet
tools: Read, Grep, Glob, Bash, Edit, Write
permissionMode: acceptEdits
---

# Performance Optimizer Agent

You are an expert in software performance optimization.

## Core Competencies

1. **Algorithmic Complexity**: Identify O(n²) and worse
2. **Memory Optimization**: Find memory leaks and excessive allocation
3. **Database Performance**: Query optimization and indexing
4. **Caching Strategies**: Implement effective caching
5. **Async Patterns**: Convert blocking to non-blocking operations

## Analysis Process

1. **Profile**: Identify hot paths and bottlenecks
2. **Measure**: Benchmark current performance
3. **Optimize**: Implement improvements
4. **Verify**: Confirm performance gains

## Optimization Checklist

- [ ] Algorithmic efficiency (time complexity)
- [ ] Space complexity and memory usage
- [ ] Database query optimization
- [ ] Network request minimization
- [ ] Caching implementation
- [ ] Lazy loading opportunities
- [ ] Parallel execution possibilities
- [ ] Resource pooling

## Output Format

### Performance Analysis: [Component Name]

**Current State**:
- Complexity: O(?)
- Estimated operations: X
- Memory usage: Y MB

**Bottlenecks**:
1. [Issue description]
2. [Issue description]

**Optimizations**:
1. [Optimization with code example]
   - Expected improvement: X%
   - Tradeoffs: [any downsides]

**Implementation Priority**:
- High impact, low effort: [items]
- High impact, high effort: [items]
- Low impact: [items]
EOF

# Use the agent
claude -p "Use performance-optimizer agent to analyze and optimize the user search functionality"
```

#### Example 3: Documentation Generator Agent

```bash
cat > .claude/agents/docs-generator.md <<'EOF'
---
name: docs-generator
description: Automatically generates and maintains comprehensive documentation including API docs, README files, code comments, and tutorials. Use when documentation is missing or outdated.
model: sonnet
tools: Read, Grep, Glob, Write, Edit
permissionMode: acceptEdits
skills: api-documentation, tutorial-writing
---

# Documentation Generator Agent

You are a technical documentation specialist.

## Documentation Types

1. **API Documentation**: Endpoints, parameters, responses
2. **Code Comments**: JSDoc, inline explanations
3. **README Files**: Project overview, setup, usage
4. **Tutorials**: Step-by-step guides
5. **Architecture Docs**: System design, patterns

## Documentation Standards

### API Documentation Template

```markdown
## Endpoint: METHOD /path

**Description**: What this endpoint does

**Authentication**: Required/Optional

**Parameters**:
- `param1` (type, required): Description
- `param2` (type, optional): Description

**Request Example**:
```http
METHOD /path
Content-Type: application/json

{request body}
```

**Success Response** (200 OK):
```json
{response}
```

**Error Responses**:
- 400: Bad Request - Invalid parameters
- 401: Unauthorized - Missing/invalid token
- 404: Not Found - Resource doesn't exist
```

### Code Comment Standards

- All public functions must have JSDoc
- Complex logic must have inline comments
- Use examples in documentation
- Keep comments up-to-date with code

## Process

1. **Analyze**: Review code to understand functionality
2. **Extract**: Identify undocumented areas
3. **Generate**: Create comprehensive documentation
4. **Format**: Follow project style guide
5. **Verify**: Ensure accuracy and completeness
EOF

# Use the agent
claude -p "Use docs-generator agent to create comprehensive API documentation for all REST endpoints"
```

### Agent Configuration via CLI

For dynamic agent creation without files:

```bash
# Define agent inline with JSON
claude --agents '{
  "name": "test-automator",
  "description": "Generates comprehensive test suites",
  "model": "sonnet",
  "tools": ["Read", "Write", "Grep", "Glob", "Bash"],
  "permissionMode": "acceptEdits"
}' -p "Create unit tests for authentication module"

# Multiple agents
claude --agents '[
  {
    "name": "analyzer",
    "description": "Code analysis",
    "model": "haiku",
    "tools": ["Read", "Grep"]
  },
  {
    "name": "implementer",
    "description": "Code implementation",
    "model": "sonnet",
    "tools": ["Read", "Write", "Edit"]
  }
]' -p "First analyze then implement feature"
```

---

## Agent Orchestration Patterns

### Pattern 1: Sequential Agent Chain

Execute agents in sequence, passing context between them:

```bash
claude -p "First, use the Explore agent (very thorough) to map all authentication files.

Then, use the security-auditor agent to perform a comprehensive security review of those files.

Finally, use the docs-generator agent to create security documentation based on the findings."
```

### Pattern 2: Parallel Agent Execution

For independent tasks that can run simultaneously:

```bash
# In headless mode, use multiple sessions
SESSION1=$(claude -p "Use Explore agent to find all API endpoints" \
  --output-format json --session-id "explore-apis" &)

SESSION2=$(claude -p "Use Explore agent to find all database models" \
  --output-format json --session-id "explore-models" &)

SESSION3=$(claude -p "Use Explore agent to find all test files" \
  --output-format json --session-id "explore-tests" &)

# Wait for all to complete
wait

# Process results
echo "API exploration: $SESSION1" | jq -r '.result'
echo "Model exploration: $SESSION2" | jq -r '.result'
echo "Test exploration: $SESSION3" | jq -r '.result'
```

### Pattern 3: Conditional Agent Selection

Choose agent based on analysis results:

```bash
#!/bin/bash
# conditional-agent.sh

# Step 1: Analyze complexity
ANALYSIS=$(claude -p "Analyze the complexity of implementing OAuth2 authentication" \
  --output-format json)

COMPLEXITY=$(echo "$ANALYSIS" | jq -r '.result' | grep -c "complex")

# Step 2: Choose appropriate agent based on complexity
if [[ $COMPLEXITY -gt 5 ]]; then
  # High complexity - use general-purpose agent with full access
  echo "High complexity detected, using general-purpose agent"
  claude -p "Use general-purpose agent to implement OAuth2 authentication with comprehensive error handling and testing"
else
  # Low complexity - use faster Explore agent for guidance
  echo "Low complexity, using Explore agent"
  claude -p "Use Explore agent to find OAuth2 implementation examples and provide implementation guidance"
fi
```

### Pattern 4: Supervisor Pattern

Main conversation supervises multiple specialized agents:

```bash
#!/bin/bash
# supervisor-pattern.sh

FEATURE="user-registration"
SESSION_FILE=".supervisor-session"

# Supervisor: Coordinate overall workflow
SUPERVISOR=$(claude -p "Coordinate implementation of $FEATURE:

1. Use Explore agent to research existing user management code
2. Use security-auditor agent to review proposed implementation
3. Use performance-optimizer agent to ensure efficiency
4. Use docs-generator agent to create documentation
5. Provide final implementation review and integration plan" \
  --output-format json \
  --max-turns 50)

# Save supervisor session for future reference
echo "$SUPERVISOR" | jq -r '.metadata.sessionId' > "$SESSION_FILE"

echo "Supervised implementation complete"
echo "$SUPERVISOR" | jq -r '.result'
```

---

## Agent Chaining and Pipelines

### Simple Agent Pipeline

```bash
#!/bin/bash
# agent-pipeline.sh

COMPONENT="$1"

echo "=== Agent Pipeline for $COMPONENT ==="

# Stage 1: Exploration (Haiku for speed)
echo "Stage 1: Exploring $COMPONENT..."
EXPLORATION=$(claude -p "Use Explore agent (very thorough) to:
1. Locate all files related to $COMPONENT
2. Map dependencies
3. Identify test coverage
4. Find related documentation" \
  --output-format json)

EXPLORE_SESSION=$(echo "$EXPLORATION" | jq -r '.metadata.sessionId')
echo "Exploration complete (Session: $EXPLORE_SESSION)"

# Stage 2: Security Analysis
echo "Stage 2: Security analysis..."
SECURITY=$(claude -p "Use security-auditor agent to analyze $COMPONENT for vulnerabilities" \
  --output-format json)

SEC_FINDINGS=$(echo "$SECURITY" | jq -r '.result')

# Stage 3: Performance Analysis
echo "Stage 3: Performance analysis..."
PERFORMANCE=$(claude -p "Use performance-optimizer agent to analyze $COMPONENT" \
  --output-format json)

PERF_FINDINGS=$(echo "$PERFORMANCE" | jq -r '.result')

# Stage 4: Generate Report
echo "Stage 4: Generating comprehensive report..."
claude -p "Generate a comprehensive analysis report for $COMPONENT:

Security Findings:
$SEC_FINDINGS

Performance Findings:
$PERF_FINDINGS

Include:
1. Executive summary
2. Detailed findings
3. Prioritized recommendations
4. Implementation roadmap" > "${COMPONENT}-analysis-report.md"

echo "=== Pipeline Complete ==="
echo "Report: ${COMPONENT}-analysis-report.md"
```

**Usage:**
```bash
./agent-pipeline.sh "authentication-module"
```

### Advanced Multi-Agent Pipeline

```bash
#!/bin/bash
# multi-agent-refactoring.sh

MODULE="$1"
TARGET_DIR="${2:-./}"

# Configuration
PIPELINE_SESSION=".pipeline-$(date +%s)"

pipeline_stage() {
  local stage_name="$1"
  local agent="$2"
  local prompt="$3"
  local session_file="${PIPELINE_SESSION}-${stage_name}"

  echo "=== ${stage_name} ==="

  RESULT=$(claude -p "Use $agent agent: $prompt" \
    --output-format json \
    --max-turns 20)

  # Save session and result
  echo "$RESULT" | jq -r '.metadata.sessionId' > "${session_file}.session"
  echo "$RESULT" | jq -r '.result' > "${session_file}.result"

  echo "✓ ${stage_name} complete"
  echo ""
}

# Execute pipeline
{
  # Stage 1: Discovery
  pipeline_stage "Discovery" "Explore" \
    "Map all files, dependencies, and architecture of $MODULE in $TARGET_DIR"

  # Stage 2: Code Analysis
  pipeline_stage "CodeAnalysis" "general-purpose" \
    "Analyze code quality, patterns, and technical debt in $MODULE"

  # Stage 3: Security Audit
  pipeline_stage "SecurityAudit" "security-auditor" \
    "Comprehensive security review of $MODULE"

  # Stage 4: Performance Review
  pipeline_stage "PerformanceReview" "performance-optimizer" \
    "Analyze performance and optimization opportunities in $MODULE"

  # Stage 5: Refactoring Plan
  pipeline_stage "RefactoringPlan" "general-purpose" \
    "Create detailed refactoring plan based on all findings"

  # Stage 6: Implementation (with approval)
  echo "=== Refactoring Plan Ready ==="
  cat "${PIPELINE_SESSION}-RefactoringPlan.result"

  read -p "Proceed with refactoring? (y/n) " -n 1 -r
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    pipeline_stage "Implementation" "general-purpose" \
      "Execute refactoring plan for $MODULE with comprehensive testing"

    pipeline_stage "Documentation" "docs-generator" \
      "Update all documentation to reflect refactored $MODULE"

    echo "=== Refactoring Complete ==="
  else
    echo "Refactoring cancelled"
  fi

} | tee "pipeline-${MODULE}-$(date +%Y%m%d-%H%M%S).log"

# Cleanup sessions
rm -f ${PIPELINE_SESSION}-*.session
```

---

## Resumable Agents

Sub-agents can be resumed across sessions using their unique agent IDs.

### Basic Agent Resume

```bash
# Initial execution
claude -p "Use security-auditor agent to begin comprehensive audit of payment processing"

# Claude will output something like:
# "Agent ID: agent-abc123def456"

# Later, resume that specific agent
claude -p "Resume agent agent-abc123def456 and continue the audit with database queries"
```

### Agent Resume Pattern with Tracking

```bash
#!/bin/bash
# resumable-audit.sh

AUDIT_TYPE="$1"
AGENT_SESSION_FILE=".agent-${AUDIT_TYPE}.session"

if [[ -f "$AGENT_SESSION_FILE" ]]; then
  # Resume existing audit
  AGENT_ID=$(cat "$AGENT_SESSION_FILE")
  echo "Resuming audit agent: $AGENT_ID"

  claude -p "Resume agent $AGENT_ID and continue the $AUDIT_TYPE audit with next steps"
else
  # Start new audit
  echo "Starting new $AUDIT_TYPE audit"

  RESULT=$(claude -p "Use security-auditor agent to begin comprehensive $AUDIT_TYPE audit" \
    --output-format json)

  # Extract and save agent ID
  AGENT_ID=$(echo "$RESULT" | jq -r '.agentId // empty')

  if [[ -n "$AGENT_ID" ]]; then
    echo "$AGENT_ID" > "$AGENT_SESSION_FILE"
    echo "Agent ID saved: $AGENT_ID"
  fi

  echo "$RESULT" | jq -r '.result'
fi
```

**Usage:**
```bash
# Day 1: Start audit
./resumable-audit.sh "authentication"

# Day 2: Continue audit
./resumable-audit.sh "authentication"

# Day 3: Continue audit
./resumable-audit.sh "authentication"
```

### Long-Running Agent Workflow

```bash
#!/bin/bash
# long-running-migration.sh

MIGRATION_NAME="$1"
AGENT_FILE=".migration-agent"
PROGRESS_FILE=".migration-progress"

# Initialize or resume
if [[ -f "$AGENT_FILE" ]]; then
  AGENT_ID=$(cat "$AGENT_FILE")
  PROGRESS=$(cat "$PROGRESS_FILE")

  echo "Resuming migration '$MIGRATION_NAME' (Progress: $PROGRESS%)"
  echo "Agent: $AGENT_ID"

  PROMPT="Resume agent $AGENT_ID and continue the $MIGRATION_NAME migration from $PROGRESS% complete"
else
  echo "Starting new migration: $MIGRATION_NAME"

  PROMPT="Use general-purpose agent to execute $MIGRATION_NAME migration:
1. Create detailed migration plan
2. Execute migration in phases
3. Verify each phase
4. Update progress
5. Handle rollback if needed"
fi

# Execute with agent
RESULT=$(claude -p "$PROMPT" \
  --output-format json \
  --max-turns 30)

# Save agent ID and update progress
AGENT_ID=$(echo "$RESULT" | jq -r '.agentId // empty')
if [[ -n "$AGENT_ID" ]]; then
  echo "$AGENT_ID" > "$AGENT_FILE"
fi

# Parse progress from output (example - adjust based on actual output)
NEW_PROGRESS=$(echo "$RESULT" | jq -r '.result' | grep -oP 'Progress: \K[0-9]+' | tail -1)
if [[ -n "$NEW_PROGRESS" ]]; then
  echo "$NEW_PROGRESS" > "$PROGRESS_FILE"
fi

# Display results
echo "$RESULT" | jq -r '.result'

# Check if migration complete
if [[ "$NEW_PROGRESS" == "100" ]]; then
  echo "=== Migration Complete ==="
  rm -f "$AGENT_FILE" "$PROGRESS_FILE"
fi
```

---

## Best Practices

### 1. Agent Selection Guidelines

```bash
# Use Explore for: Fast searches, file discovery, read-only analysis
claude -p "Use Explore agent to find all configuration files"

# Use Plan for: Research before implementation, architecture planning
claude -p "Use Plan agent to research current state before refactoring"

# Use General-Purpose for: Complex multi-step tasks, write operations
claude -p "Use general-purpose agent to implement new feature"

# Use Custom for: Specialized, domain-specific tasks
claude -p "Use security-auditor agent for vulnerability assessment"
```

### 2. Tool Restriction Best Practices

```bash
# Security agents: Read-only tools
tools: Read, Grep, Glob

# Implementation agents: Full access
tools: Read, Write, Edit, Grep, Glob, Bash

# Analysis agents: Read + safe execution
tools: Read, Grep, Glob, Bash
permissionMode: plan
```

### 3. Model Selection Strategy

```bash
# Haiku: Fast, simple tasks (searches, quick analysis)
model: haiku

# Sonnet: Complex reasoning, implementation
model: sonnet

# Opus: Most complex tasks, creative solutions
model: opus

# Inherit: Use same model as main conversation
model: inherit
```

### 4. Agent Naming Conventions

- Use lowercase with hyphens: `security-auditor`
- Be descriptive: `api-documentation-generator` not `doc-gen`
- Avoid version numbers in names
- Use category prefixes: `test-unit-generator`, `test-e2e-generator`

### 5. Managing Agent Lifecycle

```bash
# List all agents
claude -p "List all available agents"

# View agent configuration
cat .claude/agents/security-auditor.md

# Test agent before production use
claude -p "Use security-auditor agent to test on sample file" \
  --allowedTools "Read"

# Version control agents
git add .claude/agents/
git commit -m "feat: add security-auditor agent"
```

---

## Troubleshooting

### Agent Not Found

```bash
# Check agent file exists
ls -la .claude/agents/
ls -la ~/.claude/agents/

# Verify YAML frontmatter
head -10 .claude/agents/your-agent.md

# Restart may be needed after creating new agent files
```

### Agent Using Wrong Tools

```bash
# Explicitly specify allowed tools
claude --agents '{
  "name": "my-agent",
  "tools": ["Read", "Grep"]
}' -p "Use my-agent for analysis"
```

### Agent Resume Fails

```bash
# Verify agent ID format
# Should be: agent-{alphanumeric}

# Check transcript file exists
ls -la .claude/transcripts/agent-*.jsonl

# Use correct resume syntax
claude -p "Resume agent agent-abc123 and continue task"
```

---

## Next Steps

- **Skills** → [../05-skills/](../05-skills/) for skill development and integration
- **Remote Execution** → [../06-remote/](../06-remote/) for distributed agent execution
- **Pipelines** → [../07-pipelines/](../07-pipelines/) for complex workflows
