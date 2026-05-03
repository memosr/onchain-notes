# 📝 OnchainNotes

**Your personal notebook, permanently on Base.**

[![Base Network](https://img.shields.io/badge/network-Base%20Mainnet-0052FF?logo=coinbase&logoColor=white)](https://base.org)
[![Solidity](https://img.shields.io/badge/solidity-%5E0.8.20-363636?logo=solidity)](https://soliditylang.org)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Tests](https://img.shields.io/badge/forge%20tests-passing-brightgreen)](test/OnchainNotes.t.sol)

---

## 🌐 Live Demo

> **[→ Open OnchainNotes](https://memosr.github.io/onchain-notes/)**  
> Connect your wallet and start writing — no sign-up, no server, no middleman.

---

## Why on-chain notes?

Your notes belong to you — not to a company that can go offline, change their terms, or sell your data. OnchainNotes stores every note directly on Base, an Ethereum L2, tied to your wallet address. As long as the blockchain exists, your notes exist. No account required. No password to lose. Just your wallet.

---

## ✨ Features

- 🔐 **Wallet-owned** — only your address can read, write, or delete your notes
- ✍️ **Full CRUD** — create, edit, and delete notes on-chain
- 🎨 **Color tags** — six colors to organize at a glance
- 🔍 **Instant search** — filter notes by title or content client-side
- 📋 **Copy to clipboard** — one click to copy any note's content
- ⛽ **Permissionless** — no fees beyond standard Base gas (fractions of a cent)
- 🌐 **No backend** — pure static frontend, served from GitHub Pages

---

## How it works

```
1. Connect wallet        →   Your MetaMask (or any injected wallet) signs in via ethers.js v6
2. Write a note          →   Calls createNote() on the contract — stored permanently on Base
3. Read / edit / delete  →   All operations gated by msg.sender — only you see your notes
```

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Smart contract | Solidity `^0.8.20` |
| Testing & deployment | [Foundry](https://book.getfoundry.sh/) (Forge, Cast, Anvil) |
| Blockchain | [Base Mainnet](https://base.org) (chainId 8453) |
| Wallet integration | [ethers.js v6](https://docs.ethers.org/v6/) |
| Frontend | Vanilla JS, HTML, CSS |
| Hosting | GitHub Pages |

---

## 📄 Deployed Contract

| | |
|---|---|
| **Address** | [`0xc9ccC404749895Cf45691897429e130E0a418200`](https://basescan.org/address/0xc9ccc404749895cf45691897429e130e0a418200) |
| **Network** | Base Mainnet (chainId 8453) |
| **Explorer** | [View on Basescan](https://basescan.org/address/0xc9ccc404749895cf45691897429e130e0a418200) |

---

## 💻 Local Development

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) — `curl -L https://foundry.paradigm.xyz | bash`
- A Base RPC URL (e.g. from [Alchemy](https://www.alchemy.com/) or [QuickNode](https://www.quicknode.com/))

### Clone & build

```bash
git clone https://github.com/memosr/onchain-notes.git
cd onchain-notes
forge install
forge build
```

### Run tests

```bash
forge test -v
```

All 18 tests cover CRUD operations, ownership enforcement, input validation, and multi-user isolation.

### Deploy to Base

```bash
export PRIVATE_KEY=<your_deployer_private_key>
export BASE_RPC_URL=<your_base_rpc_url>

forge script script/Deploy.s.sol:DeployScript \
  --rpc-url $BASE_RPC_URL \
  --broadcast \
  --verify
```

### Run frontend locally

The frontend is plain HTML/JS — open `index.html` directly in a browser, or serve it:

```bash
npx serve .
```

---

## 🏗 Contract Architecture

**`src/OnchainNotes.sol`**

### Data structure

```solidity
struct Note {
    uint256 id;
    address owner;
    string  title;      // max 100 bytes
    string  content;    // max 2000 bytes
    uint256 createdAt;
    uint256 updatedAt;
}
```

### Write functions

| Function | Description |
|---|---|
| `createNote(title, content)` | Creates a new note owned by `msg.sender`; returns the new `noteId` |
| `updateNote(noteId, title, content)` | Updates an existing note; reverts if caller is not the owner |
| `deleteNote(noteId)` | Soft-deletes a note; reverts if caller is not the owner |

### Read functions

| Function | Description |
|---|---|
| `getMyNotes()` | Returns all active notes for `msg.sender` |
| `getNoteCount(address)` | Returns the active note count for any address |

### Events

| Event | Emitted when |
|---|---|
| `NoteCreated(noteId, owner, title)` | A new note is created |
| `NoteUpdated(noteId, owner, title)` | A note's title or content is changed |
| `NoteDeleted(noteId, owner)` | A note is deleted |

### Custom errors

| Error | Condition |
|---|---|
| `NotOwner(noteId, caller)` | Caller is not the note's owner |
| `NoteAlreadyDeleted(noteId)` | Attempting to update or delete an already-deleted note |
| `EmptyTitle()` | Title string is empty |
| `TitleTooLong(length, max)` | Title exceeds 100 bytes |
| `ContentTooLong(length, max)` | Content exceeds 2 000 bytes |

---

## 🤝 Contributing

Contributions are welcome! Here's how:

1. Fork the repo and create a feature branch
2. Make your changes and add tests for any new contract behaviour
3. Run `forge test` — all tests must pass
4. Open a pull request with a clear description

Please keep PRs focused. Bug fixes and small improvements are preferred over large refactors without prior discussion.

---

## License

[MIT](LICENSE) — use it, fork it, build on it.
