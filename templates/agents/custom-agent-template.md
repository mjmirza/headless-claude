# Custom Agent Template

Use this template to create your own specialized sub-agents for Claude Code.

## File Location

Save this file as: `.claude/agents/your-agent-name.md`

---

## Template

```markdown
---
name: your-agent-name
description: Clear description of what this agent does and when Claude should use it. Be specific and include key trigger words. This description helps Claude decide when to automatically invoke this agent.
model: sonnet  # Options: haiku (fast), sonnet (balanced), opus (most capable), inherit (use main conversation model)
tools: Read, Grep, Glob, Bash  # Comma-separated list of allowed tools, or omit to allow all
permissionMode: plan  # Options: default, acceptEdits, bypassPermissions, plan, ignore
skills: skill-name-1, skill-name-2  # Optional: Auto-load specific skills
---

# Agent Name

Brief overview of what this agent does and its specialized capabilities.

## Purpose

What problems does this agent solve? When should it be used?

## Capabilities

List the specific things this agent can do:

1. Capability 1
2. Capability 2
3. Capability 3

## Analysis Framework

Describe the systematic approach this agent follows:

### Step 1: [Phase Name]

What the agent does in this phase.

### Step 2: [Phase Name]

What the agent does in this phase.

### Step 3: [Phase Name]

What the agent does in this phase.

## Tools Usage Guidelines

Explain how this agent should use its available tools:

- **Read**: When and why to use
- **Grep**: Search patterns and use cases
- **Glob**: File discovery strategies
- **Bash**: Safe commands only (if applicable)

## Output Format

Define the expected output structure:

```
### [Output Section Title]

**Field 1**: Description
**Field 2**: Description

[Detailed findings]

### Recommendations

[Actionable recommendations]
```

## Best Practices

Guidelines for this agent's operation:

1. Best practice 1
2. Best practice 2
3. Best practice 3

## Examples

Provide examples of when to use this agent:

### Example 1: [Use Case]

**Scenario**: Description of scenario

**Invocation**:
```bash
claude -p "Use your-agent-name agent to [task description]"
```

**Expected Output**: Brief description of expected results

### Example 2: [Use Case]

[Similar structure]

## Limitations

What this agent cannot or should not do:

- Limitation 1
- Limitation 2
- Limitation 3

## Related Agents

If applicable, mention related or complementary agents:

- **agent-name-1**: When to use this instead
- **agent-name-2**: How to use in combination
```

---

## Field Descriptions

### Frontmatter Fields

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `name` | Yes | Unique identifier (lowercase, hyphens) | `security-auditor` |
| `description` | Yes | What agent does + when to use (max 1024 chars) | `Performs security audits...` |
| `model` | No | Model to use (defaults to sonnet) | `haiku`, `sonnet`, `opus`, `inherit` |
| `tools` | No | Allowed tools (omit for all) | `Read, Grep, Glob` |
| `permissionMode` | No | How to handle permissions | `plan`, `acceptEdits`, `default` |
| `skills` | No | Auto-loaded skills | `api-security, code-review` |

### Permission Modes

| Mode | Behavior | Use Case |
|------|----------|----------|
| `default` | Prompt for all permissions | Interactive use |
| `acceptEdits` | Auto-accept file edits | Trusted modifications |
| `bypassPermissions` | Skip all prompts | Automation (careful!) |
| `plan` | Read-only planning mode | Research and analysis |
| `ignore` | Ignore permission requests | Advanced use only |

---

## Example Agents

### Example 1: API Documentation Generator

```markdown
---
name: api-doc-generator
description: Automatically generates comprehensive API documentation from code including endpoints, parameters, request/response examples, and error codes. Use when documenting REST APIs or when API docs are missing or outdated.
model: sonnet
tools: Read, Write, Grep, Glob
permissionMode: acceptEdits
---

# API Documentation Generator

Generates comprehensive, standardized API documentation from source code.

## Purpose

Automatically create complete API documentation including:
- Endpoint descriptions
- Request/response formats
- Authentication requirements
- Error codes and handling
- Usage examples

## Process

1. **Discovery**: Find all API endpoint definitions
2. **Analysis**: Extract parameters, responses, error handling
3. **Generation**: Create documentation in standard format
4. **Validation**: Ensure completeness and accuracy

## Output Format

```markdown
## Endpoint: METHOD /path

