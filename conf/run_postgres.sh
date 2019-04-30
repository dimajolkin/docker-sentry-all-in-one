#!/bin/sh

# This script is run by Supervisor to start PostgreSQL 9.3 in foreground mode

if [ -d /var/run/postgresql ]; then
    chmod 2775 /var/run/postgresql
else
    install -d -m 2775 -o postgres -g postgres /var/run/postgresql
fi

exec su postgres -c "/usr/lib/postgresql/10/bin/postgres -c config_file=/var/lib/postgresql/10/main/postgresql.conf"