#!/bin/bash
#--------------------------------------
# Script Name:  helper.sh
# Version:      1.4
# Authors:      akombeiz@ukaachen.de
# Date:         5 Dec 24
# Purpose:      Centralized helper functions for package maintenance tasks
#--------------------------------------

# Global Configuration
readonly MAX_RETRIES=5
readonly RETRY_INTERVAL=12
readonly SERVICE_STOP_TIMEOUT=30

# Unified Logging Functions
_log() {
  local color="$1"
  local level="$2"
  local message="$3"
  echo -e "\033[${color}m[${level}]\033[0m ${message}" >&"$([[ "$level" == "ERROR" ]] && echo 2 || echo 1)"
}

log_info()    { _log "0;34" "INFO"    "$1"; }
log_success() { _log "0;32" "SUCCESS" "$1"; }
log_warn()    { _log "1;33" "WARN"    "$1"; }
log_error()   { _log "0;31" "ERROR"   "$1"; }

connect_to_psql() {
  local timeout=$((MAX_RETRIES * RETRY_INTERVAL))
  local attempt=1
  log_info "Connecting to PostgreSQL via local UNIX socket..."
  export PSQL="sudo -u postgres psql"

  while ((attempt <= MAX_RETRIES)); do
    if systemctl is-active --quiet postgresql && eval "${PSQL} -c '\l' >/dev/null 2>&1"; then
      log_success "PostgreSQL connection established"
      return 0
    fi

    if ((attempt == MAX_RETRIES)); then
      log_error "PostgreSQL connection failed after ${timeout} seconds"
      log_error "Service status: $(systemctl is-active postgresql)"
      return 1
    fi

    log_warn "Database not ready. Retry ${attempt}/${MAX_RETRIES} in ${RETRY_INTERVAL}s"
    ((attempt++))
    sleep "${RETRY_INTERVAL}"
  done
}

check_and_start_service() {
  local service="${1}"
  local timeout=$((MAX_RETRIES * RETRY_INTERVAL))
  log_info "Initiating ${service} service..."

  if systemctl is-active --quiet "${service}"; then
    log_success "Service ${service} already running"
    return 0
  fi

  local attempt=1
  while ((attempt <= MAX_RETRIES)); do
    systemctl start "${service}"
    sleep "${RETRY_INTERVAL}"

    if systemctl is-active --quiet "${service}"; then
      log_success "Service ${service} started successfully"
      return 0
    fi

     if ((attempt == MAX_RETRIES)); then
      log_error "Failed to start service ${service} after ${timeout} seconds"
      log_error "Service status:"
      systemctl status "${service}" >&2
      return 1
    fi

    log_warn "Service not started. Retry ${attempt}/${MAX_RETRIES} in ${RETRY_INTERVAL}s"
  done
}

stop_service() {
  local service="${1}"
  log_info "Initiating shutdown of ${service}..."

  if ! systemctl is-active --quiet "${service}"; then
    log_warn "Service ${service} not running"
    return 0
  fi

  systemctl stop "${service}"
  local wait_time=0
  while systemctl is-active --quiet "${service}"; do
    if ((wait_time >= SERVICE_STOP_TIMEOUT)); then
      log_error "Forceful termination required for ${service}"
      systemctl kill "${service}"
      break
    fi
    sleep 1
    ((wait_time++))
  done

  log_success "Service ${service} stopped successfully"
}

cleanup_wildfly_deployment_markers() {
  local deploy_dir="${1:-/opt/wildfly/standalone/deployments}"
  log_info "Removing Wildfly deployment markers..."

  if [[ ! -d "${deploy_dir}" ]]; then
    log_warn "WildFly deployment directory not found: ${deploy_dir}"
    return 0
  fi

  local marker_types=(
    "*.deployed"
    "*.dodeploy"
    "*.failed"
    "*.undeployed"
    "*.swp"
  )
  find "${deploy_dir}" -type f \( \
    -name "${marker_types[0]}" -o \
    -name "${marker_types[1]}" -o \
    -name "${marker_types[2]}" -o \
    -name "${marker_types[3]}" -o \
    -name "${marker_types[4]}" \
  \) -delete

  log_success "WildFly deployment markers cleaned"
}

# Removes specified datasource files from deployment directory
# (as datasources moved to standalone.xml in V1.6)
# @param $1 Deployment directory path (optional, defaults to WildFly deployments)
# @param $2... One or more datasource names without .xml extension
remove_datasource_files() {
  local deploy_dir="${1:-/opt/wildfly/standalone/deployments}"
  shift
  local -r datasources=("$@")
  log_info "Removing datasource configuration files..."

  for ds in "${datasources[@]}"; do
    local ds_file="${deploy_dir}/${ds}.xml"
    if [[ -f "${ds_file}" ]]; then
      if rm -f "${ds_file}"; then
        log_success "Removed datasource file: ${ds}.xml"
      else
        log_error "Failed to remove datasource file: ${ds}.xml"
        return 1
      fi
    else
      log_warn "Datasource file not found: ${ds}.xml"
    fi
  done

  return 0
}
