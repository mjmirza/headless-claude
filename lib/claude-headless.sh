#!/usr/bin/env bash
#
# Claude Headless Execution Library
# Ultra-advanced shell library for headless Claude Code orchestration
#
# Author: Advanced Automation Framework
# Version: 2.0.0
# License: MIT
#

set -euo pipefail

# ============================================================================
# GLOBAL CONFIGURATION
# ============================================================================

# Default configuration
CLAUDE_USER="${CLAUDE_USER:-claudeuser}"
CLAUDE_BINARY="${CLAUDE_BINARY:-claude}"
CLAUDE_LOG_DIR="${CLAUDE_LOG_DIR:-./logs}"
CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-./config}"
CLAUDE_OUTPUT_FORMAT="${CLAUDE_OUTPUT_FORMAT:-json}"
CLAUDE_TIMEOUT="${CLAUDE_TIMEOUT:-300}"
CLAUDE_RETRY_COUNT="${CLAUDE_RETRY_COUNT:-3}"
CLAUDE_RETRY_DELAY="${CLAUDE_RETRY_DELAY:-5}"

# Color codes for output
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_MAGENTA='\033[0;35m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_RESET='\033[0m'

# Logging levels
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_ERROR=3
readonly LOG_LEVEL_FATAL=4

CURRENT_LOG_LEVEL="${LOG_LEVEL_INFO}"

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Initialize logging directory
init_logging() {
    mkdir -p "${CLAUDE_LOG_DIR}"
    mkdir -p "${CLAUDE_CONFIG_DIR}"
}

# Get timestamp for logging
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Log message with level
log_message() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(get_timestamp)

    local log_file="${CLAUDE_LOG_DIR}/claude-headless-$(date '+%Y%m%d').log"

    echo "[${timestamp}] [${level}] ${message}" | tee -a "${log_file}"
}

# Logging functions
log_debug() {
    if [[ ${CURRENT_LOG_LEVEL} -le ${LOG_LEVEL_DEBUG} ]]; then
        echo -e "${COLOR_CYAN}[DEBUG]${COLOR_RESET} $*" >&2
        log_message "DEBUG" "$*"
    fi
}

log_info() {
    if [[ ${CURRENT_LOG_LEVEL} -le ${LOG_LEVEL_INFO} ]]; then
        echo -e "${COLOR_GREEN}[INFO]${COLOR_RESET} $*" >&2
        log_message "INFO" "$*"
    fi
}

log_warn() {
    if [[ ${CURRENT_LOG_LEVEL} -le ${LOG_LEVEL_WARN} ]]; then
        echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $*" >&2
        log_message "WARN" "$*"
    fi
}

log_error() {
    if [[ ${CURRENT_LOG_LEVEL} -le ${LOG_LEVEL_ERROR} ]]; then
        echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
        log_message "ERROR" "$*"
    fi
}

log_fatal() {
    echo -e "${COLOR_RED}[FATAL]${COLOR_RESET} $*" >&2
    log_message "FATAL" "$*"
    exit 1
}

# ============================================================================
# CLAUDE EXECUTION FUNCTIONS
# ============================================================================

# Execute Claude with prompt (basic)
claude_exec() {
    local prompt="$1"
    local flags="${2:-}"

    log_info "Executing Claude with prompt: ${prompt:0:50}..."

    local cmd="su - ${CLAUDE_USER} -c '${CLAUDE_BINARY} --dangerously-skip-permissions -p \"${prompt}\" ${flags}'"

    log_debug "Command: ${cmd}"

    eval "${cmd}"
}

# Execute Claude with timeout and retry logic
claude_exec_resilient() {
    local prompt="$1"
    local flags="${2:-}"
    local timeout="${3:-$CLAUDE_TIMEOUT}"
    local retry_count="${4:-$CLAUDE_RETRY_COUNT}"

    local attempt=1

    while [[ ${attempt} -le ${retry_count} ]]; do
        log_info "Attempt ${attempt}/${retry_count}: Executing Claude..."

        if timeout "${timeout}" su - "${CLAUDE_USER}" -c "${CLAUDE_BINARY} --dangerously-skip-permissions -p \"${prompt}\" ${flags}"; then
            log_info "Execution successful on attempt ${attempt}"
            return 0
        else
            local exit_code=$?
            log_warn "Attempt ${attempt} failed with exit code ${exit_code}"

            if [[ ${attempt} -lt ${retry_count} ]]; then
                log_info "Retrying in ${CLAUDE_RETRY_DELAY} seconds..."
                sleep "${CLAUDE_RETRY_DELAY}"
            fi
        fi

        ((attempt++))
    done

    log_error "All ${retry_count} attempts failed"
    return 1
}

