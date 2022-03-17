### Overview

- A scalable multi-signature wallet contract, which requires a minimum of 60% authorisation by the signatory wallets to perform a transaction. 
- Access registry contract that stores the signatories of this multi-sig wallet by address. This access registry contract has its own admin. Capable of adding, revoking, renouncing, and transfer of signatory functionalities.

### Testnet Deploy

- Contract address: 0x9d09DA959BBdcf7978416dE54532bd711454c676
- [Ropsten Network Deployement here](https://ropsten.etherscan.io/address/0x9d09DA959BBdcf7978416dE54532bd711454c676)

### Installation and testing

Install global dependencies:

- npm install -g truffle

Install local dependencies:

- npm install

To run the tests:
- Make sure ganache is running a testnet.
- trufflle migrate
- truffle test
