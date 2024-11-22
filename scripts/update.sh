#! /bin/bash

set -euo pipefail

# Target chain: If empty, default to "local"
# Can be: local, sepolia, holesky, mainnet, base-sepolia, base, optimism
TARGET_CHAIN=${1:-local}
# Check that target chain is in allowed values
if [ "$TARGET_CHAIN" != "local" ] && [ "$TARGET_CHAIN" != "sepolia" ] && [ "$TARGET_CHAIN" != "holesky" ] && [ "$TARGET_CHAIN" != "mainnet" ] && [ "$TARGET_CHAIN" != "base-sepolia" ] && [ "$TARGET_CHAIN" != "base" ] && [ "$TARGET_CHAIN" != "optimism" ]; then
  echo "Invalid target chain: $TARGET_CHAIN"
  exit 1
fi
# Section.
SECTION=${2:-}
if [ "$SECTION" != "frontend-files" ]; then
  echo "Invalid section: $SECTION"
  exit 1
fi
DOMAIN=ocweb


# Setup cleanup
function cleanup {
  echo "Exiting, cleaning up..."
  # rm -rf dist
}
trap cleanup EXIT

# Go to the root folder
ROOT_FOLDER=$(cd $(dirname $(readlink -f $0)); cd ..; pwd)
cd $ROOT_FOLDER

# Load .env file
# PRIVATE_KEY must be defined
source .env
# Determine the private key and RPC URL to use, and the chain id
PRIVKEY=
RPC_URL=
CHAIN_ID=
if [ "$TARGET_CHAIN" == "local" ]; then
  PRIVKEY=$PRIVATE_KEY_LOCAL
  RPC_URL=http://127.0.0.1:8545
  CHAIN_ID=31337
elif [ "$TARGET_CHAIN" == "sepolia" ]; then
  PRIVKEY=$PRIVATE_KEY_SEPOLIA
  RPC_URL=https://ethereum-sepolia-rpc.publicnode.com
  CHAIN_ID=11155111
elif [ "$TARGET_CHAIN" == "holesky" ]; then
  PRIVKEY=$PRIVATE_KEY_HOLESKY
  RPC_URL=https://ethereum-holesky-rpc.publicnode.com
  CHAIN_ID=17000
elif [ "$TARGET_CHAIN" == "base-sepolia" ]; then
  PRIVKEY=$PRIVATE_KEY_BASE_SEPOLIA
  RPC_URL=https://sepolia.base.org
  CHAIN_ID=84532
elif [ "$TARGET_CHAIN" == "base" ]; then
  PRIVKEY=$PRIVATE_KEY_BASE
  RPC_URL=https://mainnet.base.org
  CHAIN_ID=8453
elif [ "$TARGET_CHAIN" == "optimism" ]; then
  PRIVKEY=$PRIVATE_KEY_OPTIMISM
  RPC_URL=https://mainnet.optimism.io/
  CHAIN_ID=10
else
  echo "Not implemented yet"
  exit 1
fi

# Preparing the etherscan API key
# For etherscan, it is already set in the .env file
# If basescan, copy BASESCAN_API_KEY into it
if [ "$TARGET_CHAIN" == "base-sepolia" ] || [ "$TARGET_CHAIN" == "base" ]; then
  export ETHERSCAN_API_KEY=$BASESCAN_API_KEY
fi
# If optimism, copy OPTIMISTIC_ETHERSCAN_API_KEY into it
if [ "$TARGET_CHAIN" == "optimism" ]; then
  export ETHERSCAN_API_KEY=$OPTIMISTIC_ETHERSCAN_API_KEY
fi

# Preparing options for forge
FORGE_SCRIPT_OPTIONS=
if [ "$TARGET_CHAIN" == "local" ]; then
  # 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
  FORGE_SCRIPT_OPTIONS="--broadcast"
elif [ "$TARGET_CHAIN" == "sepolia" ]; then
  # 0xAafA7E1FBE681de12D41Ef9a5d5206A96963390e
  FORGE_SCRIPT_OPTIONS="--broadcast --verify" #  --legacy --with-gas-price=5000000000
elif [ "$TARGET_CHAIN" == "holesky" ]; then
  # 0xAafA7E1FBE681de12D41Ef9a5d5206A96963390e
  # Weird, sometimes I have "Failed to get EIP-1559 fees" on holesky, need --legacy
  FORGE_SCRIPT_OPTIONS="--broadcast --verify" #  --legacy --with-gas-price=1000000000
elif [ "$TARGET_CHAIN" == "base-sepolia" ]; then
  # 0xAafA7E1FBE681de12D41Ef9a5d5206A96963390e
  FORGE_SCRIPT_OPTIONS="--broadcast --verify"
elif [ "$TARGET_CHAIN" == "base" ]; then
  # 0xAafA7E1FBE681de12D41Ef9a5d5206A96963390e
  FORGE_SCRIPT_OPTIONS="--broadcast --verify --slow"
elif [ "$TARGET_CHAIN" == "optimism" ]; then
  # 0xAafA7E1FBE681de12D41Ef9a5d5206A96963390e
  FORGE_SCRIPT_OPTIONS="--broadcast --verify --slow"
else
  echo "Not implemented yet"
  exit 1
fi

# Non-hardhat chain: Ask for confirmation
if [ "$TARGET_CHAIN" != "local" ]; then
  echo "Please confirm that you want to deploy on $TARGET_CHAIN"
  read -p "Press enter to continue"