# Execute Claude and capture output
claude_exec_capture() {
    local prompt="$1"
    local flags="${2:-}"
    local output_file="${3:-}"

    log_info "Executing Claude with output capture..."

    local result
    if [[ -n "${output_file}" ]]; then
        result=$(su - "${CLAUDE_USER}" -c "${CLAUDE_BINARY} --dangerously-skip-permissions -p \"${prompt}\" ${flags}" 2>&1 | tee "${output_file}")
    else
        result=$(su - "${CLAUDE_USER}" -c "${CLAUDE_BINARY} --dangerously-skip-permissions -p \"${prompt}\" ${flags}" 2>&1)
    fi

    echo "${result}"
}

# Execute Claude with JSON output parsing
claude_exec_json() {
    local prompt="$1"
    local flags="${2:-}"

    log_info "Executing Claude with JSON output parsing..."

    local output
    output=$(claude_exec_capture "${prompt}" "${flags}")

    # Validate JSON
    if echo "${output}" | jq empty 2>/dev/null; then
        echo "${output}"
    else
        log_error "Output is not valid JSON"
        return 1
    fi
}

# ============================================================================
# AGENT ORCHESTRATION FUNCTIONS
# ============================================================================

# Execute sub-agent with specific task
claude_exec_subagent() {
    local subagent_type="$1"
    local task_description="$2"
    local detailed_prompt="$3"
    local model="${4:-sonnet}"

    log_info "Launching ${subagent_type} sub-agent: ${task_description}"

    local prompt="Execute the following task using a ${subagent_type} agent: ${detailed_prompt}"

    claude_exec_resilient "${prompt}" "--model ${model}"
}

# Execute multiple agents in parallel
claude_exec_parallel_agents() {
    local -n tasks=$1  # nameref to array of tasks
    local max_parallel="${2:-4}"

    log_info "Executing ${#tasks[@]} tasks in parallel (max: ${max_parallel})"

    local pids=()
    local count=0

    for task in "${tasks[@]}"; do
        # Parse task format: "type|description|prompt|model"
        IFS='|' read -r type desc prompt model <<< "${task}"

        claude_exec_subagent "${type}" "${desc}" "${prompt}" "${model}" &
        pids+=($!)

        ((count++))

        # Wait if we've reached max parallel
        if [[ ${count} -ge ${max_parallel} ]]; then
            wait "${pids[@]}"
            pids=()
            count=0
        fi
    done

    # Wait for remaining tasks
    if [[ ${#pids[@]} -gt 0 ]]; then
        wait "${pids[@]}"
    fi

    log_info "All parallel agents completed"
}

# Execute agent pipeline (sequential with data passing)
claude_exec_pipeline() {
    local -n pipeline_steps=$1  # nameref to array of pipeline steps
    local initial_input="$2"

    log_info "Executing pipeline with ${#pipeline_steps[@]} steps"

    local current_input="${initial_input}"
    local step_num=1

    for step in "${pipeline_steps[@]}"; do
        log_info "Pipeline Step ${step_num}: ${step}"

        # Execute step with previous output as input
        local prompt="${step} Input data: ${current_input}"
        current_input=$(claude_exec_capture "${prompt}")

        log_debug "Step ${step_num} output length: ${#current_input} chars"

        ((step_num++))
    done

    echo "${current_input}"
}

# ============================================================================
# SKILL EXECUTION FUNCTIONS
# ============================================================================

# Execute a skill from template
claude_exec_skill() {
    local skill_name="$1"
    local skill_params="${2:-}"
    local skill_template="${3:-templates/skills/${skill_name}.md}"

    log_info "Executing skill: ${skill_name}"

    if [[ ! -f "${skill_template}" ]]; then
        log_error "Skill template not found: ${skill_template}"
        return 1
    fi

    local skill_content
    skill_content=$(cat "${skill_template}")

    # Replace parameters in template
    if [[ -n "${skill_params}" ]]; then
        while IFS='=' read -r key value; do
            skill_content="${skill_content//\{\{${key}\}\}/${value}}"
        done <<< "${skill_params}"
    fi

    claude_exec_resilient "${skill_content}"
}

# Load and execute custom skill
claude_load_skill() {
    local skill_path="$1"
    local skill_args="${2:-}"

    log_info "Loading skill from: ${skill_path}"

    if [[ ! -f "${skill_path}" ]]; then
        log_error "Skill file not found: ${skill_path}"
        return 1
    fi

    source "${skill_path}"

    if declare -f skill_execute >/dev/null; then
        skill_execute "${skill_args}"
    else
        log_error "Skill does not define skill_execute function"
        return 1
    fi
}

# ============================================================================
# REMOTE EXECUTION FUNCTIONS
# ============================================================================

# Execute Claude on remote host via SSH
claude_exec_remote() {
    local remote_host="$1"
    local prompt="$2"
    local ssh_user="${3:-$(whoami)}"
    local ssh_key="${4:-}"

    log_info "Executing Claude on remote host: ${remote_host}"

    local ssh_opts=""
    if [[ -n "${ssh_key}" ]]; then
        ssh_opts="-i ${ssh_key}"
    fi

    # shellcheck disable=SC2029
    ssh ${ssh_opts} "${ssh_user}@${remote_host}" \
        "su - ${CLAUDE_USER} -c '${CLAUDE_BINARY} --dangerously-skip-permissions -p \"${prompt}\"'"
}

# Execute Claude on multiple remote hosts in parallel
claude_exec_remote_parallel() {
    local -n hosts=$1  # nameref to array of hosts
    local prompt="$2"
    local ssh_user="${3:-$(whoami)}"

    log_info "Executing Claude on ${#hosts[@]} remote hosts in parallel"

    local pids=()

    for host in "${hosts[@]}"; do
        claude_exec_remote "${host}" "${prompt}" "${ssh_user}" &
        pids+=($!)
    done

    wait "${pids[@]}"

    log_info "All remote executions completed"
}

# Distribute task across remote cluster
claude_exec_distributed() {
    local -n cluster_hosts=$1
    local task_prompt="$2"
    local distribution_strategy="${3:-round-robin}"  # round-robin, load-balanced, map-reduce

    log_info "Distributing task across ${#cluster_hosts[@]} hosts (strategy: ${distribution_strategy})"

    case "${distribution_strategy}" in
        round-robin)
            claude_exec_remote_parallel cluster_hosts "${task_prompt}"
            ;;
        load-balanced)
            # TODO: Implement load-based distribution
            log_warn "Load-balanced distribution not yet implemented, using round-robin"
            claude_exec_remote_parallel cluster_hosts "${task_prompt}"
            ;;
        map-reduce)
            # TODO: Implement map-reduce pattern
            log_warn "Map-reduce distribution not yet implemented, using round-robin"
            claude_exec_remote_parallel cluster_hosts "${task_prompt}"
            ;;
        *)
            log_error "Unknown distribution strategy: ${distribution_strategy}"
            return 1
            ;;
    esac
}

