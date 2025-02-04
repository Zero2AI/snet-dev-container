#!/bin/bash

# ---------------------------------------------------------------------------
# This script reads organization details and branch name from input.txt
# and then configures/publishes a SingularityNET service with snet-cli.
# ---------------------------------------------------------------------------

# 1) Read variables from input.txt
#    Ensure input.txt is present and has lines like:
#       ORG="myorg"
#       ORG_ID="myorgid"
#       PROTO_BRANCH="mybranch"
#    (No spaces around '=' recommended)
if [ ! -f "input.txt" ]; then
  echo "ERROR: input.txt not found. Please create input.txt with ORG, ORG_ID, and PROTO_BRANCH."
  exit 1
fi

# Use 'source' to load the variables directly
source input.txt

# You can optionally check if variables are empty
if [[ -z "$ORG" || -z "$ORG_ID" || -z "$PROTO_BRANCH" ]]; then
  echo "ERROR: One of the required variables (ORG, ORG_ID, PROTO_BRANCH) is not set in input.txt"
  exit 1
fi

clear

DATE1=$(date +%Y%m%d)
TIME1=$(date +%H%M%S)
DT1=$DATE1$TIME1

# ---SNET Setup--- 
echo "Creating OrganizationID '${ORG_ID}'"

# Create an identity (change key if needed)
snet identity create --private-key 6b7369a54b9c41a991e8d420c447cffe507cd73ca7ee12484d82313a7f975369 FIRST key --network sepolia 2>/dev/null

# add latest sepholia infura key
sed -i 's|https://sepolia.infura.io/v3/09027f4a13e841d48dbfefc67e7685d5|https://sepolia.infura.io/v3/37ab1531f69a402fbb84ae725248ec60|g' /root/.snet/config

# Initialize org metadata
snet organization metadata-init "$ORG" "$ORG_ID" individual 2>/dev/null

# Add org description
snet organization metadata-add-description \
  --description "${ORG} organisation for zero2ai snet" \
  --short-description "${ORG} z2ai organization" \
  --url "http://demo.${ORG}.com" 2>/dev/null

# Add group
snet organization add-group default_group \
  0x5BEc085daC9b53E5bEED6A44C4D02C68fcCBA82c \
  http://127.0.0.1:2379 \
  2>/dev/null

# Create organization on-chain
snet organization create "$ORG_ID" -y 2>/dev/null

git clone https://github.com/Zero2AI/service.git -b $PROTO_BRANCH

# Host settings
HOST_IP=127.0.0.1
CONT_PORT=8010

# Create and publish the service using PROTO_BRANCH
echo ""
echo "Creating ServiceID '${PROTO_BRANCH}'"
snet service metadata-init service "${PROTO_BRANCH}" \
    --group-name default_group \
    --fixed-price 0.00000001 \
    --endpoints http://"${HOST_IP}":"${CONT_PORT}" \
    2>/dev/null

# Add service description
snet service metadata-add-description \
  --json '{"description": "'${PROTO_BRANCH}' is a service of '${ORG}'.", "url": "https://service.users.guide"}' \
  2>/dev/null

# Publish the service
snet service publish "$ORG_ID" "$PROTO_BRANCH" -y 2>/dev/null

# Create snetd config file
cat <<EOF > /opt/snetd.config.json
{
  "blockchain_enabled": true,
  "blockchain_network_selected": "sepolia",
  "daemon_end_point": "0.0.0.0:8010",
  "daemon_group_name": "default_group",
  "ipfs_end_point": "http://ipfs.singularitynet.io:80",
  "organization_id": "${ORG_ID}",
  "service_id": "${PROTO_BRANCH}",
  "passthrough_enabled": true,
  "passthrough_endpoint": "http://127.0.0.1:50051",
  "payment_channel_storage_server": {
    "client_port": 2379,
    "cluster": "storage-1=http://127.0.0.1:2380",
    "data_dir": "data.etcd",
    "enabled": true,
    "host": "127.0.0.1",
    "id": "storage-1",
    "log_level": "info",
    "peer_port": 2380,
    "scheme": "http",
    "startup_timeout": "1m",
    "token": "518"
  },
  "log": {
    "level": "debug",
    "output": {
      "type": "stdout"
    }
  }
}
EOF

# Start the service and snet daemon
echo "Starting snetd and application service..."
nohup python service/"${PROTO_BRANCH}_service.py" > service.log 2>&1 &
sleep 2
nohup snetd -c /opt/snetd.config.json > snetd.log 2>&1 &
sleep 5

# Deposit and open payment channel
echo ""
snet account deposit 0.00000002 -y 2>/dev/null
snet channel open-init "$ORG_ID" default_group 0.00000002 +12days -y 2>/dev/null
sleep 3

channel_id=$(snet channel print-initialized 2>/dev/null)

cp service/testocr.png /home/testocr.png

# Show info
echo ""
echo "Please note the following information:"
echo "---------------------------------------"
echo " Organization : $ORG"
echo " ORG_ID       : $ORG_ID"
echo " Service_ID   : $PROTO_BRANCH"
echo " Channel_ID   : $channel_id"
echo " End-point    : $HOST_IP:$CONT_PORT"
echo "---------------------------------------"

sleep 2
echo "Example client call:"
echo "snet client call '$ORG_ID' '$PROTO_BRANCH' default_group predict '{\"input1\":\"PaddleOCR\",\"fileName2\":\"testocr.png\",\"file@fileBytes2\":\"testocr.png\"}'"