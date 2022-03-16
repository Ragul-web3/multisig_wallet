const { expectRevert } = require("../node_modules/@openzeppelin/test-helpers");
const {
  web3,
} = require("../node_modules/@openzeppelin/test-helpers/src/setup");
const Multisig = artifacts.require("MultiSigWallet.sol");

contract("Multisig", (accounts) => {
  let wallet;
  beforeEach(async () => {
    wallet = await Multisig.new([
      accounts[0],
      accounts[1],
      accounts[2],
      accounts[3],
    ]);
    await web3.eth.sendTransaction({
      from: accounts[0],
      to: wallet.address,
      value: 1000,
    });
  });

  it("should have the correct owners", async () => {
    const owners = await wallet.getOwners();

    assert(owners.length === 4);
    assert(owners[0] === accounts[0]);
    assert(owners[1] === accounts[1]);
    assert(owners[2] === accounts[2]);
    assert(owners[3] === accounts[3]);
  });

  it("should submit transaction but not approve without others", async () => {
    const transactions_initial = await wallet.getValidTransactions();
    assert(transactions_initial.length === 0);

    await wallet.submitTransaction(accounts[5], 100, "0x00", {
      from: accounts[0],
    });

    const transactions = await wallet.getValidTransactions();
    assert(transactions.length === 0);
  });

  it("should NOT create a transfer if sender is not one of the approvers", async () => {
    await expectRevert(
      wallet.submitTransaction(accounts[5], 100, "0x00", {
        from: accounts[6],
      }),
      "You are not authorized for this action."
    );
  });

  it("Should send the transfer if quorum is reached", async () => {
    await wallet.submitTransaction(accounts[5], 100, "0x00", {
      from: accounts[0],
    });
    await wallet.confirmTransaction(0, { from: accounts[1] });
    const transactions = await wallet.getValidTransactions();
    assert(transactions[0].executed === true);
  });

  it("Should NOT approve the transfer if sender is not approved", async () => {
    await wallet.submitTransaction(accounts[5], 100, "0x00", {
      from: accounts[0],
    });
    await expectRevert(
      wallet.confirmTransaction(0, { from: accounts[4] }),
      "You are not authorized for this action."
    );
  });

  it("Should NOT approve the transfer if transfer is already has been sent", async () => {
    await wallet.submitTransaction(accounts[5], 100, "0x00", {
      from: accounts[0],
    });
    await wallet.confirmTransaction(0, { from: accounts[1] });
    await expectRevert(
      wallet.confirmTransaction(0, { from: accounts[2] }),
      "This transaction has already been executed."
    );
  });
});
