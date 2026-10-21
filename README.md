# Base Titan Quest Engine

A decentralized Web3 gaming protocol deployed on the Base L2 network. This engine serves as an immutable quest and achievement tracker for on-chain RPGs, allowing game developers to issue verifiable tasks and automatically distribute crypto rewards upon completion.

## Core Game Mechanics
* **State-Driven Progression:** Quest states (Available, In-Progress, Completed, Failed) are rigorously managed via tightly packed `enum` structures to ensure logical progression and prevent reward duplication.
* **Cryptographic Verification:** Integrates ECDSA signature verification to validate off-chain gameplay achievements before triggering on-chain state changes and token mints.
* **Dynamic Reward Scaling:** Features an algorithmic reward pool that adjusts payout multipliers based on the total number of active participants and remaining treasury balances.

## Architecture
Compiled utilizing Solidity `0.8.37`. The protocol strictly isolates player state mappings from core treasury functions, applying the Checks-Effects-Interactions pattern to safeguard the reward pool against reentrancy exploits during claim executions.