fi

# Extra args for ocweb CLI
OCWEB_CLI_EXTRA_ARGS=
if [ "$TARGET_CHAIN" == "local" ]; then
  OCWEB_CLI_EXTRA_ARGS="--skip-tx-validation"
fi

# Get the plugin address
if [ "$CHAIN_ID" == "10" ] || [ "$CHAIN_ID" == "17000" ]; then
  PLUGIN_ADDRESS=$(npx ocweb factory-infos ${CHAIN_ID} | grep 'themeAboutMe' |  awk '{print $1}')
else
  OCWEBSITE_FACTORY_ADDRESS=$(cat ../ocweb/contracts/broadcast/OCWebsiteFactory.s.sol/${CHAIN_ID}/run-latest.json | jq -r '[.transactions[] | select(.contractName == "ERC1967Proxy" and .transactionType == "CREATE")][0].contractAddress')
  PLUGINS_INFOS_CALL_RESULT=$(cast call --rpc-url $RPC_URL --chain ${CHAIN_ID} $OCWEBSITE_FACTORY_ADDRESS "getWebsitePlugins(bytes4[])" "[]")
  PLUGINS_INFOS=$(cast abi-decode "getWebsitePlugins(bytes4[])((address,(string,string,address,uint8),bool,bool)[])" $PLUGINS_INFOS_CALL_RESULT)
  # cast abi-decode --json fails, so we need to do a dirty fetching of the plugin address
  PLUGIN_ADDRESS=$(echo $PLUGINS_INFOS | awk '{for (i=2; i<=NF; i++) if ($i == "(\"themeAboutMe\",") print $(i-1)}' | sed 's/^.\(.*\).$/\1/')
fi

# Get the frontend address
PLUGIN_FRONTEND_CALL_RESULT=$(cast call --rpc-url $RPC_URL --chain ${CHAIN_ID} $PLUGIN_ADDRESS "frontend()")
PLUGIN_FRONTEND_ADDRESS=$(cast abi-decode "frontend()(address)" $PLUGIN_FRONTEND_CALL_RESULT)
PLUGIN_FRONTEND_WEB3_ADDRESS="web3://${PLUGIN_FRONTEND_ADDRESS}:${CHAIN_ID}"

# Update files in the factory frontend
if [ "$SECTION" == "frontend-files" ]; then
  NEW_VERSION_MESSAGE="${@:3}"
  if [ "$NEW_VERSION_MESSAGE" == "" ]; then
    echo "Please provide a message for the new version"
    exit 1
  fi

  # Go to the admin frontend folder
  cd $ROOT_FOLDER/admin
  # Build the admin frontend
  npm run build

  # Go to the frontend folder
  cd $ROOT_FOLDER/frontend
  # Build the frontend
  npm run build

  # Make a temporary folder where we mix both admin and frontend
  cd $ROOT_FOLDER
  rm -Rf $ROOT_FOLDER/dist
  mkdir -p dist
  mkdir -p dist/themes/about-me
  cp -R admin/dist/* dist/themes/about-me
  cp -R frontend/dist/index.html frontend/dist/logo.svg frontend/dist/assets dist

  echo "Updating files on frontend ${PLUGIN_FRONTEND_WEB3_ADDRESS} ..."

  # First create a new website version
  echo "Creating a new website version..."
  PRIVATE_KEY=$PRIVKEY \
  WEB3_ADDRESS=${PLUGIN_FRONTEND_WEB3_ADDRESS} \
  npx ocweb --rpc $RPC_URL $OCWEB_CLI_EXTRA_ARGS version-add "$NEW_VERSION_MESSAGE"

  sleep 1

  # Get the number of the newly created version
  echo "Fetching the number of the new website version..."
  WEBSITE_VERSION_INDEX=$(WEB3_ADDRESS=${PLUGIN_FRONTEND_WEB3_ADDRESS} \
  npx ocweb --rpc $RPC_URL $OCWEB_CLI_EXTRA_ARGS version-ls | tail -n1 | awk '{print $1}')
  echo "New website version number: $WEBSITE_VERSION_INDEX"

  # Make it viewable
  echo "Making the new website version viewable..."
  PRIVATE_KEY=$PRIVKEY \
  WEB3_ADDRESS=${PLUGIN_FRONTEND_WEB3_ADDRESS} \
  npx ocweb --rpc $RPC_URL $OCWEB_CLI_EXTRA_ARGS --website-version $WEBSITE_VERSION_INDEX version-set-viewable true

  # Upload the files to the new website version
  echo "Uploading files to the new website version..."
  PRIVATE_KEY=$PRIVKEY \
  WEB3_ADDRESS=${PLUGIN_FRONTEND_WEB3_ADDRESS} \
  npx ocweb --rpc $RPC_URL $OCWEB_CLI_EXTRA_ARGS --website-version $WEBSITE_VERSION_INDEX \
  upload dist/* / --sync

  # Set the new website version live
  echo "Setting the new website version live..."
  PRIVATE_KEY=$PRIVKEY \
  WEB3_ADDRESS=${PLUGIN_FRONTEND_WEB3_ADDRESS} \
  npx ocweb --rpc $RPC_URL $OCWEB_CLI_EXTRA_ARGS version-set-live $WEBSITE_VERSION_INDEX
fi