#!/bin/bash

# Create folder if it doesn't exist
DIRECTORY="snetcli-snetd-run"

if [ -d "$DIRECTORY" ]; then
  echo "Directory '$DIRECTORY' already exists."
else
  echo "Creating directory '$DIRECTORY'"
  mkdir -p "$DIRECTORY"
fi

cd $DIRECTORY

DATE1=$(date +%Y%m%d)
TIME1=$(date +%H%M%S)
DT1=$DATE1$TIME1

clear

echo ""
  # Function to prompt user for ORG name
  get_org() {
    read -p "Enter new organization name: " ORG
    if [[ -z $ORG ]]; then
        echo "Sorry, you cann't keep it blank."
        return 1
    else
        echo "$ORG"
        return 0
    fi
  }
# First attempt to get the ORG name
  get_org || get_org  # Retry if the first attempt ORG blank

# Check if the second attempt of ORG name is blank
  if [[ $? -ne 0 ]]; then
    echo "No input provided. Exiting."
    exit 1
  fi

ORG_ID=$ORG"id"

echo ""
  echo "Enter service github repo (https://github.com/Zero2AI/service.git) branch name "
  read -p "or press enter to use default branch (ocr2txt): " proto_branch
  if [ -z "$proto_branch" ]; then
    proto_branch="ocr2txt"
  fi

# variable run for snet

#clear
sleep 2
# Snet ORG and ORG_ID
echo "Creating OrganizationID '${ORG_ID}'"
snet identity create --private-key 6b7369a54b9c41a991e8d420c447cffe507cd73ca7ee12484d82313a7f975369 FIRST key --network sepolia 2>/dev/null
snet organization metadata-init $ORG $ORG_ID individual 2>/dev/null
snet organization metadata-add-description --description $ORG" organisation for zero2ai snet" --short-description  $ORG" z2ai organozation" --url "http://demo.$ORG.com" 2>/dev/null
snet organization add-group default_group 0x5BEc085daC9b53E5bEED6A44C4D02C68fcCBA82c http://127.0.0.1:2379 2>/dev/null
snet organization create $ORG_ID -y 2>/dev/null

HOST_IP=127.0.0.1
CONT_PORT=8010

# ServiceID
echo ""
echo "Creating ServiceID '${PROTO_BRANCH}'"
snet service metadata-init service "${PROTO_BRANCH}" --group-name default_group --fixed-price 0.00000001 --endpoints http://"${HOST_IP}":"${CONT_PORT}" 2>/dev/null
snet service metadata-add-description --json '{"description": "'${PROTO_BRANCH}' is a service of '${ORG}'.", "url": "https://service.users.guide"}' 2>/dev/null
snet service publish $ORG_ID $PROTO_BRANCH -y 2>/dev/null

cat <<EOF > /opt/snetd.config.json
{
  "blockchain_enabled": true,
  "blockchain_network_selected": "sepolia",
  "daemon_end_point": "0.0.0.0:8010",
  "daemon_group_name": "default_group",
  "ipfs_end_point": "http://ipfs.singularitynet.io:80",
  "organization_id": "'$ORG_ID'",
  "service_id": "'$PROTO_BRANCH'",
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
  "log": {"level": "debug", "output": {"type": "stdout"}}
}
EOF

echo "Starting snetd and application service..."
nohup python service/"${PROTO_BRANCH}_service.py" > service.log 2>&1 &
sleep 2
nohup snetd -c /opt/snetd.config.json > snetd.log 2>&1 &
sleep 5

echo ""
snet account deposit 0.00000002 -y 2>/dev/null
snet channel open-init $ORG_ID default_group 0.00000002 +12days -y 2>/dev/null
sleep 3
channel_id=$(snet channel print-initialized 2>/dev/null)
cp service/testocr.png /home/testocr.png

# clear
echo ""
echo "Please note the following information:--"
echo ""
echo "Organization  : " $ORG
echo "ORG_ID        : " $ORG_ID
echo "Service_ID    : " $PROTO_BRANCH
echo "Channel_ID    : " $channel_id
echo "end-point Port: " $CONT_PORT
echo "Host IP       : " $HOST_IP

#rm -f varrunsnet.sh .HOSTIP .port.txt .contport.sh
#EOF
sleep 2
echo " Run -- snet client call '${ORG_id' '${proto_branch}' default_group predict '{"input1":"PaddleOCR","fileName2":"testocr.png","file@fileBytes2":"testocr.png"}'"