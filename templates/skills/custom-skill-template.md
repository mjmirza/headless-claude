# Custom Skill Template

Use this template to create reusable skills that Claude can automatically invoke based on context.

## File Location

Save as: `.claude/skills/your-skill-name/SKILL.md`

Supporting files can be added in the same directory.

---

## Template

```markdown
---
name: your-skill-name
description: Detailed description of what this skill does and when Claude should use it. Include specific keywords and use cases that would trigger this skill. Be very specific to help Claude identify when to use this skill. Maximum 1024 characters.
allowed-tools: Read, Grep, Glob  # Optional: Restrict tools to these only
---

# Skill Name

Clear explanation of what this skill provides.

## Purpose

What capability does this skill add? What problems does it solve?

## When to Use

Specific scenarios when this skill should be activated:

- Scenario 1
- Scenario 2
- Scenario 3

## Capabilities

What can this skill do?

1. Primary capability
2. Secondary capability
3. Additional features

## Process

Step-by-step process this skill follows:

### Step 1: [Phase Name]

Detailed instructions for this step.

### Step 2: [Phase Name]

Detailed instructions for this step.

### Step 3: [Phase Name]

Detailed instructions for this step.

## Tool Usage

Guidelines for using available tools:

- **Read**: When to read files and what to look for
- **Grep**: Search patterns to use
- **Glob**: File discovery strategies
- **Other tools**: How to use them

## Output Format

Define the expected output structure:

```
### [Section Title]

**Field**: Value
**Field**: Value

[Content]

### [Section Title]

[Content]
```

## Supporting Files

If you have supporting files in this skill directory, reference them:

- `examples/example1.js`: Example usage pattern
- `templates/output-template.md`: Output format template
- `scripts/helper.sh`: Helper utility for specific task

## Best Practices

Guidelines for using this skill effectively:

1. Best practice 1
2. Best practice 2
3. Best practice 3

## Examples

### Example 1: [Use Case Title]

**Input**: Description of input
**Process**: What the skill does
**Output**: Expected output format

### Example 2: [Use Case Title]

[Similar structure]

## Limitations

What this skill cannot or should not do:

- Limitation 1
- Limitation 2

## Related Skills

Other skills that complement or relate to this one:

- **skill-name**: How they relate
```

---

## Skill Directory Structure

```
.claude/skills/your-skill-name/
├── SKILL.md                    # Required: Main skill definition
├── README.md                   # Optional: Documentation
├── examples/                   # Optional: Example files
│   ├── example1.js
│   └── example2.py
├── templates/                  # Optional: Output templates
│   ├── report-template.md
│   └── code-template.js
├── scripts/                    # Optional: Helper scripts
│   └── helper.sh
└── docs/                       # Optional: Additional docs
    └── methodology.md
```

---

## Complete Example: SQL Query Validator

```markdown
---
name: sql-query-validator
description: Validates SQL queries for syntax errors, security issues like SQL injection, performance problems, and best practices. Automatically activates when reviewing SQL code, database queries, ORM usage, or when analyzing database-related code.
allowed-tools: Read, Grep, Glob
---

# SQL Query Validator

Validates SQL queries for correctness, security, and performance.

## Purpose

Automatically analyze SQL queries to identify:
- Syntax errors
- SQL injection vulnerabilities
- Performance issues
- Best practice violations

## When to Use

This skill activates when:
- Reviewing code containing SQL queries
- Analyzing ORM-generated queries
- Checking database migration files
- Auditing data access layers

## Validation Checklist

### Security

- [ ] All user inputs are parameterized (no string concatenation)
- [ ] No dynamic SQL construction from untrusted input
- [ ] Proper escaping where parameterization impossible
- [ ] Least privilege principle (appropriate permissions)

### Performance

- [ ] SELECT specific columns (not SELECT *)
- [ ] WHERE clauses use indexed columns
- [ ] JOINs are necessary and efficient
- [ ] No N+1 query patterns
- [ ] LIMIT clauses for large result sets

### Best Practices

- [ ] Consistent formatting and style
- [ ] Meaningful aliases
- [ ] Appropriate data types
- [ ] No DISTINCT unless necessary
- [ ] Transaction boundaries appropriate

## Process

### Step 1: Query Discovery

Search for SQL queries using patterns:
- Raw SQL strings
- ORM method calls (`.query()`, `.execute()`)
- Query builder patterns

### Step 2: Security Analysis

For each query:
1. Check for string concatenation with user input
2. Verify parameterization
3. Look for dynamic SQL construction
4. Flag potential injection points

### Step 3: Performance Review

Analyze:
1. Column selection (avoid SELECT *)
2. WHERE clause efficiency
3. JOIN usage
4. Index utilization potential

### Step 4: Reporting

Generate findings report with:
- Severity (Critical/High/Medium/Low)
- Location (file and line number)
- Issue description
- Recommended fix
- Code examples

## Output Format

### SQL Query Validation Report

#### Query: [Description]
**Location**: `file.js:line`
**Severity**: Critical/High/Medium/Low

**Current Query**:
```sql
[query code]
```

**Issues**:
1. [Issue description]
   - **Risk**: [What could happen]
   - **Recommendation**: [How to fix]

**Secure Version**:
```sql
[fixed query]
```

---

## Examples

See `examples/` directory:
- `examples/sql-injection.js`: Vulnerable vs secure queries
- `examples/n-plus-one.js`: N+1 problem demonstration
- `examples/performance.sql`: Query optimization examples

## Supporting Files

- `examples/sql-injection.js`: SQL injection patterns
- `examples/performance.sql`: Performance anti-patterns
- `templates/report-template.md`: Validation report template

## Best Practices

1. Always use parameterized queries
2. Never concatenate user input into SQL
3. Use specific column selection
4. Index frequently queried columns
5. Use EXPLAIN to verify query plans

## Limitations

- Cannot validate database-specific syntax extensions
- Cannot determine actual index availability without database access
- Performance estimates are based on static analysis only
```

