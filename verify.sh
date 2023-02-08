#!/bin/bash
RPC_URL=https://rpc.payload.de
SOLC_METADATA_DELIMITER=a264

while [ $# -gt 0 ]; do
  case "$1" in
    --contract=*)
      CONTRACT_NAME="${1#*=}"
      ;;
    --tx=*)
      DEPLOYMENT_TX="${1#*=}"
      ;;
    --repo=*)
      PROJECT_REPO="${1#*=}"
      ;;
    --commit=*)
      COMMIT="${1#*=}"
      ;;
    --solc=*)
      SOLC_VERSION="--use ${1#*=}"
      ;;
    --rpc=*)
      RPC_URL="${1#*=}"
      ;;
    --evm-version=*)
      EVM_VERSION="--evm-version ${1#*=}"
      ;;
    --optimizer-runs=*)
      SOLC_OPTIMIZER_CONFIG="--optimize --optimizer-runs ${1#*=}"
      ;;
    --via-ir)
      VIA_IR="--via-ir"
      ;;
    --no-clean)
      NO_CLEAN="true"
      ;;
    --debug)
      DEBUG="true"
      ;;
    *)
      echo "Error: Invalid argument: $1";
      exit 1
  esac
  shift
done


if [[ "$CONTRACT_NAME" == "" || "$DEPLOYMENT_TX" == "" || "$PROJECT_REPO" == "" ]]; then
    echo "Error missing required parameters.";
    echo "  Usage: bash ./verify.sh [OPTIONS] --contract=<CONTRACT_NAME> --tx=<DEPLOYMENT_TX> --repo=<GIT_URL>";
    echo "";
    echo "Options:";
    echo "  --rpc=<HTTP_URL>";
    echo "  --commit=<GIT_COMMIT_HASH>";
    echo "  --solc=<SOLC_VERSION>";
    echo "  --optimizer-runs=<NUMBER_OF_RUNS>";
    echo "  --evm-version=<EVM_VERSION_NAME>";
    echo "  --via-ir";
    echo "  --no-clean";
    echo "  --debug";
    exit 1;
fi

# If a commit hash is set, we append it to the tmp folder name
TEMP_FOLDER=/tmp/$CONTRACT_NAME
if [ "$COMMIT" != "" ]; then
    TEMP_FOLDER=$TEMP_FOLDER-$COMMIT
fi

# Clone a fresh version of the repo to a temporary project folder
echo "Cloning Git repo from $PROJECT_REPO...";
git clone --progress $PROJECT_REPO $TEMP_FOLDER > /dev/null 2>&1

# Move into the working directory of the project
cd $TEMP_FOLDER

# Checkout to the specific commit we want
if [ "$COMMIT" != "" ]; then
    echo "Checking out to commit $COMMIT...";
    git checkout $COMMIT 1> /dev/null 2>&1
fi

# Check if foundry/forge is installed
if ! command -v forge >/dev/null 2>&1; then
    echo "Error: Foundry (forge) was not found in your path, is it installed?";
    exit 1;
fi

# Check if this repo uses forge libraries, if so install them
if [ -f "foundry.toml" ]; then
    # Clone the submodules
    forge install 1> /dev/null
fi 

# Check if this repo uses npm packages, if so install them
if [ -f "package.json" ]; then
  # See if we can use yarn, otherwise check if we can use npm
  if command -v yarn >/dev/null 2>&1; then
    echo "Installing project dependicies using yarn..."
    #yarn upgrade
    yarn install 1> /dev/null
  elif command -v npm >/dev/null 2>&1; then
    echo "Installing project dependicies using npm..."
    npm install 1> /dev/null
  else
    echo "Error: No package manager was found. Install Yarn or NPM."
    exit 1;
  fi
fi

echo "Fetching deployment transaction bytecode...";
DEPLOYMENT_BYTECODE=$(cast tx --rpc-url $RPC_URL $DEPLOYMENT_TX input)
# We remove the solc metadata from the end of the bytecode
DEPLOYMENT_BYTECODE=$(echo $DEPLOYMENT_BYTECODE |  awk -F "$SOLC_METADATA_DELIMITER" '{print $1}')
if [ "$DEBUG" != "" ]; then echo $DEPLOYMENT_BYTECODE; fi

echo "Building bytecode from local source code...";
BUILD_BYTECODE=$(forge inspect $EVM_VERSION --force $VIA_IR $SOLC_OPTIMIZER_CONFIG $SOLC_VERSION $CONTRACT_NAME bytecode)
# We remove the solc metadata from the end of the bytecode
BUILD_BYTECODE=$(echo $BUILD_BYTECODE | awk -F "$SOLC_METADATA_DELIMITER" '{print $1}')
if [ "$DEBUG" != "" ]; then echo $BUILD_BYTECODE; fi

#echo $(forge inspect --force $CONTRACT_NAME deployed_bytecode)
if [ "$DEPLOYMENT_BYTECODE" == "$BUILD_BYTECODE" ]; then
    echo "Contracts match ✅"
else
    echo "Contracts do not match ❌"
fi

# Get out of the temp folder and delete it
cd ~
if [ "$NO_CLEAN" == "" ]; then rm -rf $TEMP_FOLDER; fi