## Day 12 - Foundry Configs & Compiler Settings (MultiSig Wallet)

### A compact demo that shows Solidity compiler settings, optimizer tuning, formatting, and gas reporting using a tiny MultiSig Wallet. Clean, reproducible dev flow for real-world projects.

## Key Takeaways

- Use foundry.toml to control compiler version, optimizer, and EVM settings.
- Run forge fmt, forge build, forge test, forge test --gas-report to validate code & costs.
- forge-std gives handy cheatcodes: vm.prank, vm.deal, expectRevert, assertEq, etc.
- Profiles are a concept in Foundry; my current version doesn’t support --profile flags — we can update if we want to run --profile.
- Keep formatting consistent via forge fmt (+ optional .forgefmt.toml).

### Prerequisites

```shell
curl -L https://foundry.paradigm.xyz | bash
foundryup
# (inside the project)
forge install
```

### foundry.toml (example)

```shell
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc_version = "0.8.24"
optimizer = true
optimizer_runs = 200
evm_version = "paris"
bytecode_hash = "none"
gas_reports = ["Wallet"]
```

### (Optional) .forgefmt.toml

```shell
line_length = 100
quote_style = "double"
wrap_comments = true
```

### What Each “Foundry File” Does

- foundry.toml: central config - compiler version, optimizer, EVM, gas reports, paths.
- .forgefmt.toml (optional): formatting preferences (forge fmt uses this).

### Contracts & Tests
#### src/Wallet.sol
##### Minimal 2-of-3 MultiSig example:

- submit(address to, uint value, bytes data) - create a pending tx.
- confirm(txId) / revoke(txId) - manage confirmations.
- execute(txId) - runs the call once confirmations >= required.
- Events: Submit, Confirm, Revoke, Execute.

#### test/Wallet.t.sol
##### Covers success + failure paths:
- Funds the wallet (vm.deal), submits a tx, confirms twice, executes, and asserts the recipient balance increased.
- Negative cases: non-owner submit reverts; executing with insufficient confirms reverts.

### Commands to Run

```shell
forge fmt
# Format Solidity files for clean, consistent style

forge build
# Compile contracts with the optimizer settings from foundry.toml

forge test -vv
# Run tests with verbose logs and assertions

forge test --gas-report
# Run tests + print gas usage per function and deployment cost/size
```

### Sample Outputs
#### Build
```shell
[⠊] Compiling...
[⠢] Compiling 22 files with Solc 0.8.24
[⠆] Solc 0.8.24 finished in 600ms
Compiler run successful!
```
- Meaning: Contracts compiled successfully with the configured compiler & optimizer.

### Test

```shell
Ran 3 tests for test/Wallet.t.sol:WalletTest
[PASS] testRevert_NotOwnerSubmit()         (gas: ~13k–35k)
[PASS] testRevokeFlow()                    (gas: ~150k–330k)
[PASS] testSubmitConfirmExecute()          (gas: ~220k–350k)
Suite result: ok. 3 passed; 0 failed
```

### Gas Report
- You can see per-function gas and deployment metrics; helpful to reason about optimizer runs.

## End of the Project
