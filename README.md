# Git bytecode verifier
Check if a deployed contract matches the source code as seen on Git. Useful to verify that a contract is the approved version before granting it permissions or interacting with it.

## Disclaimer
This script does not check the arguments the contract was deployed with, it only verifies that the bytecode matches the one from the specified repository(/commit).

# Usage

```
bash ./verify.sh [OPTIONS] --contract=<CONTRACT_NAME> --tx=<DEPLOYMENT_TX> --repo=<GIT_URL>";
```

Additional options:
| Option  | Description  |
|---|---|
|`--contract=<NAME>` | The name of the contract to compile (ex. Counter)|
|`--tx=<HASH>` | Transaction hash in which the contract got deployed |
|`--repo=<GIT_URL>` | URL of the repo where the contract is located|
|`--rpc=<HTTP_URL>` | RPC to use to fetch the transaction data  |
|`--commit=<HASH>`| Git commit hash to match against |
|`--solc=<VERSION>`| Solc version to compile with (ex  0.18.6)|
|`--optimizer-runs=<N>`| If set the optimizer gets enabled and ran with the N specified (ex. 200)|
|`--evm-version=<NAME>`| EVM version to compile for (ex. london)|
|`--via-ir`|Will compile using the yul pipeline|
|`--debug`|Will dump the bytecode to stdout|
|   |   |


## Examples
These contracts match!
```
bash verify.sh \
    --solc=0.8.17 \
    --evm-version=london \
    --contract=JBTiered721DelegateProjectDeployer \
    --optimizer-runs=200 \
    --repo=https://github.com/jbx-protocol/juice-721-delegate \
    --commit=f3137a055221931b17eeb09b0e44af933f0f4e3a \
    --tx=0xf8973b6aa565155ff312fbcaf716b979e6accd240169ffc0db828cdf91416b2d
```
But if we remove the git commit, they no longer match, as the contract has been modified on git since the deploy was done.
```
bash verify.sh \
    --solc=0.8.17 \
    --evm-version=london \
    --contract=JBTiered721DelegateProjectDeployer \
    --optimizer-runs=200 \
    --repo=https://github.com/jbx-protocol/juice-721-delegate \
    --tx=0xf8973b6aa565155ff312fbcaf716b979e6accd240169ffc0db828cdf91416b2d
```

# Install & Requirements
In order to use this you need to have installed the following:
- Bash
- [Foundry](https://getfoundry.sh/)
- [Yarn](https://yarnpkg.com/)

Clone or download the `verify.sh` script.