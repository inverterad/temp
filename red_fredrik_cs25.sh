#!/usr/bin/bash
#
# Fredriks script för uppgiften
# Skapar en ssh-nyckel som en backdoor (T1098.004)
# Lägger till ett cronjob som återskapar den varje dag om den inte finns (T1053.003)
# Timestomp för att dölja (T1070.006)

set -u

# Lite variabler
TAG="RED_FREDRIK"
VICTIM="victim-${RANDOM}"
VICTIM_HOME="/home/${VICTIM}"
CRON="/etc/cron.d/${TAG}"

# Kolla så att användaren kör som sudo, om inte så avslutar vi med ett felmeddelande
if [[ $EUID -ne 0 ]]; then
  echo "ERROR! Run as sudo."
  exit 1
fi

# Funktion för att lägga till lite stil och variabel väntan i texten
thinking() {
    sleep $1
    echo -n "."
    sleep $1
    echo -n "."
    sleep $1
    echo "."
}

# Funktion för att enklare få saker i loggen framöver
log() {
    logger -t "$TAG" "$1"
}

# Funktion för att städa upp efter oss
cleanup(){
  log "Restoring system"
  echo "Restoring system"
  rm -f "$CRON"
  userdel -r "$VICTIM" 2>/dev/null
  sleep 0.5
  log "Restoring system -- DONE!"
  echo "Restoring system -- DONE!"
}
trap cleanup EXIT

log "Simulation ${TAG} starting"
echo "Simulation ${TAG} starting as ${SUDO_USER:-?} / $(whoami)"

# Skapar ett temp-konto - MITRE T1136.001
log  "T1136.001: Creating account $VICTIM"
echo -n "Doing covert stuff"
thinking 0.5
useradd -m -s /bin/bash "$VICTIM"

# Skapar en dummy-nyckel för SSH - MITRE T1098.004
log "T1098.004: Creating SSH-nyckel in $VICTIM/.ssh/authorized_keys"
echo -n "More covert things being performed"
thinking 0.5
install -d -m 700 -o "$VICTIM" -g "$VICTIM" "$VICTIM_HOME/.ssh"
echo "ssh-ed25519 AAAA_DUMMY_${TAG}_NOT_A_REAL_KEY sim@lab" \
    > "$VICTIM_HOME/.ssh/authorized_keys"
chown "$VICTIM:$VICTIM" "$VICTIM_HOME/.ssh/authorized_keys"
chmod 600 "$VICTIM_HOME/.ssh/authorized_keys"

# Maskerar och gör i ordning data för exfiltrering och tar bort den - MITRE T1036, T1074 och T1070.004
log "T1036 + T1074 + T1070.004: staging harvested data as a masqueraded .swp file and removing it afterwards"
echo -n "Doing hacker stuff" 
echo "We'd have /etc/passwd here" > "/home/${VICTIM}/.cache.swp"
thinking 0.5
rm -f "/home/${VICTIM}/.cache.swp"

# Cron job - MITRE T1053.003
log "T1053.003: Creating Cron persistence with $CRON"
cat > "$CRON" <<EOF
# ${TAG} - simulated persistence
0 0 * * * root logger -t ${TAG} "cron persistence beacon (${TAG})"
EOF
chmod 644 "$CRON"
echo -n "More hacker stuff"
thinking 1

# Timestomp - MITRE T1070.006
log "T1070.006: timestomp $CRON (mtime = /etc/hostname)"
touch -r /etc/hostname "$CRON"
touch -r /etc/hostname "$VICTIM_HOME/.ssh/authorized_keys"

echo -n "Doing the heavy lifting"
thinking 1
echo -n "This was heavier than expected"
thinking 2
echo -n "This script must be pretty devastating"
thinking 3
echo -n "Finishing touches"
thinking 5

# cleanup() per automatik vid EXIT