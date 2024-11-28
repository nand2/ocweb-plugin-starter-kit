#! /bin/bash

set -euo pipefail

# We need some infos
PRIVATE_KEY=${PRIVATE_KEY:-}
RPC_URL=${RPC_URL:-}
CHAIN_ID=${CHAIN_ID:-31337}
OCWEBSITE_FACTORY_ADDRESS=${OCWEBSITE_FACTORY_ADDRESS:-}
STATIC_FRONTEND_PLUGIN_ADDRESS=${STATIC_FRONTEND_PLUGIN_ADDRESS:-}
OCWEB_ADMIN_PLUGIN_ADDRESS=${OCWEB_ADMIN_PLUGIN_ADDRESS:-}
ETHERSCAN_API_KEY=${ETHERSCAN_API_KEY:-}
if [ -z "$PRIVATE_KEY" ]; then
  echo "PRIVATE_KEY env var is not set. An ethereum private key in the format 0x... must be provided"
  exit 1
fi
if [ -z "$CHAIN_ID" ]; then
  echo "CHAIN_ID env var is not set. Specify the chain id you want to deploy on (e.g. 31337 for local hardhat chain, 10 for Optimism mainnet, etc)"
  exit 1
fi
if [ -z "$OCWEBSITE_FACTORY_ADDRESS" ]; then
  echo "OCWEBSITE_FACTORY_ADDRESS env var is not set. The ethereum address of the OCWebsite factory in the format 0x... must be provided"
  exit 1
fi
if [ -z "$STATIC_FRONTEND_PLUGIN_ADDRESS" ]; then
  echo "STATIC_FRONTEND_PLUGIN_ADDRESS env var is not set. The ethereum address of the 'Static frontend' plugin in the format 0x... must be provided"
  exit 1
fi
if [ -z "$OCWEB_ADMIN_PLUGIN_ADDRESS" ]; then
  echo "OCWEB_ADMIN_PLUGIN_ADDRESS env var is not set. The ethereum address of the 'Admin interface' plugin in the format 0x... must be provided"
  exit 1
fi
if [ -z "$ETHERSCAN_API_KEY" ] && [ "$CHAIN_ID" != "31337" ]; then
  echo "ETHERSCAN_API_KEY env var is not set. An etherscan API key must be provided to verify the contract on etherscan"
  exit 1
fi

# check that forge is installed
if ! command -v forge &> /dev/null
then
    echo "forge could not be found. Please install foundry (toolkit for Ethereum application development)"
    exit
fi

# If the RPC_URL is not set, we use some default ones
if [ -z "$RPC_URL" ]; then
  if [ "$CHAIN_ID" == "31337" ]; then
    RPC_URL=http://127.0.0.1:8545
  elif [ "$CHAIN_ID" == "17000" ]; then
    RPC_URL=https://ethereum-holesky-rpc.publicnode.com
  elif [ "$CHAIN_ID" == "10" ]; then
    RPC_URL=https://mainnet.optimism.io/
  elif [ "$CHAIN_ID" == "8453" ]; then
    RPC_URL=https://mainnet.base.org
  fi
fi
if [ -z "$RPC_URL" ]; then
  echo "RPC_URL env var is not set. A RPC URL must be provided for the chain you selected"
  exit 1
fi

# Non-hardhat chain: Ask for confirmation
if [ "$CHAIN_ID" != "31337" ]; then
  echo "Please confirm that you want to deploy on chain $CHAIN_ID"
  read -p "Press enter to continue"
fi

# Compute the plugin root folder (which is the parent folder of this script)
ROOT_FOLDER=$(cd $(dirname $(readlink -f $0)) && cd .. && pwd)


#
# Build the main frontend and host it on a separate OCWebsite that we will mint
#

# Go to the frontend folder
cd $ROOT_FOLDER/frontend
# Build the frontend
npm run build

# Create an OCWebsite for the frontend
OCWEBSITE_NAME=starterk # You will need to change this (14 chars max)
exec 5>&1
OUTPUT="$(PRIVATE_KEY=$PRIVATE_KEY \
  npx ocweb --rpc $RPC_URL --skip-tx-validation mint --factory-address $OCWEBSITE_FACTORY_ADDRESS $CHAIN_ID $OCWEBSITE_NAME | tee >(cat - >&5))"
# Get the address of the OCWebsite
OCWEBSITE_ADDRESS=$(echo "$OUTPUT" | grep -oP 'New OCWebsite smart contract: \K0x\w+')

# Upload the frontend
OCWEB_OPTIONS=
if [ "$CHAIN_ID" == "31337" ]; then
  OCWEB_OPTIONS="--skip-tx-validation"
fi
PRIVATE_KEY=$PRIVATE_KEY \
WEB3_ADDRESS=web3://$OCWEBSITE_ADDRESS:$CHAIN_ID \
npx ocweb --rpc $RPC_URL $OCWEB_OPTIONS upload dist/* / --exclude 'dist/variables.json'


#
# Build the admin JS UMD module and host it on a separate OCWebsite that we will mint
#

# Go to the admin frontend folder
cd $ROOT_FOLDER/admin
# Build the admin frontend
npm run build

# Create an OCWebsite for the frontend
OCWEBSITE_NAME=starterk-admin # You will need to change this (14 chars max)
exec 5>&1
OUTPUT="$(PRIVATE_KEY=$PRIVATE_KEY \
  npx ocweb --rpc $RPC_URL --skip-tx-validation mint --factory-address $OCWEBSITE_FACTORY_ADDRESS $CHAIN_ID $OCWEBSITE_NAME | tee >(cat - >&5))"
# Get the address of the OCWebsite
ADMIN_OCWEBSITE_ADDRESS=$(echo "$OUTPUT" | grep -oP 'New OCWebsite smart contract: \K0x\w+')

# Upload the frontend
OCWEB_OPTIONS=
if [ "$CHAIN_ID" == "31337" ]; then
  OCWEB_OPTIONS="--skip-tx-validation"
fi
PRIVATE_KEY=$PRIVATE_KEY \
WEB3_ADDRESS=web3://$ADMIN_OCWEBSITE_ADDRESS:$CHAIN_ID \
npx ocweb --rpc $RPC_URL $OCWEB_OPTIONS upload dist/* /admin/



#
# Build the plugin
# 

FORGE_CREATE_OPTIONS=
if [ "$CHAIN_ID" != "31337" ]; then
  FORGE_CREATE_OPTIONS="--verify"
fi
exec 5>&1
OUTPUT="$(forge create --private-key $PRIVATE_KEY $FORGE_CREATE_OPTIONS \
  --constructor-args $OCWEBSITE_ADDRESS $ADMIN_OCWEBSITE_ADDRESS $STATIC_FRONTEND_PLUGIN_ADDRESS $OCWEB_ADMIN_PLUGIN_ADDRESS \
  --rpc-url $RPC_URL \
  src/StarterKitPlugin.sol:StarterKitPlugin | tee >(cat - >&5))"
# Get the plugin address
PLUGIN_ADDRESS=$(echo "$OUTPUT" | grep -oP 'Deployed to: \K0x\w+')

# Print the plugin address
echo ""
echo "Plugin address: $PLUGIN_ADDRESS"

