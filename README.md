# mbc2023-enrollment

Motoko Bootcamp enrollment 2023

- [Source](https://medium.com/code-state/motoko-bootcamp-updates-for-students-2-3-ba9f9ca31f5b)
- [Walkthrough](https://inspire3.notion.site/Step-by-step-enrollment-guide-for-Motoko-Bootcamp-2023-eaa53db876fb43b49e4d72992ae2c12b)

## Commands

### Identity

- Create a new identity

```bash
IDENTITY_NAME="motoko_bootcamp_2023"

dfx identity new "${IDENTITY_NAME}"
```

- Use the newly created identity

```bash
dfx identity use "${IDENTITY_NAME}"
```

- List all identities and look for the `*` to indicate the active identity.

```bash
dfx identity list
```

- Get the account ID and then transfer IC into that ID

```bash
dfx ledger --network ic account-id
```

- Once the transfer is complete, check the balance

```bash
dfx ledger --network ic balance
```

### Wallet canister

- Get the principle ID

```bash
dfx identity get-principal

PRINCIPLE_ID=
```

- Create a cycles wallet to hold the cycles for the application

```bash
dfx ledger --network ic create-canister "${PRINCIPLE_ID}" --amount 1.0
```

- Capture the canister ID from the above command

```bash
WALLET_CANISTER_ID=
```

- Deploy the wallet module into this newly created canister

```bash
dfx identity --network ic deploy-wallet "${WALLET_CANISTER_ID}"
```

- Show the cycles balance of the wallet

```bash
dfx wallet --network ic balance
```

- To top up a wallet, you can run this command

```bash
dfx ledger --network ic top-up --amount 1.0 "${WALLET_CANISTER_ID}"
```

- Show your ledger and wallet balances

```bash
dfx ledger --network ic balance
dfx wallet --network ic balance
```

### Application canisters

- Make a source code directory for your application

```bash
mkdir -p src
```

- Add the following your .gitignore

```bash
cat << EOF >> .gitignore
# Exclude regeneratable code
.dfx
EOF
```

- Create your application source code

```bash
cat << EOF > src/main.mo
actor {
  public func greet(name : Text) : async Text {
    return ("Hello" # name # "!")
  };
};
EOF
```

- Create your `dfx.json` to describe your canisters.

```bash
cat << EOF > dfx.json
{
  "canisters": {
    "greeter": {
      "main": "src/main.mo",
      "type": "motoko"
    }
  }
}
EOF
```

#### Test locally

- Deploy the canister locally and try it out

```bash
CANISTER_NAME="greeter"

dfx start --clean --background
dfx deploy

# Should return 'Hello World!"
dfx canister call "${CANISTER_NAME}" greet '(" World")'

dfx stop
```

#### Ship It!

- Create each canister on the IC network.

```bash
CANISTER_NAME="greeter"

dfx canister --network ic create "${CANISTER_NAME}" --with-cycles 1000000000000
```

- The command creates a `canister_ids.json` file with the recorded canister IDs

```bash
git add canister_ids.json
git commit -m "feat: Capture canister IDs"
```

- Build the WASM for installation into the canister

```bash
dfx build --network ic ${CANISTER_NAME}
```

- Install the WASM into the canister

```bash
dfx canister --network ic install ${CANISTER_NAME}
```

- Test the canister remotely using `dfx`

```bash
dfx canister --network ic call ${CANISTER_NAME} greet '(" world")'
```

- Get the canister ID from the IC deployed canister

```bash
dfx canister id --network ic ${CANISTER_NAME}
```

- Head over to [icscan.io](https://icscan.io/canister) and put in the canister ID.

- Enter some text and press the `Call` button to execute the canister.

- Select `Anonymous call` in the popup and press `Call your method` button

- If `Hello World!` is returned, then you are finished!

- Capture the information you need and fill out the [Google form](https://forms.gle/3Pkna87o5ynyFvHC8)

    - Email address
    - Discord username
    - GitHub profile URL
    - Live on-chain canister ID

