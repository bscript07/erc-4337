# MinimalAccount (ERC-4337 Minimal Smart Contract Wallet)

This repository contains a minimal implementation of an [ERC-4337](https://eips.ethereum.org/EIPS/eip-4337)-compatible smart contract account written in Solidity.

The `MinimalAccount` contract allows an EOA (Externally Owned Account) to operate as a smart wallet, enabling programmable transaction logic, meta-transactions, and user operations through an `EntryPoint`.

---

## ✨ Features

- 🔐 Ownable smart account with custom `owner` logic
- 📦 Compatible with ERC-4337 Bundler & EntryPoint
- ✅ Signature validation using EIP-191 (via `ECDSA`)
- 🛠️ Manual execution of arbitrary calls via `execute()`
- ⚙️ Minimal `UserOperation` validation flow

---

## 🔧 Tech Stack

- Solidity `0.8.30`
- [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [ERC-4337 Account Abstraction SDK](https://github.com/eth-infinitism/account-abstraction)
- Foundry (`forge`, `cast`, `anvil`) for testing & scripting

---

## 🧪 Contract Overview

### MinimalAccount.sol


