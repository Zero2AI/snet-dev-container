#!/bin/bash

clear
echo ""
echo ""
# Load values from id_input.txt
source id_input.txt

# Show menu with actual values
echo "Select an option to delete:"
echo "1. Delete Service only ($SERVICE)"
echo "2. Delete Organization only ($ORG_ID)"
echo "3. Delete both Service and Organization ($SERVICE and $ORG_ID)"
echo "4. Exit"
read -p "Enter your choice (1-4): " choice
echo ""
echo ""

# Exit if user selects option 4
if [[ "$choice" == "4" ]]; then
  echo "Exiting..."
  exit 0
fi

# Prompt user for values with defaults from id_input.txt
#read -p "Enter PROTO_BRANCH [default: $PROTO_BRANCH]: " user_branch
#PROTO_BRANCH="${user_branch:-$PROTO_BRANCH}"

#read -p "Enter ORG_ID [default: $ORG_ID]: " user_org
#ORG_ID="${user_org:-$ORG_ID}"

echo ""
echo "Executing deletion based on selected option..."

# Execute the appropriate deletion command(s)
case $choice in
  1)
    list_service=$(snet organization list-services "$ORG_ID" 2>/dev/null)
    echo $list_service 2>/dev/null
    echo ""
    read -p "Enter SERVICE [default: $SERVICE] (you may type 'exit' to quit): " user_branch
    [[ "${user_branch,,}" == "exit" ]] && echo "Exiting..." && exit 0
    SERVICE="${user_branch:-$SERVICE}"
    echo ""
    echo "Deleting service: $SERVICE in org: $ORG_ID"
    snet service delete "$SERVICE" "$ORG_ID" -y 2>/dev/null
    # Remove PROTO_BRANCH line from file
    sed -i '/^SERVICE=/d' id_input.txt
    rm service_metadata.json service.log service
    echo ""
    ;;
  2)
    # Check if service entry exists in the file before deleting org
    proto_exists_in_file=$(grep -E "^SERVICE=.*" id_input.txt)
    if [[ -n "$proto_exists_in_file" ]]; then
      echo ""
      echo "Cannot remove Organization. Service is still registered: $SERVICE"
      echo "Please remove the Service first."
      exit 1
    fi
    read -p "Enter ORG_ID [default: $ORG_ID] (you may type 'exit' to quit): " user_org
    [[ "${user_org,,}" == "exit" ]] && echo "Exiting..." && exit 0
    ORG_ID="${user_org:-$ORG_ID}"
    echo ""
    echo "Deleting organization: $ORG_ID"
    snet organization delete "$ORG_ID" -y 2>/dev/null
    # Remove ORG_ID line from file
    sed -i '/^ORG_ID=/d' id_input.txt
    sed -i '/^ORG=/d' id_input.txt
    sed -i '/^GITHUB=/d' id_input.txt
    sed -i '/^ORG_ID=/d' id_input.txt
    sed -i '/^SERVICE=/d' id_input.txt
    rm organization_metadata.json data.etcd snetd.log
    ;;
  3)
    echo ""
    read -p "Enter SERVICE [default: $SERVICE] (you may type 'exit' to quit): " user_branch
    [[ "${user_branch,,}" == "exit" ]] && echo "Exiting..." && exit 0
    SERVICE="${user_branch:-$SERVICE}"
    echo ""
    read -p "Enter ORG_ID [default: $ORG_ID] (you may type 'exit' to quit): " user_org
    [[ "${user_org,,}" == "exit" ]] && echo "Exiting..." && exit 0
    ORG_ID="${user_org:-$ORG_ID}"
    echo ""
    echo "Deleting Service : $SERVICE in org: $ORG_ID"
    sent service delete "$SERVICE" "$ORG_ID" -y 2>/dev/null
    echo "Deleting Organization : $ORG_ID"
    snet organization delete "$ORG_ID" -y 2>/dev/null
    # Remove line from file
    #sed -i '/^PROTO_BRANCH=/d' id_input.txt
    #sed -i '/^ORG_ID=/d' id_input.txt
    #sed -i '/^ORG=/d' id_input.txt
    #sed -i '/^GITHUB=/d' id_input.txt
    #sed -i '/^ORG_ID=/d' id_input.txt
    #sed -i '/^PVT_KEY=/d' id_input.txt
    #sed -i '/^PUB_KEY=/d' id_input.txt

    # Kill Service.py file
    kill -9 -f "${SERVICE_APP}_service.py" 2>/dev/null && kill -9 -f snetd.config.json 2>/dev/null
    sleep 2

    rm -rf id_input.txt organization_metadata.json service_metadata.json service data.etcd service.log snetd.log etcd-server.log
    ;;
  *)
    echo "Invalid option selected."
    ;;
esac
