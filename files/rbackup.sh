#!/bin/bash

set -eu

## Logging functions

function prepare_date() {
  date "$@"
}

function log() {
  if [ -n "${LOG_FILE}" ]; then
     echo "$(prepare_date +%F_%H:%M:%S): ${*}" >> "${LOG_FILE}"
  else
     echo "$(prepare_date +%F_%H:%M:%S): ${*}"
  fi
}

function loginfo() {
  log "INFO: ${*}"
}

# Only used if -v --verbose is passed in
function logverbose() {
  if ${VERBOSE}; then
    log "DEBUG: ${*}"
  fi
}

# Pass errors to stderr.
function logerror() {
  log "ERROR: ${*}" >&2
  let ERROR_COUNT++
}

### Arguments validation

function validate() {
  if [ -z "${RSYNC}" ]; then
    logerror "Cannot find rsync utility please make sure it is in the PATH"
    exit 1
  fi

  # # Remote source should contain @
  # # e.g. foo@server.com:/path
  # if [ "${REMOTE_SOURCE/@}" == "${REMOTE_SOURCE}" ]; then
  #   logerror "Remote source $REMOTE_SOURCE does not contain a SSH username"
  #   exit 1
  # fi

  # # Remote source should contain :
  # # e.g. foo@server.com:/path
  # if [ "${REMOTE_SOURCE/:}" == "${REMOTE_SOURCE}" ]; then
  #   logerror "Remote source $REMOTE_SOURCE does not contain a valid path"
  #   exit 1
  # fi
  if [ -z "${REMOTE_SOURCE}" ]; then
    logerror "Remote source (-s) is not set"
    exit 1
  fi

  if [ -z "${LOCAL_DESTINATION}" ]; then
    logerror "Local destination (-d) is not set"
    exit 1
  fi

  if [ ! -w "${LOCAL_DESTINATION}" ]; then
    logerror "Destination $LOCAL_DESTINATION does exist or is not writable"
    exit 1    
  fi

  re='^[0-9]+$'
  if ! [[ $KEEP =~ $re ]] ; then
    logerror "Provided keep count ($KEEP) is not a number"
  fi
}

## Backup

function backup() {
  DATE=$(date "+%Y-%m-%dT%H:%M:%S")
  loginfo "Creating backup ${DATE} in ${LOCAL_DESTINATION}"

  RSYNC_OPTS="-a ${RSYNC_COMPRESS} ${VERBOSE_RSYNC}"

  # Sets dry run if needed
  $DRY_RUN && RSYNC_OPTS="${RSYNC_OPTS} ${RSYNC_COMPRESS} -n"

  logverbose "Executing ${RSYNC} ${RSYNC_OPTS} --link-dest ${LOCAL_DESTINATION}/current/ ${REMOTE_SOURCE} ${LOCAL_DESTINATION}/${DATE}/"
  # We check if this is the first backup and skip link-dest
  if [ ! -L "${LOCAL_DESTINATION}/current" ]; then
    loginfo "First backup - using full mode"
    # shellcheck disable=SC2086
    ${RSYNC} ${RSYNC_OPTS} ${REMOTE_SOURCE} "${LOCAL_DESTINATION}/${DATE}/"
  else
    loginfo "Diff backup - using link-dest"
    # shellcheck disable=SC2086
    ${RSYNC} ${RSYNC_OPTS} --link-dest "${LOCAL_DESTINATION}/current/" ${REMOTE_SOURCE} "${LOCAL_DESTINATION}/${DATE}/"
  fi

  sync

  logverbose "Symlinking ${LOCAL_DESTINATION}/${DATE}/ to ${LOCAL_DESTINATION}/current/"
  if ! $DRY_RUN; then
    rm -f "${LOCAL_DESTINATION}/current"
    ln -s "${LOCAL_DESTINATION}/${DATE}" "${LOCAL_DESTINATION}/current"
  fi
}

# Purge old backups
function purge() {
  if [ "$KEEP" -eq 0 ]; then
    loginfo "No backups will be purged (-k 0)"
    return
  fi

  # Remove older backups for mysqldump
  # COUNT=$(( $(ls -t1 "${LOCAL_DESTINATION}/" | grep -v current -c) - $KEEP ))

  shopt -s nullglob
  file_arr=(${LOCAL_DESTINATION}/*)
  CURRENT="${#file_arr[@]}"

  # Remove "current" symlink and requested keep so we end up with count of directories to remove
  COUNT=$((CURRENT - 1 - KEEP))

  if [ $COUNT -gt 0 ]; then
    loginfo "Erasing $COUNT old backups, keeping ${KEEP}"
    # shellcheck disable=SC2012
    for i in $(ls "${LOCAL_DESTINATION}/" | head -$COUNT); do
      loginfo "Erasing ${i}"
      ${DRY_RUN} || rm  -rf "${LOCAL_DESTINATION:?}/${i:?}"
    done
  else
    loginfo "No backup to purge ($((CURRENT - 1 )) present, ${KEEP} to keep)"
  fi
}

# Parse arguments

function parse() {
  DRY_RUN=false
  ERROR_COUNT=0
  KEEP=0                            # keep everything by default
  LOCAL_DESTINATION=""
  LOG_FILE=""
  REMOTE_SOURCE=""
  RSYNC=$(which rsync 2> /dev/null) # find rsync
  RSYNC_COMPRESS=""                 # do not compress by default
  VERBOSE=false                     # prints detailed information
  VERBOSE_RSYNC=""                  # add more detail to rsync when verbose mode is active

  for arg in "$@"
  do
    shift
    case "$arg" in

      "--purge")       set -- "$@" "-p" ;;
      "--source")      set -- "$@" "-s" ;;
      "--destination") set -- "$@" "-d" ;;
      "--verbose")     set -- "$@" "-v" ;;
      "--Verbose")     set -- "$@" "-V" ;;
      "--log")         set -- "$@" "-l" ;;
      "--dry-run")     set -- "$@" "-n" ;;
      "--keep")        set -- "$@" "-k" ;;
      "--compress")    set -- "$@" "-c" ;;
      *)               set -- "$@" "$arg"

    esac
  done

  while getopts 'p:s:d:hvl:nh:k:Vc' OPTION
  do
    case $OPTION in
      k) 
        KEEP="${OPTARG}"
        ;;
      s)
        REMOTE_SOURCE="${OPTARG}"
        ;;
      l)
        LOG_FILE="${OPTARG}"
        ;;      
      d)
        LOCAL_DESTINATION="${OPTARG}"
        ;;
      n)
        DRY_RUN=true
        ;;
      v)
        VERBOSE=true
        ;;
      V)
        VERBOSE_RSYNC="-v"
        ;;
      c)
        RSYNC_COMPRESS="-z"
        ;;
      h)  
        help
        exit 0
        ;;
    esac
  done
}

parse "$@"
validate
backup
purge

loginfo "Backup completed with ${ERROR_COUNT} errors"
