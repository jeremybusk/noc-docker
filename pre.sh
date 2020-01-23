#!/bin/bash

# setup permissions
# setup promgrafana dashboards\sources

INSTALLPATH=/opt/noc-dc
TMPPATH=$(mktemp -d -p /tmp)
TMPPATH1=$(mktemp -d -p /tmp)

function CREATEDIR {
    mkdir -p $INSTALLPATH/data/promgrafana/etc/provisioning/datasources
    mkdir -p $INSTALLPATH/data/promgrafana/etc/provisioning/notifiers
    mkdir -p $INSTALLPATH/data/promgrafana/etc/provisioning/dashboards
    mkdir -p $INSTALLPATH/data/promgrafana/etc/dashboards
    mkdir -p $INSTALLPATH/data/promgrafana/plugins
    mkdir -p $INSTALLPATH/data/promgrafana/db
    mkdir -p $INSTALLPATH/data/promvm
    mkdir -p $INSTALLPATH/data/prometheus/metrics
    mkdir -p $INSTALLPATH/data/prometheus/etc/rules.d
    mkdir -p $INSTALLPATH/data/consul
    mkdir -p $INSTALLPATH/data/clickhouse/data
    mkdir -p $INSTALLPATH/data/nsq
    mkdir -p $INSTALLPATH/data/mongo
    mkdir -p $INSTALLPATH/data/noc/custom
    mkdir -p $INSTALLPATH/data/postgres
    mkdir -p $INSTALLPATH/data/nginx/ssl
    mkdir -p $INSTALLPATH/data/grafana/plugins
    mkdir -p $INSTALLPATH/data/sentry/redis
    mkdir -p $INSTALLPATH/data/sentry/pg
}

function SETPERMISSION {
    chown 101 -R $INSTALLPATH/data/clickhouse/data
    chown 999 -R $INSTALLPATH/data/postgres
    chown 999 -R $INSTALLPATH/data/mongo
    chown 472 -R $INSTALLPATH/data/grafana/
    chown 65534 -R $INSTALLPATH/data/prometheus/metrics
    chown 472 -R $INSTALLPATH/data/promgrafana/plugins
    chown 999 -R $INSTALLPATH/data/sentry/redis
    chown 70 -R $INSTALLPATH/data/sentry/pg
}

function SETUPPROMGRAFANA {
    echo "Clone GRAFANA dashboards from code.getnoc.com"
    cd "$TMPPATH" && git clone https://code.getnoc.com/noc/grafana-selfmon-dashboards.git .
    cp -f -r "$TMPPATH"/dashboards/* "$INSTALLPATH"/data/promgrafana/etc/dashboards
    cp -f -r "$TMPPATH"/provisioning/* "$INSTALLPATH"/data/promgrafana/etc/provisioning
}

function SETUPPROMRULES {
    echo "Clone PROMETHEUS alert rules from code.getnoc.com"
    cd "$TMPPATH1" && git clone https://code.getnoc.com/noc/noc-prometheus-alerts.git .
    cp -f "$TMPPATH1"/*.yml "$INSTALLPATH"/data/prometheus/etc/rules.d
}

function SETUPSENTRY() {
    if [ ! -f $INSTALLPATH/data/sentry/sentry.env ]
        then
            echo "Setup Sentry env in $INSTALLPATH/data/sentry/sentry.env"
            echo "SENTRY_SECRET_KEY=$(date -d "Oct 22 1974" +%s)" > $INSTALLPATH/data/sentry/sentry.env
            echo "SENTRY_DB_PASSWORD=$(date -d "now" +%s)" >> $INSTALLPATH/data/sentry/sentry.env
            echo "POSTGRES_PASSWORD=$(date -d "Oct 1 2000" +%s)" >> $INSTALLPATH/data/sentry/sentry.env
            echo "POSTGRES_DBPASS$(date -d "Oct 14 1199" +%s)" >> $INSTALLPATH/data/sentry/sentry.env
    fi
}

function SETUPNOCCONF {
    if [ ! -f $INSTALLPATH/data/noc/etc/noc.conf ]
        then
            echo "Copy " $INSTALLPATH/data/noc/etc/noc.conf.example " to " $INSTALLPATH/data/noc/etc/noc.conf
            cp $INSTALLPATH/data/noc/etc/noc.conf.example $INSTALLPATH/data/noc/etc/noc.conf
    fi
}

# todo
# need check $INSTALLPATH == $COMPOSEPATH and make warning if not
function SETUPENV {
    if [ ! -f $INSTALLPATH/.env ]
        then
            echo "Setup COMPOSEPATH=$INSTALLPATH in $INSTALLPATH/.env"
            echo "COMPOSEPATH=$INSTALLPATH" > $INSTALLPATH/.env
    fi
}

if [ -n "$1" ]
    then
        if [ "$1" = "all" ]
            then
                CREATEDIR
                SETPERMISSION
                SETUPPROMGRAFANA
                SETUPPROMRULES
                SETUPNOCCONF
                SETUPSENTRY
                SETUPENV
        elif [ "$1" = "perm" ]
            then
                CREATEDIR
                SETPERMISSION
        elif [ "$1" = "grafana" ]
            then
                CREATEDIR
                SETUPPROMGRAFANA
        elif [ "$1" = "promrules" ]
            then
                CREATEDIR
                SETUPPROMRULES
        elif [ "$1" = "nocconf" ]
            then
                SETUPNOCCONF
        elif [ "$1" = "sentry" ]
            then
                SETUPSENTRY
        elif [ "$1" = "env" ]
            then
                SETUPENV
        else
            echo "Unknown parameter"
            echo "Use one of: all, env, perm, grafana, promrules, nocconf, sentry"
        fi
else
    echo "No  parameters found."
    echo "Use one of: all, env, perm, grafana, promrules, nocconf, sentry"
fi