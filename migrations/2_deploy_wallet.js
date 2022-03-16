const multiSigWallet = artifacts.require("MultiSigWallet.sol");

module.exports = async (deployer, network, accounts) => {
  const owners = accounts.slice(0, 4);

  await deployer.deploy(multiSigWallet, owners);
};
