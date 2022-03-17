const { assert } = require("chai");
const { expectRevert } = require("../node_modules/@openzeppelin/test-helpers");
const {
    web3,
} = require("../node_modules/@openzeppelin/test-helpers/src/setup");
const truffleAssert = require('truffle-assertions');
const accessControlWallet = artifacts.require("AccessControlWallet.sol");
const multiSigWallet = artifacts.require("MultiSigWallet.sol");

contract("AccessControlWallet", function (accounts) {
    let wallet;
    beforeEach(async () => {
        accs = [accounts[0],
        accounts[1],
        accounts[2],
        accounts[3],];
        wallet = await multiSigWallet.new(accs);

        await web3.eth.sendTransaction({
            from: accounts[0],
            to: wallet.address,
            value: 1000,
        });

        accessControl = await accessControlWallet.new(wallet.address, accs)
    });

    it("should add owners to wallet", async () => {
        let owners_initial = accessControl.getOwners();

        await accessControl.addOwner(accounts[5], {
            from: accounts[0],
        });

        let owners_final = accessControl.getOwners();
        assert(owners_final, owners_initial + 1, "New owners weren't added successfully");
    });

    it("should NOT add owners to wallet if call is not approved", async () => {
        await expectRevert(
            accessControl.addOwner(accounts[7], {
                from: accounts[6],
            }),
            "Admin restricted function"
        )
    });

    it("should remove owners from wallet", async () => {
        await accessControl.addOwner(accounts[7], {
            from: accounts[0],
        });

        let owners_initial = accessControl.getOwners();

        await accessControl.removeOwner(accounts[7], {
            from: accounts[0],
        });

        let owners_final = accessControl.getOwners();
        assert(owners_final, owners_initial - 1, "Owners wasn't removed successfully");
    });

    it("should NOT remove owners from wallet if call is not approved", async () => {
        await accessControl.addOwner(accounts[7], {
            from: accounts[0],
        });

        await expectRevert(
            accessControl.removeOwner(accounts[7], {
                from: accounts[6],
            }),
            "Admin restricted function"
        )
    });

    it("should transfer admin role to another account", async () => {
        // await accessControl.addOwner(accounts[1], {
        //     from: accounts[0],
        // });

        await accessControl.renounceAdmin(accounts[1]);
        let final_admin = await accessControl.getAdmin();

        assert(final_admin, accounts[1], "Admin transfer was unsuccessful");
    });

    it("should swap addresses for wallet owners", async () => {
        // await accessControl.addOwner(accounts[1], {
        //     from: accounts[0],
        // });

        let transfer = await accessControl.transferOwner(accounts[1], accounts[5]);

        truffleAssert.eventEmitted(transfer, 'OwnerAddition', (e) => {
            return e.owner === accounts[5]
        })
    })
});
