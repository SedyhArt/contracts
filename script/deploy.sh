#!/bin/bash

# Ensure the script exits on any error
set -e

# Variables (update these with your specific details)
ETHERSCAN_API_KEY="WJJPJ72GIDVI8QHWKVBWQGJ9UE7BVTDF58"
CHAIN_ID=11155111
DEPLOYED_ADDRESS="0x702b3CE0530f10D72ED251629307384ab8749Af8"
CONTRACT_PATH="src/CreepzSoulbound.sol" # Path to the contract file
CONTRACT_NAME="CreepzSoulbound"        # Name of the contract

# Export the Etherscan API key
export ETHERSCAN_API_KEY=$ETHERSCAN_API_KEY

# Run the Foundry verification command
forge verify-contract --chain-id $CHAIN_ID $DEPLOYED_ADDRESS $CONTRACT_PATH:$CONTRACT_NAME

# Notify the user
echo "Verification process initiated. Check the block explorer for the status."