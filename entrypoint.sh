#!/bin/bash
set -e

# execute bash if given
if [ $# -eq 1 ] && [ "$@" = "bash" ]; then
  exec "$@"
fi

if [ -f "$JOTTA_TOKEN_FILE" ]; then
  JOTTA_TOKEN=$(cat "$JOTTA_TOKEN_FILE")
fi

if [ -z "$JOTTA_TOKEN" ]; then
  echo "Error: Environment variable \$JOTTA_TOKEN or \$JOTTA_TOKEN_FILE is not set."
  exit 1
fi

if [ -z "$JOTTA_DEVICE" ]; then
  echo "Error: Environment variable \$JOTTA_DEVICE is not set."
  exit 1
fi

mkdir -p /data/jottad
ln -sfn /data/jottad /root/.jottad
mkdir -p /root/.config/jotta-cli
mkdir -p /data/jotta-cli
ln -sfn /data/jotta-cli /root/.config/jotta-cli

# start the service
/usr/bin/run_jottad &

# wait for service to fully start
sleep 5

# Exit on error no longer needed. Also, it would prevent detecting jotta-cli status
set +e

echo -n "Wait jottad to start for $STARTUP_TIMEOUT seconds. "
# inspired by https://github.com/Eficode/wait-for
while :; do
  timeout 1 jotta-cli status >/dev/null 2>&1
  R=$?

  if [ $R -eq 0 ]; then
    echo "Jotta started."
    break
  fi

  if [ $R -ne 0 ]; then
    if [[ "$(timeout 1 jotta-cli status 2>&1)" =~ "Found remote device that matches this machine" ]]; then
      echo -n "..found matching device name.."
      /usr/bin/expect -c "
      set timeout 1
      spawn jotta-cli status
      expect \"Do you want to re-use this device? (yes/no): \" {send \"yes\n\"}
      expect eof
      "

    elif [[ "$(timeout 1 jotta-cli status 2>&1)" =~ "Error: The session has been revoked." ]]; then
      echo -n "Session expired. Logging out."
      /usr/bin/expect -c "
      set timeout 20
      spawn jotta-cli logout
      expect \"Backup will stop. Continue?(y/n): \" {send \"y\n\"}
      expect eof
      "

      echo -n "Logging in again."
      # Login user
      /usr/bin/expect -c "
      set timeout 20
      spawn jotta-cli login
      expect \"accept license (yes/no): \" {send \"yes\n\"}
      expect \"Personal login token: \" {send \"$JOTTA_TOKEN\n\"}
      expect \"Do you want to re-use this device? (yes/no): \" {send \"yes\n\"}
      expect eof
      # TODO: Jotta may return "Found remote device that matches this machine", where a yes/no answer could be given automatically
      "

    elif [[ "$(timeout 1 jotta-cli status 2>&1)" =~ "Not logged in" ]]; then
      echo -n "First time login. Logging in."

      # Login user
      /usr/bin/expect -c "
      set timeout 20
      spawn jotta-cli login
      expect \"accept license (yes/no): \" {send \"yes\n\"}
      expect \"Personal login token: \" {send \"$JOTTA_TOKEN\n\"}
      expect \"Devicename*: \" {send \"$JOTTA_DEVICE\n\"}
      expect eof
      # TODO: Jotta may return "Found remote device that matches this machine", where a yes/no answer could be given automatically
      "
    fi
  fi

  if [ "$STARTUP_TIMEOUT" -le 0 ]; then
    echo "waited for too long to start ($STARTUP_TIMEOUT seconds)"
    echo "ERROR: Not able to determine why Jotta cannot start:"
    jotta-cli status
    exit 1
    break
  fi

  STARTUP_TIMEOUT=$((STARTUP_TIMEOUT - 1))
  echo -n ".$STARTUP_TIMEOUT."
  sleep 1
done

remove_ignores() {
  local output
  local trimmed_entries

  # Capture output of the ignores list command, it pipes to stderr for some reason
  output=$(jotta-cli ignores list 2>&1 >/dev/null)

  # Extract lines starting with " > ", trim them, and remove duplicates
  trimmed_entries=$(echo "$output" | grep -o ' > .*' | sed 's/^ > //g' | sort -u)

  # Loop through each trimmed entry and execute your desired command
  while IFS= read -r entry; do
    echo "Removing ignore pattern: $entry"
    jotta-cli ignores rem --pattern $entry
  done <<<"$trimmed_entries"
}

add_ignores() {
  for i in ${GLOBAL_IGNORE//,/ }; do
    echo "Adding ignore pattern: $i"
    jotta-cli ignores add --pattern $i
  done
}

add_backups() {
  echo "Adding backups"
  for dir in /backup/*; do
    if [ -d "${dir}" ]; then
      set +e
      jotta-cli add "/$dir"
      set -e
    fi
  done
}

# Because we have no good way of removing stuff from the GLOBAL_IGNORE list,
# we remove all current ignored entries and re-add them using the GLOBAL_IGNORE list.
# That way we should just be left with stuff we actually want to ignore.
jotta-cli ignores use-version-2
remove_ignores
add_ignores

add_backups

echo "Setting scan interval"
jotta-cli config set scaninterval $JOTTA_SCANINTERVAL

jotta-cli tail &

R=0
while [[ $R -eq 0 ]]; do
  sleep 15
  jotta-cli status >/dev/null 2>&1
  R=$?
done

echo "Exiting:"
jotta-cli status
exit 1
