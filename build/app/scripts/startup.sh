#!/usr/bin/env bash

## Run the commands to make it all work
ln -fs /usr/share/zoneinfo/$TZ /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata

echo $HOSTNAME > /etc/hostname

# Extract compressed binaries and move binaries to bin
if [ -e /opt/"$APPNAME"/scripts/.firstrun ]; then
    # Unzip frontail and tailon
    gunzip /usr/local/bin/frontail.gz
    gunzip /usr/local/bin/tailon.gz

    # Copy python scripts to /usr/local/bin and make executable
    cp /opt/"$APPNAME"/scripts/dns-add.py /usr/local/bin
    chmod 755 /usr/local/bin/dns-add.py
fi

# Link scripts to debug folder as needed
if [ -e /opt/"$APPNAME"/scripts/.firstrun ]; then
    ln -s /opt/"$APPNAME"/scripts/tail.sh /opt/"$APPNAME"/debug
    ln -s /opt/"$APPNAME"/scripts/tmux.sh /opt/"$APPNAME"/debug
fi

# Create the file /var/run/utmp or when using tmux this error will be received
# utempter: pututline: No such file or directory
if [ -e /opt/"$APPNAME"/scripts/.firstrun ]; then
    touch /var/run/utmp
else
    truncate -s 0 /var/run/utmp
fi

# Link the log to the app log. Create/clear other log files.
if [ -e /opt/"$APPNAME"/scripts/.firstrun ]; then
    mkdir -p /opt/"$APPNAME"/logs
    touch /opt/"$APPNAME"/logs/"$APPNAME".log
else
    truncate -s 0 /opt/"$APPNAME"/logs/"$APPNAME".log
fi

# Print first message to either the app log file or syslog
echo "$(date -Is) [Start of $APPNAME log file]" >> /opt/"$APPNAME"/logs/"$APPNAME".log

# Check if `upload` subfolder exists. If non-existing, create it .
# Checking for a file inside the folder because if the folder
#  is mounted as a volume it will already exists when docker starts.
# Also change permissions
if [ ! -e "/opt/$APPNAME/upload/.exists" ]
then
    mkdir -p /opt/"$APPNAME"/upload
    touch /opt/"$APPNAME"/upload/.exists
    echo '`upload` folder created'
    cp /opt/"$APPNAME"/configs/hosts.csv /opt/"$APPNAME"/upload
    chown -R "${HUID}":"${HGID}" /opt/"$APPNAME"/upload
fi

# Stop services
service dnsmasq stop

# Modify configuration files or customize container
if [ -e /opt/"$APPNAME"/scripts/.firstrun ]; then
    cp /opt/"$APPNAME"/configs/dnsmasq.conf /etc/
    sed -i '/^search/d' /etc/resolv.conf
    touch /etc/banner_add_hosts
fi

# Run the python script to add all the IPs and static routes
dns-add.py | tee -a /opt/"$APPNAME"/logs/"$APPNAME".log

# Start services
service dnsmasq start

# Start web interface
NLINES=1000 # how many tail lines to follow

# ttyd1 (tail and read only)
# to remove color add the option `-T xterm-mono`
# selection changed to selectionBackground in 1.7.2 - bug reported
# `-t 'theme={"foreground":"black","background":"white", "selection":"#ff6969"}'` # 69, nice!
# `-t 'theme={"foreground":"black","background":"white", "selectionBackground":"#ff6969"}'`
sed -Ei 's/tail -n 500/tail -n '"$NLINES"'/' /opt/"$APPNAME"/scripts/tail.sh
nohup ttyd -p "$HTTPPORT1" -R -t titleFixed="${APPNAME}.log" -t fontSize=16 -t 'theme={"foreground":"black","background":"white", "selectionBackground":"#ff6969"}' -s 2 /opt/"$APPNAME"/scripts/tail.sh >> /opt/"$APPNAME"/logs/ttyd1.log 2>&1 &

# ttyd2 (tmux with color)
# to remove color add the option `-T xterm-mono`
# selection changed to selectionBackground in 1.7.2 - bug reported
# `-t 'theme={"foreground":"black","background":"white", "selection":"#ff6969"}'` # 69, nice!
# `-t 'theme={"foreground":"black","background":"white", "selectionBackground":"#ff6969"}'`
cp /opt/"$APPNAME"/configs/tmux.conf /root/.tmux.conf
sed -Ei 's/tail -n 500/tail -n '"$NLINES"'/' /opt/"$APPNAME"/scripts/tmux.sh
nohup ttyd -p "$HTTPPORT2" -t titleFixed="${APPNAME}.log" -t fontSize=16 -t 'theme={"foreground":"black","background":"white", "selectionBackground":"#ff6969"}' -s 9 /opt/"$APPNAME"/scripts/tmux.sh >> /opt/"$APPNAME"/logs/ttyd2.log 2>&1 &

# frontail
nohup frontail -n "$NLINES" -p "$HTTPPORT3" /opt/"$APPNAME"/logs/"$APPNAME".log >> /opt/"$APPNAME"/logs/frontail.log 2>&1 &

# tailon
sed -Ei 's/\$lines/'"$NLINES"'/' /opt/"$APPNAME"/configs/tailon.toml
sed -Ei '/^listen-addr = /c listen-addr = [":'"$HTTPPORT4"'"]' /opt/"$APPNAME"/configs/tailon.toml
nohup tailon -c /opt/"$APPNAME"/configs/tailon.toml /opt/"$APPNAME"/logs/"$APPNAME".log /opt/"$APPNAME"/logs/ttyd1.log /opt/"$APPNAME"/logs/ttyd2.log /opt/"$APPNAME"/logs/frontail.log /opt/"$APPNAME"/logs/tailon.log >> /opt/"$APPNAME"/logs/tailon.log 2>&1 &

# Remove the .firstrun file if this is the first run
if [ -e /opt/"$APPNAME"/scripts/.firstrun ]; then
    rm -f /opt/"$APPNAME"/scripts/.firstrun
fi

# Keep docker running
bash
