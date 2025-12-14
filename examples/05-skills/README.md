# Skills Framework Examples

Comprehensive guide to creating, managing, and using Agent Skills in headless Claude Code for modular, reusable capabilities.

## Table of Contents

1. [Understanding Skills](#understanding-skills)
2. [Skill Structure](#skill-structure)
3. [Creating Custom Skills](#creating-custom-skills)
4. [Advanced Skill Patterns](#advanced-skill-patterns)
5. [Skill Integration with Agents](#skill-integration-with-agents)
6. [Best Practices](#best-practices)

---

## Understanding Skills

### What Are Skills?

Skills are **model-invoked** capabilities that Claude automatically activates based on context. Unlike slash commands (user-invoked), skills are:

- **Autonomous**: Claude decides when to use them
- **Modular**: Each skill is self-contained
- **Reusable**: Share across projects and teams
- **Context-aware**: Activated based on description matching

### Skills vs Commands vs Agents

| Feature | Skills | Slash Commands | Sub-Agents |
|---------|--------|----------------|------------|
| **Invocation** | Automatic (by Claude) | Manual (by user) | Explicit or automatic |
| **Scope** | Single capability | Custom prompt | Complex multi-step |
| **Context** | Current conversation | New conversation | Isolated context |
| **Tools** | Can restrict | Full access | Configurable |

### Skill Locations

1. **Personal Skills**: `~/.claude/skills/`
   - Available across all projects
   - Experimental features
   - Personal workflows

2. **Project Skills**: `.claude/skills/`
   - Shared via git
   - Team conventions
   - Project-specific expertise

---

## Skill Structure

### Directory Layout

```
.claude/skills/
├── api-security-check/
│   ├── SKILL.md                    # Required: Skill definition
│   ├── owasp-checklist.md          # Supporting docs
│   ├── examples/
│   │   ├── jwt-validation.js
│   │   └── sql-injection-test.js
│   └── templates/
│       └── security-report.md
├── database-optimizer/
│   ├── SKILL.md
│   ├── query-patterns.md
│   └── scripts/
│       └── analyze-indexes.sql
└── code-reviewer/
    ├── SKILL.md
    └── review-checklist.md
```

### SKILL.md Format

```markdown
---
name: skill-name
description: What the skill does and when Claude should use it (max 1024 chars)
allowed-tools: Read, Grep, Glob  # Optional: restrict tool access
---

# Skill Implementation

Detailed instructions for Claude on how to execute this skill.

## Supporting Files

Reference other files in the skill directory:
- See examples/example.js for usage patterns
- Check templates/template.md for output format
```

---

## Creating Custom Skills

### Example 1: API Security Checker

```bash
mkdir -p .claude/skills/api-security-check/examples

cat > .claude/skills/api-security-check/SKILL.md <<'EOF'
---
name: api-security-check
description: Automatically performs comprehensive security analysis of REST API endpoints including authentication, authorization, input validation, and OWASP Top 10 vulnerabilities. Use when reviewing API code, endpoints, or authentication mechanisms.
allowed-tools: Read, Grep, Glob
---

# API Security Check Skill

Perform comprehensive security analysis of REST API endpoints.

## Analysis Framework

### 1. Authentication Review

Check for:
- Proper JWT validation (signature, expiration, claims)
- Secure session management
- Password hashing (bcrypt, argon2)
- API key handling
- OAuth2 implementation

### 2. Authorization Review

Verify:
- Role-based access control (RBAC)
- Resource ownership validation
- Principle of least privilege
- Insecure direct object references (IDOR)

### 3. Input Validation

Examine:
- SQL injection vectors
- NoSQL injection
- XSS (Cross-Site Scripting)
- Command injection
- Path traversal
- XXE (XML External Entities)

### 4. Data Protection

Assess:
- Sensitive data exposure
- Encryption in transit (HTTPS)
- Encryption at rest
- Secure headers (HSTS, CSP, etc.)

### 5. Rate Limiting

Check for:
- Request rate limiting
- Account lockout mechanisms
- Brute force protection

## Process

1. **Discovery**: Use Grep to find all API endpoint definitions
   ```bash
   Search for: @app.route, @Get, @Post, @Put, @Delete, router.get, router.post
   ```

2. **Analysis**: For each endpoint, check security controls

3. **Categorization**: Group findings by severity:
   - Critical: Direct exploitation possible
   - High: Requires minimal preconditions
   - Medium: Requires specific conditions
   - Low: Informational

4. **Reporting**: Use security-report.md template

## Output Format

### Security Finding: [Endpoint Name]

**Endpoint**: `METHOD /path`
**Severity**: Critical/High/Medium/Low
**Category**: [OWASP category]

**Description**: Detailed explanation of the vulnerability

**Vulnerable Code**:
```language
[code snippet with line numbers]
```

**Proof of Concept**:
```bash
[demonstration of exploit]
```

**Impact**: What an attacker could achieve

**Remediation**:
```language
[fixed code example]
```

**References**:
- OWASP: [link]
- CWE: [link]

## Examples

See examples/ directory for:
- JWT validation patterns (examples/jwt-validation.js)
- SQL injection tests (examples/sql-injection-test.js)
EOF

# Create supporting example
cat > .claude/skills/api-security-check/examples/jwt-validation.js <<'EOF'
// Example: Proper JWT Validation

const jwt = require('jsonwebtoken');

// BAD: No signature verification
function badJwtValidation(token) {
  return jwt.decode(token); // Dangerous!
}

// GOOD: Proper validation
function goodJwtValidation(token, secret) {
  try {
    const decoded = jwt.verify(token, secret, {
      algorithms: ['HS256'], // Whitelist allowed algorithms
      maxAge: '1h',          // Token expiration
      issuer: 'myapp.com',   // Verify issuer
      audience: 'api.myapp.com' // Verify audience
    });

    // Additional checks
    if (!decoded.userId) {
      throw new Error('Missing userId claim');
    }

    return decoded;
  } catch (err) {
    // Handle verification errors
    throw new Error('Invalid token: ' + err.message);
  }
}
EOF

# Use the skill
claude -p "Review the authentication endpoints in src/api/auth.js for security vulnerabilities"
# Skill will automatically activate when Claude sees it's relevant
```

### Example 2: Database Query Optimizer

```bash
mkdir -p .claude/skills/database-optimizer/{scripts,examples}

cat > .claude/skills/database-optimizer/SKILL.md <<'EOF'
---
name: database-optimizer
description: Analyzes database queries for performance issues, missing indexes, N+1 problems, and optimization opportunities. Automatically activates when reviewing database code, ORM usage, or performance issues.
allowed-tools: Read, Grep, Glob, Bash
---

# Database Query Optimizer Skill

Optimize database queries and data access patterns.

## Optimization Areas

### 1. Query Performance

Identify:
- SELECT * (fetch only needed columns)
- Missing WHERE clauses on large tables
- LIKE queries without leading wildcard
- Subqueries that could be JOINs
- Unnecessary DISTINCT
- Functions in WHERE clauses (prevents index usage)

### 2. Indexing Strategy

Check for:
- Missing indexes on foreign keys
- Missing indexes on frequently queried columns
- Unused indexes (overhead)
- Composite index opportunities
- Index column order optimization

### 3. N+1 Query Problems

Detect:
- Loops with database queries inside
- ORM lazy loading in iterations
- Missing eager loading / JOIN strategies

### 4. Connection Management

Review:
- Connection pooling configuration
- Connection leak risks
- Transaction scope
- Long-running transactions

### 5. Data Type Optimization

Examine:
- Appropriate data types for columns
- VARCHAR length optimization
- ENUM vs foreign key tables
- JSON column usage appropriateness

## Analysis Process

1. **Find Queries**: Search for ORM methods and raw SQL
   ```bash
   Patterns: .find, .query, .execute, SELECT, INSERT, UPDATE, DELETE
   ```

2. **Analyze Patterns**: For each query, check:
   - Execution frequency
   - Potential table size
   - Index availability
   - JOIN efficiency

3. **Benchmark**: Provide EXPLAIN plan interpretation

4. **Recommend**: Suggest concrete improvements

## Output Format

### Query Optimization: [Query Description]

**Location**: `file.js:line`

**Current Query**:
```sql
[current query with parameters]
```

**Issues**:
1. [Issue description with impact estimation]
2. [Issue description]

**Optimized Query**:
```sql
[improved query]
```

**Required Index**:
```sql
CREATE INDEX idx_name ON table(column1, column2);
```

**Performance Impact**:
- Current: ~X ms (estimated)
- Optimized: ~Y ms (estimated)
- Improvement: Z%

**Implementation Notes**:
[Any caveats or considerations]

## Tools

Use `scripts/analyze-indexes.sql` to generate index analysis queries.

## Examples

See examples/ for common optimization patterns.
EOF

# Supporting script
cat > .claude/skills/database-optimizer/scripts/analyze-indexes.sql <<'EOF'
-- Analyze index usage and recommendations

-- Find missing indexes (PostgreSQL)
SELECT
  schemaname,
  tablename,
  attname,
  n_distinct,
  correlation
FROM pg_stats
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
  AND n_distinct > 100  -- High cardinality columns
  AND correlation < 0.5  -- Random access pattern
ORDER BY n_distinct DESC;

-- Find unused indexes
SELECT
  schemaname,
  tablename,
  indexname,
  idx_scan,
  idx_tup_read,
  idx_tup_fetch
FROM pg_stat_user_indexes
WHERE idx_scan = 0  -- Never used
  AND indexrelname NOT LIKE 'pg_%'
ORDER BY pg_relation_size(indexrelid) DESC;

-- Find duplicate indexes
SELECT
  a.indrelid::regclass AS table,
  a.indexrelid::regclass AS index1,
  b.indexrelid::regclass AS index2,
  a.indkey AS columns
FROM pg_index a
JOIN pg_index b ON a.indrelid = b.indrelid
  AND a.indkey = b.indkey
  AND a.indexrelid > b.indexrelid;
EOF

# Use the skill
claude -p "Analyze database queries in src/models/ for performance optimization opportunities"
```

### Example 3: Code Review Assistant

```bash
mkdir -p .claude/skills/code-reviewer/templates

cat > .claude/skills/code-reviewer/SKILL.md <<'EOF'
---
name: code-reviewer
description: Performs comprehensive code reviews checking for code quality, best practices, security issues, performance problems, and maintainability. Automatically activates when asked to review code or pull requests.
allowed-tools: Read, Grep, Glob
---

# Code Review Assistant Skill

Perform thorough code reviews following industry best practices.

## Review Checklist

### 1. Code Quality

- [ ] Clear, descriptive variable and function names
- [ ] Functions are small and single-purpose
- [ ] No code duplication (DRY principle)
- [ ] Proper error handling
- [ ] Consistent code style
- [ ] Meaningful comments for complex logic
- [ ] No commented-out code
- [ ] No TODO comments without tickets

### 2. Security

- [ ] Input validation on all user inputs
- [ ] Output encoding to prevent XSS
- [ ] SQL parameterization (no string concatenation)
- [ ] Secrets not hardcoded
- [ ] Secure random number generation
- [ ] Proper authentication and authorization
- [ ] No sensitive data in logs

### 3. Performance

- [ ] Efficient algorithms (time complexity)
- [ ] Minimal memory allocation
- [ ] Database queries optimized
- [ ] Caching where appropriate
- [ ] No premature optimization
- [ ] Resource cleanup (files, connections, etc.)

### 4. Testing

- [ ] Unit tests for new functionality
- [ ] Edge cases covered
- [ ] Error cases tested
- [ ] Integration tests if needed
- [ ] Test names are descriptive
- [ ] Tests are independent
- [ ] Mocks used appropriately

### 5. Documentation

- [ ] Public API documented
- [ ] Complex logic explained
- [ ] README updated if needed
- [ ] Breaking changes noted
- [ ] Examples provided for new features

### 6. Architecture

- [ ] Follows project patterns
- [ ] Proper separation of concerns
- [ ] SOLID principles followed
- [ ] Dependencies are necessary
- [ ] No circular dependencies
- [ ] Appropriate design patterns used

## Review Process

1. **Understand**: Read code to understand intent
2. **Check**: Apply review checklist
3. **Prioritize**: Categorize findings:
   - **Blocker**: Must fix before merge
   - **Critical**: Should fix before merge
   - **Important**: Fix soon after merge
   - **Minor**: Nice to have
   - **Nitpick**: Stylistic preference

4. **Suggest**: Provide specific code improvements
5. **Educate**: Explain reasoning behind feedback

## Output Format

Use templates/review-template.md for consistent reviews.

### Code Review: [Component/File Name]

**Overall Assessment**: 🟢 Approve / 🟡 Approve with comments / 🔴 Request changes

**Summary**: [Brief overview of changes and overall quality]

---

#### Blockers 🔴

1. **[Issue Title]** `file.js:42`

   **Problem**: Detailed explanation

   **Current Code**:
   ```javascript
   // problematic code
   ```

   **Suggested Fix**:
   ```javascript
   // improved code
   ```

   **Reasoning**: Why this change is necessary

---

#### Critical Issues ⚠️

[Same format as blockers]

---

#### Improvements 💡

[Same format]

---

#### Nitpicks 🔧

[Same format]

---

#### Positive Feedback 🌟

- Well-structured error handling in `file.js:100-120`
- Excellent test coverage for edge cases
- Clear, self-documenting code in `module.js`

---

**Next Steps**: [What needs to happen before merge]
EOF

# Review template
cat > .claude/skills/code-reviewer/templates/review-template.md <<'EOF'
# Code Review: {{COMPONENT_NAME}}

**Reviewer**: Claude Code Review Assistant
**Date**: {{DATE}}
**Commit/PR**: {{REFERENCE}}

## Overall Assessment

**Status**: 🟢 Approve / 🟡 Approve with comments / 🔴 Request changes

**Summary**:
[Brief overview of the changes and overall code quality]

---

## Findings

### Blockers 🔴
[Issues that must be fixed before merge]

### Critical Issues ⚠️
[Important issues that should be addressed before merge]

### Improvements 💡
[Suggestions for better code quality, can be addressed after merge]

### Nitpicks 🔧
[Minor style or preference items]

---

## Positive Feedback 🌟

[Highlight what was done well]

---

## Metrics

- **Files Changed**: {{FILES_CHANGED}}
- **Lines Added**: {{LINES_ADDED}}
- **Lines Removed**: {{LINES_REMOVED}}
- **Test Coverage**: {{COVERAGE}}%

---

## Recommendation

[Final verdict and next steps]
EOF

# Use the skill
claude -p "Review the pull request changes in src/components/UserAuth.tsx"
```

---

## Advanced Skill Patterns

### Pattern 1: Multi-File Skill with Templates

```bash
mkdir -p .claude/skills/test-generator/{templates,examples}

cat > .claude/skills/test-generator/SKILL.md <<'EOF'
---
name: test-generator
description: Automatically generates comprehensive unit tests, integration tests, and test fixtures for any code. Use when asked to create tests, improve test coverage, or generate test cases.
allowed-tools: Read, Write, Grep, Glob, Bash
---

# Test Generator Skill

Generate comprehensive, high-quality automated tests.

## Test Types

### 1. Unit Tests
- Test individual functions in isolation
- Use mocks for dependencies
- Cover edge cases and error paths
- Follow AAA pattern (Arrange, Act, Assert)

### 2. Integration Tests
- Test component interactions
- Use real or test databases
- Test API endpoints end-to-end
- Verify business workflows

### 3. Edge Case Tests
- Null/undefined inputs
- Empty arrays/objects
- Boundary values (max, min, zero)
- Invalid data types
- Concurrent operations

## Test Generation Process

1. **Analyze Code**: Understand function purpose and inputs
2. **Identify Cases**: List all scenarios to test
3. **Generate Tests**: Create test code using templates
4. **Add Fixtures**: Create necessary test data
5. **Verify**: Ensure tests are runnable

## Templates

Use templates based on testing framework:
- templates/jest-test.js
- templates/mocha-test.js
- templates/pytest-test.py

## Example Structure

```javascript
describe('FunctionName', () => {
  // Setup
  beforeEach(() => {
    // Test setup
  });

  afterEach(() => {
    // Cleanup
  });

  describe('Happy Path', () => {
    it('should [expected behavior] when [condition]', () => {
      // Arrange
      const input = ...;
      const expected = ...;

      // Act
      const result = functionName(input);

      // Assert
      expect(result).toBe(expected);
    });
  });

  describe('Edge Cases', () => {
    it('should handle null input', () => { ... });
    it('should handle empty array', () => { ... });
    it('should throw error for invalid type', () => { ... });
  });

  describe('Error Handling', () => {
    it('should throw meaningful error when [error condition]', () => { ... });
  });
});
```

## Output

Generate:
1. Test file with descriptive name
2. Test fixtures if needed
3. Mock definitions
4. Setup/teardown helpers
EOF

# Jest template
cat > .claude/skills/test-generator/templates/jest-test.js <<'EOF'
import { {{FUNCTION_NAME}} } from '../{{SOURCE_FILE}}';

describe('{{FUNCTION_NAME}}', () => {
  describe('Happy Path', () => {
    it('should {{EXPECTED_BEHAVIOR}}', () => {
      // Arrange
      const input = {{SAMPLE_INPUT}};
      const expected = {{EXPECTED_OUTPUT}};

      // Act
      const result = {{FUNCTION_NAME}}(input);

      // Assert
      expect(result).toEqual(expected);
    });
  });

  describe('Edge Cases', () => {
    it('should handle null input', () => {
      expect(() => {{FUNCTION_NAME}}(null)).toThrow();
    });

    it('should handle undefined input', () => {
      expect(() => {{FUNCTION_NAME}}(undefined)).toThrow();
    });

    it('should handle empty input', () => {
      const result = {{FUNCTION_NAME}}({{EMPTY_INPUT}});
      expect(result).toEqual({{EMPTY_OUTPUT}});
    });
  });

  describe('Error Handling', () => {
    it('should throw descriptive error for invalid input', () => {
      expect(() => {{FUNCTION_NAME}}({{INVALID_INPUT}}))
        .toThrow('{{ERROR_MESSAGE}}');
    });
  });
});
EOF

# Use the skill
claude -p "Generate comprehensive tests for src/utils/validation.ts"
```

### Pattern 2: Skill with Script Execution

```bash
mkdir -p .claude/skills/dependency-auditor/scripts

cat > .claude/skills/dependency-auditor/SKILL.md <<'EOF'
---
name: dependency-auditor
description: Audits project dependencies for security vulnerabilities, license issues, outdated packages, and supply chain risks. Use when reviewing package.json, requirements.txt, or dependency updates.
allowed-tools: Read, Grep, Bash
---

# Dependency Auditor Skill

Comprehensive dependency security and compliance auditing.

## Audit Areas

### 1. Security Vulnerabilities
- Known CVEs in dependencies
- Outdated packages with security patches
- Malicious packages

### 2. License Compliance
- Incompatible licenses (e.g., GPL in proprietary project)
- Missing license information
- License changes in updates

### 3. Supply Chain Security
- Suspicious download patterns
- Typosquatting risks
- Unmaintained packages (last update > 2 years)
- Small maintainer teams (single-person projects)

### 4. Dependency Health
- Bundle size impact
- Transitive dependency bloat
- Circular dependencies
- Deprecated packages

## Audit Process

1. **Identify Package Manager**: npm, yarn, pip, gem, etc.

2. **Run Security Audit**:
   ```bash
   npm audit --json
   yarn audit --json
   pip-audit --format json
   ```

3. **Analyze Results**: Parse and categorize findings

4. **Check Licenses**:
   ```bash
   npx license-checker --json
   ```

5. **Generate Report**: Use scripts/audit-report.sh

## Output Format

### Dependency Audit Report

**Project**: [Project Name]
**Date**: [Date]
**Package Manager**: [npm/yarn/pip/etc]

#### Executive Summary
- Total Dependencies: X
- Direct: X | Transitive: X
- Vulnerabilities: Critical: X | High: X | Medium: X | Low: X
- Outdated: X packages
- License Issues: X packages

#### Critical Vulnerabilities 🔴

1. **Package**: `package-name@version`

   **Severity**: Critical
   **CVE**: CVE-2024-XXXXX
   **Description**: [vulnerability description]

   **Affected Versions**: < X.X.X
   **Fixed Version**: X.X.X

   **Exploit Maturity**: Proof of concept exists
   **CVSS Score**: 9.8

   **Remediation**:
   ```bash
   npm update package-name@X.X.X
   ```

   **Impact**: [What this vulnerability could allow]

#### License Issues ⚖️

1. **Package**: `package-name@version`
   **License**: GPL-3.0
   **Issue**: Incompatible with proprietary project
   **Recommendation**: Find alternative or negotiate license

#### Outdated Packages 📅

[Table of outdated packages with current and latest versions]

#### Supply Chain Risks ⚠️

[Packages with potential supply chain concerns]

## Scripts

Use `scripts/generate-sbom.sh` to create Software Bill of Materials.
EOF

# Supporting script
cat > .claude/skills/dependency-auditor/scripts/generate-sbom.sh <<'#!/bin/bash
# Generate Software Bill of Materials (SBOM)

PACKAGE_MANAGER="$1"
OUTPUT_FILE="${2:-sbom.json}"

case "$PACKAGE_MANAGER" in
  npm)
    npx @cyclonedx/cyclonedx-npm --output-file "$OUTPUT_FILE"
    ;;
  pip)
    pip-audit --format cyclonedx-json --output "$OUTPUT_FILE"
    ;;
  *)
    echo "Unsupported package manager: $PACKAGE_MANAGER"
    exit 1
    ;;
esac

echo "SBOM generated: $OUTPUT_FILE"
EOF

chmod +x .claude/skills/dependency-auditor/scripts/generate-sbom.sh

# Use the skill
claude -p "Audit dependencies in package.json for security and compliance"
```

---

## Skill Integration with Agents

### Loading Skills in Agents

```bash
cat > .claude/agents/security-specialist.md <<'EOF'
---
name: security-specialist
description: Comprehensive security analysis using multiple security skills
model: sonnet
tools: Read, Grep, Glob, Bash
skills: api-security-check, dependency-auditor
permissionMode: plan
---

# Security Specialist Agent

This agent automatically loads and uses security-related skills.

When analyzing a project:

1. Use **api-security-check** skill for API endpoint analysis
2. Use **dependency-auditor** skill for dependency security
3. Combine findings into comprehensive security report

## Process

1. **Discovery**: Map application architecture
2. **API Security**: Apply api-security-check to all endpoints
3. **Dependency Audit**: Apply dependency-auditor to dependencies
4. **Configuration Review**: Check security configurations
5. **Report**: Generate unified security assessment
EOF

# Use agent with auto-loaded skills
claude -p "Use security-specialist agent to perform full security audit"
```

---

## Best Practices

### 1. Skill Naming and Description

```yaml
# GOOD: Specific, descriptive
name: jwt-token-validator
description: Validates JWT tokens checking signature, expiration, claims, and algorithm security. Use when reviewing authentication code or JWT implementations.

# BAD: Vague, generic
name: validator
description: Validates stuff
```

### 2. Tool Restriction

```yaml
# For read-only analysis skills
allowed-tools: Read, Grep, Glob

# For implementation skills
allowed-tools: Read, Write, Edit, Grep, Glob

# For diagnostic skills
allowed-tools: Read, Grep, Glob, Bash
```

### 3. Supporting Files Organization

```
skill-name/
├── SKILL.md              # Main skill definition
├── README.md             # Usage documentation
├── templates/            # Output templates
│   └── report.md
├── examples/             # Example inputs/outputs
│   ├── example1.js
│   └── example2.js
├── scripts/              # Helper scripts
│   └── helper.sh
└── docs/                 # Additional documentation
    └── methodology.md
```

### 4. Version Control

```bash
# Commit project skills
git add .claude/skills/
git commit -m "feat: add api-security-check skill"

# Document in project README
echo "## Available Skills

- **api-security-check**: API security analysis
- **database-optimizer**: Query optimization
- **code-reviewer**: Code review assistant
" >> README.md
```

### 5. Testing Skills

```bash
# Test skill activation
claude -p "Test the api-security-check skill on a sample file" \
  --allowedTools "Read"

# Verify skill is discovered
claude -p "List all available skills"

# Check skill file syntax
cat .claude/skills/skill-name/SKILL.md | head -10
```

### 6. Skill Documentation

Always include in SKILL.md:
- Clear description of what skill does
- When Claude should use it
- Examples of usage
- References to supporting files
- Expected output format

---

## Troubleshooting

### Skill Not Activating

1. **Check description specificity**:
   ```bash
   # Too vague - may not match
   description: Checks code

   # Specific - better matching
   description: Analyzes TypeScript code for type safety issues, strict mode violations, and proper type annotations. Use when reviewing .ts files or TypeScript-related code.
   ```

2. **Verify file structure**:
   ```bash
   ls -la .claude/skills/skill-name/SKILL.md
   ```

3. **Check YAML frontmatter**:
   ```bash
   head -10 .claude/skills/skill-name/SKILL.md
   # Ensure proper YAML format
   ```

### Skill Using Wrong Tools

```yaml
# Restrict tools explicitly
allowed-tools: Read, Grep, Glob
```

### Multiple Skills Conflict

Make descriptions more specific to differentiate:

```yaml
# Skill 1
description: Analyzes API security focusing on authentication and authorization

# Skill 2
description: Analyzes API performance focusing on query optimization and caching
```

---

## Next Steps

- **Remote Execution** → [../06-remote/](../06-remote/) for distributed skills
- **Pipelines** → [../07-pipelines/](../07-pipelines/) for skill workflows
- **Monitoring** → [../08-monitoring/](../08-monitoring/) for skill performance tracking