---

## Example Supporting Files

### examples/sql-injection.js

```javascript
// BAD: SQL Injection Vulnerable
function getUserBad(username) {
  const query = `SELECT * FROM users WHERE username = '${username}'`;
  return db.execute(query);  // DANGEROUS!
}

// GOOD: Parameterized Query
function getUserGood(username) {
  const query = 'SELECT id, username, email FROM users WHERE username = ?';
  return db.execute(query, [username]);  // Safe
}

// BAD: Dynamic SQL
function searchUsers(filters) {
  let query = 'SELECT * FROM users WHERE 1=1';
  for (const [key, value] of Object.entries(filters)) {
    query += ` AND ${key} = '${value}'`;  // Injection risk!
  }
  return db.execute(query);
}

// GOOD: Safe Dynamic SQL
function searchUsersGood(filters) {
  const allowedColumns = ['username', 'email', 'status'];
  const conditions = [];
  const values = [];

  for (const [key, value] of Object.entries(filters)) {
    if (allowedColumns.includes(key)) {
      conditions.push(`${key} = ?`);
      values.push(value);
    }
  }

  const query = `SELECT id, username, email FROM users WHERE ${conditions.join(' AND ')}`;
  return db.execute(query, values);
}
```

### templates/report-template.md

```markdown
# SQL Validation Report

**Project**: {{PROJECT_NAME}}
**Date**: {{DATE}}
**Total Queries Analyzed**: {{TOTAL_QUERIES}}

---

## Summary

- **Critical Issues**: {{CRITICAL_COUNT}}
- **High Priority**: {{HIGH_COUNT}}
- **Medium Priority**: {{MEDIUM_COUNT}}
- **Low Priority**: {{LOW_COUNT}}

---

## Critical Issues 🔴

### Issue 1: SQL Injection Vulnerability

**Location**: `{{FILE}}:{{LINE}}`

**Vulnerable Query**:
```sql
{{VULNERABLE_QUERY}}
```

**Risk**: Attacker could execute arbitrary SQL commands

**Fix**:
```sql
{{FIXED_QUERY}}
```

---

## Recommendations

1. {{RECOMMENDATION_1}}
2. {{RECOMMENDATION_2}}
3. {{RECOMMENDATION_3}}
```

---

## Tips for Effective Skills

### 1. Descriptive Name & Description

```markdown
# ✓ Good
name: jwt-security-validator
description: Validates JWT token implementation for security issues including signature verification, expiration handling, algorithm security, and claim validation. Use when reviewing authentication code, JWT libraries, or token handling logic.

# ❌ Bad
name: validator
description: Validates code
```

### 2. Specific Trigger Keywords

Include keywords in description that match common use cases:
- "when reviewing authentication"
- "when analyzing database queries"
- "when checking API endpoints"
- "when auditing security"

### 3. Clear Process

Define step-by-step what to do so Claude can execute the skill consistently.

### 4. Tool Restriction

For security-sensitive skills, restrict to read-only tools:

```yaml
allowed-tools: Read, Grep, Glob
```

### 5. Supporting Files

Use supporting files to provide examples and templates:

```
skill-name/
├── SKILL.md
├── examples/
│   ├── good-example.js
│   └── bad-example.js
└── templates/
    └── output.md
```

---

## Testing Your Skill

```bash
# 1. Create skill directory and file
mkdir -p .claude/skills/test-skill
cat > .claude/skills/test-skill/SKILL.md <<'EOF'
[Your skill definition]
EOF

# 2. Ask Claude to discover skills
claude -p "What skills are available?"

# 3. Test activation with relevant query
claude -p "Check for SQL injection in src/db/queries.js"
# Your SQL validation skill should activate automatically

# 4. Verify with debug mode
claude -p "Check SQL queries" --debug all
```

---

## Skill vs Agent vs Command

| Feature | Skill | Agent | Slash Command |
|---------|-------|-------|---------------|
| Invocation | Automatic (by Claude) | Explicit or automatic | Manual (by user) |
| Scope | Single capability | Complex multi-step | Custom prompt |
| Tools | Can restrict | Can restrict | Full access |
| Context | Current conversation | Isolated | New conversation |
| Best for | Repetitive patterns | Specialized tasks | User workflows |

**Use skills when:**
- You have repetitive analysis patterns
- Claude should automatically recognize when to use it
- The capability is self-contained
- You want to share expertise with team

---

## Sharing Skills

### Team Sharing (Project-Level)

```bash
# 1. Create in project
mkdir -p .claude/skills/team-skill
# ... create SKILL.md ...

# 2. Commit to git
git add .claude/skills/team-skill/
git commit -m "feat: add team-skill"
git push

# 3. Team members auto-load on pull
```

### Personal (User-Level)

```bash
# Create in home directory
mkdir -p ~/.claude/skills/personal-skill
# Available across all projects
```

---

## Common Skill Patterns

### Code Analysis Skill

```yaml
name: pattern-analyzer
description: Analyzes code patterns...
allowed-tools: Read, Grep, Glob
```

### Code Generation Skill

```yaml
name: test-generator
description: Generates test cases...
allowed-tools: Read, Write, Grep, Glob
```

### Security Audit Skill

```yaml
name: security-scanner
description: Scans for vulnerabilities...
allowed-tools: Read, Grep, Glob
```

---

## Next Steps

1. Copy this template
2. Customize for your use case
3. Create supporting files (examples, templates)
4. Test skill activation
5. Share with team if valuable

For more examples, see: [../../examples/05-skills/](../../examples/05-skills/)
