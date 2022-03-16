const multiSigWallet = artifacts.require("MultiSigWallet.sol");
const accessControlWallet = artifacts.require("AccessControlWallet.sol");

module.exports = async (deployer, network, accounts) => {
  const owners = accounts.slice(0, 5);

  await deployer.deploy(multiSigWallet, owners);
  console.log("MultiSig Wallet deployed");

  await deployer.deploy(accessControlWallet);
  console.log("Access Control for Wallet deployed");
};
