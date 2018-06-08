set -x
echo "List Diego Cell CF env vars"
set | grep CF_

# check if TIBCO_EP_HOME is present
if [ ! -z "$TIBCO_EP_HOME" ]; then
  TIBCO_EP_HOME=$HOME
fi

ADMINISTRATOR=$TIBCO_EP_HOME/distrib/tibco/bin/epadmin
$ADMINISTRATOR version
NODE_INSTALL_PATH=$HOME/deploy/nodes
SB_APP_DIR=$HOME
export _JAVA_OPTIONS=-DTIBCO_EP_HOME=$TIBCO_EP_HOME
DOMAIN_NAME=`domainname -d`

# check if Cluster is present
if [ ! -z "$1" ]; then
  ClusterName=$1
else
  DOMAIN_NAME=`domainname -d`
  if [ ! -z "$DOMAIN_NAME" ]; then
    ClusterName=$DOMAIN_NAME
  else
    ClusterName=Cluster1
  fi
fi

# set ADMIN_PORT to default 5556 if not present
if [ -z "$ADMIN_PORT" ]; then
        ADMIN_PORT=5556
fi

# if node config is present, ignore nodename parameter
if [ ! -z "$NODE_CONFIG" ]; then
        NODE_CONFIG="nodedeploy=$SB_APP_DIR/$NODE_CONFIG"
fi

# check if nodename is present
if [ ! -z "$NODENAME" ]; then
  if [ "$POLYGLOT" = "true" ]; then
    NODE_NAME="nodename=$CF_INSTANCE_INDEX.$NODENAME"
    echo "wait until dns updates with node index name"
    sleep 15
    DNS_RESULT=$(dig +short $CF_INSTANCE_INDEX.$NODENAME)
    while [ "$DNS_RESULT" = "" ]  
    do
        DNS_RESULT=$(dig +short $CF_INSTANCE_INDEX.$NODENAME)
        sleep 30
    done
    POLYGLOT_HOSTNAME="hostname=$CF_INSTANCE_INDEX.$NODENAME"
  else
    NODE_NAME="nodename=$NODENAME"
  fi
else
  if [ -z "$DOMAIN_NAME" ]; then
    NODENAME=$HOSTNAME.$ClusterName
  else
    NODENAME=$HOSTNAME
  fi
  NODE_NAME="nodename=$NODENAME"
fi

if [ ! -z "$SB_APP_FILE" ]; then
    SB_APP_FILE="application=$SB_APP_DIR/$SB_APP_FILE"
fi

if [ ! -z "$SUBSTITUTIONS" ]; then
    SUBSTITUTIONS=substitutions=$SUBSTITUTIONS
else
    SUBSTITUTIONS=substitutions=GOLDYLOCKS_EPPORT=10000
fi

if [ ! -z "$PORT" ]; then
    SUBSTITUTIONS=$SUBSTITUTIONS,PORT=$PORT
fi

if [ -z "$BUILDTYPE" ]; then
    BUILDTYPE=PRODUCTION
fi

if [ ! -z "$2" ]; then
  APPLIB_PATH=$2
else
  APPLIB_PATH=$STREAMBASE_HOME/lib
fi

if [ ! -d "$NODE_INSTALL_PATH" ]; then
        mkdir -p $NODE_INSTALL_PATH
fi

# Install node A in cluster X - administration port set to 5556
$ADMINISTRATOR username=vcap password=cloudfoundry install node $DISCOVERYHOSTS nodedirectory=$NODE_INSTALL_PATH adminport=$ADMIN_PORT $NODE_NAME $SB_APP_FILE $NODE_CONFIG $SUBSTITUTIONS deploydirectories=$APPLIB_PATH:$SB_APP_DIR:$SB_APP_DIR/java-bin buildtype=$BUILDTYPE
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Failed INSTALLING node, error code is ${exit_code}. Shutting down container..."
    exit $exit_code
else
    #Start the node using the assigned administration port
    $ADMINISTRATOR servicename=$NODENAME start node
    exit_code=$?

    $ADMINISTRATOR servicename=$NODENAME display node
    $ADMINISTRATOR servicename=0.topologies.apps.internal username=guest password=cloudfoundry display node
    $ADMINISTRATOR servicename=1.topologies.apps.internal username=guest password=cloudfoundry display node

    $ADMINISTRATOR servicename=$NODENAME display cluster
    $ADMINISTRATOR servicename=$NODENAME display partition
    $ADMINISTRATOR servicename=$NODENAME display engine
    
    if [ "$exit_code" -eq "0" ]; then
        echo "Application Started."
        while true;do sleep 300; done
    else
        cat /home/vcap/app/deploy/nodes/$NODENAME/logs/*.log > /home/vcap/all.log
        echo "Application failed to start. Retrieve logs at /home/vcap/all.log...you have 2 minutes to do this."
        sleep 120
        exit $exit_code
    fi

fi