**Description**: What this endpoint does

**Authentication**: Required/Optional

**Parameters**:
- `param` (type, required): Description

**Request Example**:
[code block]

**Response Example**:
[code block]

**Error Responses**:
- 400: Description
- 401: Description
```
```

### Example 2: Performance Profiler

```markdown
---
name: performance-profiler
description: Identifies performance bottlenecks, analyzes algorithmic complexity, and suggests optimizations. Use when code is slow, when optimizing for scale, or when reviewing performance-critical paths.
model: sonnet
tools: Read, Grep, Glob, Bash
permissionMode: plan
---

# Performance Profiler

Analyzes code for performance issues and optimization opportunities.

## Analysis Areas

1. **Time Complexity**: Identify O(n²) and worse algorithms
2. **Space Complexity**: Memory usage and leaks
3. **Database Queries**: N+1 problems, missing indexes
4. **I/O Operations**: Blocking operations, batching opportunities
5. **Caching**: Missing cache layers

## Process

1. **Profile**: Identify hot paths
2. **Measure**: Benchmark current performance
3. **Analyze**: Find bottlenecks
4. **Recommend**: Suggest specific optimizations

## Output Format

### Performance Analysis: [Component]

**Current Complexity**: O(?)
**Estimated Operations**: X
**Bottlenecks**: [List]

**Optimization 1**: [Description]
- Expected improvement: X%
- Implementation effort: Low/Medium/High
- Code example: [snippet]
```

---

## Tips for Effective Agents

### 1. Descriptive Names

```markdown
# ✓ Good
name: jwt-token-validator

# ❌ Bad
name: validator
```

### 2. Specific Descriptions

```markdown
# ✓ Good
description: Validates JWT tokens checking signature, expiration, claims, and algorithm security. Use when reviewing authentication code, JWT implementations, or token handling.

# ❌ Bad
description: Validates things
```

### 3. Appropriate Tool Restriction

```markdown
# For analysis agents (read-only)
tools: Read, Grep, Glob

# For implementation agents (full access)
tools: Read, Write, Edit, Grep, Glob, Bash

# For safe execution agents
tools: Read, Grep, Glob, Bash
permissionMode: plan
```

### 4. Clear Process Definition

Define step-by-step what the agent does so Claude knows how to operate as this agent.

### 5. Output Standardization

Provide clear output format templates so results are consistent.

---

## Testing Your Agent

```bash
# 1. Create agent file
cat > .claude/agents/test-agent.md <<'EOF'
[Your agent definition]
EOF

# 2. Test invocation
claude -p "Use test-agent agent to perform simple task"

# 3. Verify agent is discovered
claude -p "List all available agents"

# 4. Check agent actually activates
claude -p "Test task that should trigger test-agent" --verbose
```

---

## Sharing Agents

### For Teams (Project-Level)

```bash
# 1. Create in project directory
.claude/agents/your-agent.md

# 2. Commit to version control
git add .claude/agents/your-agent.md
git commit -m "feat: add your-agent agent"
git push

# 3. Team members pull and use automatically
```

### For Personal Use (User-Level)

```bash
# Create in home directory
~/.claude/agents/your-agent.md

# Available across all projects
```

---

## Common Agent Patterns

### Security Analyzer

```yaml
tools: Read, Grep, Glob
permissionMode: plan
model: sonnet
```

### Code Implementer

```yaml
tools: Read, Write, Edit, Grep, Glob
permissionMode: acceptEdits
model: sonnet
```

### Fast Explorer

```yaml
tools: Read, Grep, Glob
permissionMode: plan
model: haiku
```

### Test Generator

```yaml
tools: Read, Write, Grep, Glob, Bash
permissionMode: acceptEdits
model: sonnet
```

---

## Next Steps

1. Copy this template
2. Fill in your agent details
3. Save to `.claude/agents/your-agent-name.md`
4. Test the agent
5. Iterate based on results
6. Share with team if valuable

For more examples, see: [../../examples/04-agents/](../../examples/04-agents/)
