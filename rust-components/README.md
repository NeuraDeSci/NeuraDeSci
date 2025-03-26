# NeuraDeSci Rust Components

This directory contains the Rust implementation of core functionality for the NeuraDeSci platform, providing high-performance, secure operations for neuroscience data management through WebAssembly.

## Overview

The NeuraDeSci Rust components provide:

- Cryptographic operations for secure data handling
- IPFS integration for decentralized storage
- Neural data processing utilities
- Blockchain integration for data provenance
- WebAssembly bindings for JavaScript integration

## Architecture

The codebase is organized into the following modules:

- `crypto.rs`: Cryptographic utilities including hashing, encryption, and signatures
- `ipfs.rs`: Integration with IPFS for decentralized storage
- `neural_data.rs`: Data structures and processing for neuroscience data
- `blockchain.rs`: Blockchain operations for data provenance and transactions
- `wasm_bridge.rs`: WebAssembly bindings for JavaScript integration

## Building

To build the Rust components:

```bash
cd rust-components
cargo build
```

For WebAssembly builds:

```bash
wasm-pack build --target web
```

## Using in JavaScript

After building with wasm-pack, you can import the components in your JavaScript:

```javascript
import * as neuradesci from 'neuradesci-core';

// Create a neuroscience dataset
const dataset = new neuradesci.WasmNeuroscienceDataset(
    "Alzheimer's EEG Study", 
    "Using EEG to study brain activity in Alzheimer's patients", 
    "researcher_001"
);

// Generate keypair for encryption
const keys = neuradesci.generate_keys();

// Create EEG data
const eegData = await neuradesci.create_eeg_data(256.0, "patient_123", "Dr. Smith");

// Upload to IPFS
const jsonData = JSON.stringify(eegData);
const ipfsResult = await neuradesci.upload_to_ipfs(jsonData, "alzheimer_eeg_study.json");

// Access example
const transaction = await neuradesci.create_neural_data_transaction(
    "researcher_001",
    "researcher_002",
    ipfsResult.cid,
    keys.privateKey
);
```

## Testing

Run the test suite:

```bash
cargo test
```

## Integration with the NeuraDeSci Platform

These Rust components are designed to be integrated with the main NeuraDeSci platform, providing high-performance operations while maintaining the security and reliability needed for neuroscience research data.

The WebAssembly interface allows these components to be used directly from JavaScript in the main web application, combining the performance of Rust with the accessibility of web technologies.

## Future Extensions

- Advanced neural data analysis algorithms
- Enhanced blockchain integration with Solidity contracts
- Real-time neural data processing
- Support for additional data formats and protocols 