# ============================================================================
# MONITORING AND METRICS FUNCTIONS
# ============================================================================

# Monitor Claude execution with metrics
claude_exec_monitored() {
    local prompt="$1"
    local flags="${2:-}"
    local metrics_file="${CLAUDE_LOG_DIR}/metrics-$(date '+%Y%m%d-%H%M%S').json"

    log_info "Executing Claude with monitoring enabled"

    local start_time
    start_time=$(date +%s)

    local exit_code=0
    local output
    output=$(claude_exec_capture "${prompt}" "${flags}") || exit_code=$?

    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    local output_size=${#output}

    # Create metrics JSON
    cat > "${metrics_file}" <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "prompt_length": ${#prompt},
  "output_size": ${output_size},
  "duration_seconds": ${duration},
  "exit_code": ${exit_code},
  "success": $([ ${exit_code} -eq 0 ] && echo "true" || echo "false")
}
EOF

    log_info "Execution completed in ${duration}s (metrics: ${metrics_file})"

    echo "${output}"
    return ${exit_code}
}

# ============================================================================
# WORKFLOW AND AUTOMATION FUNCTIONS
# ============================================================================

# Execute workflow from configuration file
claude_exec_workflow() {
    local workflow_file="$1"

    log_info "Executing workflow: ${workflow_file}"

    if [[ ! -f "${workflow_file}" ]]; then
        log_error "Workflow file not found: ${workflow_file}"
        return 1
    fi

    # Parse and execute workflow (expects JSON format)
    local workflow_content
    workflow_content=$(cat "${workflow_file}")

    # Extract steps and execute
    local steps
    steps=$(echo "${workflow_content}" | jq -r '.steps[] | @base64')

    for step in ${steps}; do
        local step_data
        step_data=$(echo "${step}" | base64 -d)

        local step_name
        step_name=$(echo "${step_data}" | jq -r '.name')
        local step_prompt
        step_prompt=$(echo "${step_data}" | jq -r '.prompt')

        log_info "Workflow step: ${step_name}"
        claude_exec_resilient "${step_prompt}"
    done
}

# ============================================================================
# INITIALIZATION
# ============================================================================

init_logging

log_debug "Claude Headless Library loaded (version 2.0.0)"
