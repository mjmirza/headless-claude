# Claude Code Execution Models

Deep dive into the different execution models, their internals, and when to use each.

## Table of Contents

1. [Single-Shot Execution](#single-shot-execution)
2. [Multi-Turn Conversations](#multi-turn-conversations)
3. [Streaming Execution](#streaming-execution)
4. [Agent-Based Execution](#agent-based-execution)
5. [Distributed Execution](#distributed-execution)

---

## Single-Shot Execution

### Architecture

```
User Command → CLI → API Request → Claude Model → Response → Output
     ↓                                                           ↑
  --print flag                                            --output-format
```

### Characteristics

- **Stateless**: No context preservation
- **Fast**: Single request-response cycle
- **Simple**: Minimal overhead
- **Cost-effective**: Pay for one interaction only

### Internals

When you execute:
```bash
claude -p "Analyze this code"
```

The following happens:

1. **CLI Parsing**
   - Parse flags and options
   - Extract prompt from `-p` argument
   - Determine output format

2. **Context Building**
   - Current working directory
   - System prompt
   - Tool definitions
   - Model selection

3. **API Request**
   - Single message to Anthropic API
   - Model processes with available tools
   - Returns response

4. **Output Rendering**
   - Format based on `--output-format`
   - Exit with appropriate code

### Best Use Cases

- Quick queries
- Simple analysis
- File reading
- Pattern searching
- When context doesn't matter

### Example Workflow

```bash
# Check for specific pattern
claude -p "Search for TODO comments in src/"

# Validate configuration
claude -p "Validate the JSON in config.json"

# Quick security check
claude -p "Scan for hardcoded secrets in this directory"
```

---

## Multi-Turn Conversations

### Architecture

```
Turn 1:  User → Claude → Response → Session Created
                                          ↓
Turn 2:  User → Claude (with context) → Response
                                          ↓
Turn 3:  User → Claude (with full history) → Response
```

### Session Management

#### Session Storage

Sessions are stored as JSONL (JSON Lines) files:

```
~/.claude/transcripts/
├── session-abc123def456.jsonl
├── session-xyz789uvw012.jsonl
└── agent-agent123.jsonl
```

Each line is a message:
```json
{"role":"user","content":"Initial request"}
{"role":"assistant","content":"Response...","metadata":{...}}
{"role":"user","content":"Follow-up request"}
```

#### Session Continuation

**Continue last session** (`--continue`):
```bash
# First execution
claude -p "Start analysis" --output-format json
# → Creates session-abc123.jsonl

# Continue automatically
claude -c -p "Continue with next step"
# → Loads most recent session
```

**Resume specific session** (`--resume`):
```bash
# Capture session ID
RESULT=$(claude -p "Begin work" --output-format json)
SESSION=$(echo "$RESULT" | jq -r '.metadata.sessionId')

# Resume later
claude -r "$SESSION" -p "Continue from where we left off"
```

### Context Window Management

Claude Code automatically manages context:

1. **Full History**: All turns preserved
2. **Tool Results**: All tool outputs included
3. **Smart Truncation**: Older content summarized if needed
4. **Cost Tracking**: Cumulative cost across turns

### Best Use Cases

- Multi-step analysis
- Iterative refactoring
- Complex debugging
- Exploratory research
- Building on previous findings

### Example Workflow

```bash
# Complex security audit across multiple turns
RESULT=$(claude -p "Begin comprehensive security audit of authentication system" \
  --output-format json)

SESSION=$(echo "$RESULT" | jq -r '.metadata.sessionId')

# Turn 2: Deep dive on findings
claude -r "$SESSION" -p "For each security issue found, analyze exploitability"

# Turn 3: Generate fixes
claude -r "$SESSION" -p "Generate secure code examples for each vulnerability"

# Turn 4: Create report
claude -r "$SESSION" -p "Create executive security report with all findings"
```

---

## Streaming Execution

### Architecture

```
User Command → CLI → Streaming API → Real-time events
                                           ↓
                                    Parse & Display
                                           ↓
                                    User Processing
```

### Event Stream Format

With `--output-format stream-json`, you get JSONL events:

```json
{"type":"message_start","message":{"id":"msg_123","role":"assistant"}}
{"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}
{"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Starting"}}
{"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":" analysis"}}
{"type":"tool_use","name":"Read","input":{"file_path":"src/index.ts"}}
{"type":"tool_result","tool_use_id":"tool_123","content":"[file contents]"}
{"type":"content_block_stop","index":0}
{"type":"message_delta","delta":{"stop_reason":"end_turn"}}
{"type":"message_stop"}
```

### Real-Time Processing

```bash
claude -p "Large codebase analysis" --output-format stream-json | \
while read -r event; do
  TYPE=$(echo "$event" | jq -r '.type')

  case "$TYPE" in
    "content_block_delta")
      # Display text as it arrives
      echo "$event" | jq -r '.delta.text' | tr -d '\n'
      ;;
    "tool_use")
      # Show which tool is being used
      TOOL=$(echo "$event" | jq -r '.name')
      echo -e "\n[Using tool: $TOOL]"
      ;;
    "message_stop")
      echo -e "\n✓ Complete"
      ;;
  esac
done
```

### Progress Tracking

```bash
#!/bin/bash
# Track progress with visual feedback

STEPS=0
claude -p "Complex multi-step task" --output-format stream-json | \
while read -r event; do
  TYPE=$(echo "$event" | jq -r '.type')

  if [[ "$TYPE" == "tool_use" ]]; then
    ((STEPS++))
    printf "\rProgress: Step %d" "$STEPS"
  fi

  if [[ "$TYPE" == "message_stop" ]]; then
    printf "\n✓ Completed %d steps\n" "$STEPS"
  fi
done
```

### Best Use Cases

- Long-running analysis
- Progress monitoring
- Real-time dashboards
- Incremental processing
- User feedback during execution

---

## Agent-Based Execution

### Architecture

```
Main Conversation
    ↓
Launch Sub-Agent → Isolated Context
                        ↓
                   Specialized Tools
                        ↓
                   Model (Haiku/Sonnet/Opus)
                        ↓
                   Complete Task → Return to Main
```

### Agent Lifecycle

1. **Agent Definition**
   ```yaml
   # .claude/agents/security-scanner.md
   ---
   name: security-scanner
   description: Scans for security vulnerabilities
   model: sonnet
   tools: Read, Grep, Glob
   permissionMode: plan
   ---
   ```

2. **Agent Invocation**
   ```bash
   claude -p "Use security-scanner agent to audit authentication"
   ```

3. **Execution**
   - Main conversation pauses
   - Sub-agent spawns with isolated context
   - Agent executes with defined tools and model
   - Results returned to main conversation
   - Main conversation resumes

4. **Result Integration**
   - Agent findings available in main context
   - Can reference agent outputs
   - Can spawn additional agents

### Agent Context Isolation

Each agent has:
- **Own context window**: Doesn't pollute main conversation
- **Own system prompt**: Specialized instructions
- **Own tool set**: Restricted capabilities
- **Own model**: Cost/performance optimization

### Agent Chaining

```bash
# Sequential agent execution
claude -p "
1. Use Explore agent to find all API endpoints
2. Use security-scanner agent to audit those endpoints
3. Use documentation-generator agent to document findings
"
```

### Agent Resumption

Agents can be resumed like conversations:

```bash
# Agent creates resumable session
claude -p "Use security-scanner agent to begin audit"
# → Outputs: Agent ID: agent-abc123

# Later, resume agent
claude -p "Resume agent agent-abc123 and continue audit with database analysis"
```

### Best Use Cases

- Specialized tasks (security, performance, docs)
- Parallel execution (multiple agents)
- Cost optimization (use Haiku for simple agents)
- Context isolation (prevent main conversation pollution)
- Resumable workflows

---

## Distributed Execution

### Architecture

```
Control Node
    ↓
┌───┴───┬────────┬────────┐
↓       ↓        ↓        ↓
Host1   Host2   Host3   HostN
↓       ↓        ↓        ↓
Claude  Claude  Claude  Claude
↓       ↓        ↓        ↓
└───┬───┴────────┴────────┘
    ↓
Aggregate Results
```

### Execution Patterns

#### 1. Parallel Independent

Each host executes independently:

```bash
# Same task on all hosts
for host in host{1..10}; do
  ssh user@$host "claude -p 'Analyze local logs'" &
done
wait
```

**Use when:**
- Tasks are independent
- No data sharing needed
- Results can be aggregated

#### 2. Map-Reduce

Distribute work, then combine:

```bash
# Map: Each host processes subset
for host in host{1..10}; do
  ssh user@$host "claude -p 'Process local data'" > "result-$host.json" &
done
wait

# Reduce: Combine results
cat result-*.json | claude -p "Aggregate these results"
```

**Use when:**
- Large dataset to process
- Each subset can be processed independently
- Final aggregation needed

#### 3. Pipeline

Sequential processing across hosts:

```bash
# Stage 1: Host 1
RESULT1=$(ssh user@host1 "claude -p 'Step 1: Extract data'")

# Stage 2: Host 2 (uses output from Stage 1)
RESULT2=$(ssh user@host2 "claude -p 'Step 2: Transform: $RESULT1'")

# Stage 3: Host 3 (uses output from Stage 2)
RESULT3=$(ssh user@host3 "claude -p 'Step 3: Load: $RESULT2'")
```

**Use when:**
- Sequential dependencies
- Each stage requires different resources
- Data transformation needed

### Load Balancing

```bash
# Dynamic selection based on load
get_least_loaded_host() {
  local hosts=("$@")
  local min_load=999
  local selected=""

  for host in "${hosts[@]}"; do
    load=$(ssh user@$host "uptime | awk '{print \$(NF-2)}' | tr -d ','")
    if (( $(echo "$load < $min_load" | bc -l) )); then
      min_load=$load
      selected=$host
    fi
  done

  echo "$selected"
}

# Execute on least loaded
HOSTS=(host1 host2 host3)
TARGET=$(get_least_loaded_host "${HOSTS[@]}")
ssh user@$TARGET "claude -p 'Heavy task'"
```

### Fault Tolerance

```bash
# Retry failed hosts
HOSTS=(host1 host2 host3)
TASK="Analyze logs"

for host in "${HOSTS[@]}"; do
  {
    retry=0
    max_retries=3

    while [[ $retry -lt $max_retries ]]; do
      if ssh user@$host "claude -p '$TASK'"; then
        break
      else
        ((retry++))
        sleep 5
      fi
    done

    if [[ $retry -eq $max_retries ]]; then
      echo "Host $host failed after $max_retries attempts" >&2
    fi
  } &
done
wait
```

### Best Use Cases

- Large-scale analysis (many servers)
- Geographically distributed systems
- High-availability requirements
- Resource-intensive tasks
- Parallel data processing

---

## Choosing the Right Model

| Scenario | Recommended Model | Reasoning |
|----------|-------------------|-----------|
| Quick file search | Single-shot | No context needed |
| Multi-step refactoring | Multi-turn | Iterative changes |
| Real-time monitoring | Streaming | Progress visibility |
| Specialized audit | Agent-based | Isolation + specialization |
| Analyze 100 servers | Distributed | Parallel processing |
| Security scan + performance analysis | Multiple agents (parallel) | Different specializations |
| ETL pipeline across regions | Distributed pipeline | Geographic distribution |

---

## Performance Characteristics

### Latency

```
Single-shot:    ~2-5 seconds (one API call)
Multi-turn:     +context loading per turn (~500ms)
Streaming:      First token ~1-2 seconds
Agent spawn:    +~1 second per agent
Remote SSH:     +network latency (~50-200ms)
```

### Cost

```
Single-shot:    Cost of one interaction
Multi-turn:     Cumulative (context grows)
Streaming:      Same as single-shot (different delivery)
Agent:          Per-agent cost (can optimize with Haiku)
Distributed:    N × cost (parallelization)
```

### Scalability

```
Single-shot:    Rate-limited by API
Multi-turn:     Limited by context window
Streaming:      Same as single-shot
Agents:         Can spawn multiple (parallelization)
Distributed:    Linear scaling with hosts
```

---

## Best Practices

### 1. Match Model to Need

```bash
# Don't use multi-turn for simple queries
# ❌ Bad
RESULT=$(claude -p "List files" --output-format json)
SESSION=$(echo "$RESULT" | jq -r '.metadata.sessionId')
claude -r "$SESSION" -p "Done"  # Unnecessary

# ✓ Good
claude -p "List files"
```

### 2. Use Agents for Specialization

```bash
# Don't use main conversation for specialized tasks
# ❌ Bad
claude -p "Analyze security, then performance, then quality"

# ✓ Good
claude -p "Use security-scanner agent for security, performance-analyzer for performance"
```

### 3. Stream for Long Tasks

```bash
# Don't block on long tasks without feedback
# ❌ Bad
claude -p "Analyze entire codebase" --output-format json  # Black box

# ✓ Good
claude -p "Analyze entire codebase" --output-format stream-json | process
```

### 4. Distribute When Appropriate

```bash
# Don't run serially when parallel is possible
# ❌ Bad
for host in host{1..100}; do
  ssh user@$host "claude -p 'task'"
done  # Takes 100x time

# ✓ Good
for host in host{1..100}; do
  ssh user@$host "claude -p 'task'" &
done
wait  # All parallel
```

---

## Summary

| Model | When to Use | Key Benefit |
|-------|-------------|-------------|
| **Single-shot** | Simple queries, independent tasks | Speed, simplicity |
| **Multi-turn** | Iterative work, context building | Context preservation |
| **Streaming** | Long tasks, progress needed | Real-time feedback |
| **Agent-based** | Specialized tasks, isolation | Specialization, cost control |
| **Distributed** | Scale, geographic distribution | Parallelization, HA |

Choose based on your specific requirements for context, specialization, feedback, and scale.
