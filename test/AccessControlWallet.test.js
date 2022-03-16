const { expect, assert } = require("chai");
const { expectRevert } = require("../node_modules/@openzeppelin/test-helpers");
const {
    web3,
} = require("../node_modules/@openzeppelin/test-helpers/src/setup");

const accessControlWallet = artifacts.require("AccessControlWallet.sol");
const multiSigWallet = artifacts.require("MultiSigWallet.sol");

contract("AccessControlWallet", function (accounts) {
    let wallet;
    beforeEach(async () => {
        wallet = await multiSigWallet.new([accounts[0],
        accounts[1],
        accounts[2],
        accounts[3],]);

        await web3.eth.sendTransaction({
            from: accounts[0],
            to: wallet.address,
            value: 1000,
        });

        accessControl = await accessControlWallet.new(wallet.address)
    });

    it("should add owners to wallet", async () => {
        let owners_initial = accessControl.getOwners();

        await accessControl.addOwner(accounts[5], {
            from: accounts[0],
        });

        let owners_final = accessControl.getOwners();
        assert(owners_final, owners_initial + 1, "New owners weren't added successfully");
    });

    // it("should NOT add owners to wallet is called is not approved", async () => {
    //     await expectRevert(
    //         accessControl.addOwner(accounts[5], {
    //             from: accounts[10],
    //         }),
    //         "Admin restricted function"
    //     )
    // });
});
