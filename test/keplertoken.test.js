const chai = require("chai");
const expect = chai.expect;

describe("KeplerToken", () => {

    before(async function () {
        await deployments.fixture(['KeplerToken']);
        this.keplerToken = await ethers.getContract('KeplerToken');
        let { deployer } = await ethers.getNamedSigners();
        this.deployer = deployer;
        let signers = await ethers.getSigners();
        this.caller = signers[9];
    });

    beforeEach(async function () {
    });

    it("setSnapshotCreateCaller", async function() {
        await expect(this.keplerToken.connect(this.caller).createSnapshot('1')).to.be.revertedWith('only snapshotCreateCaller can do this');
        await this.keplerToken.connect(this.deployer).setSnapshotCreateCaller(this.caller.address);
        await expect(this.keplerToken.connect(this.caller).createSnapshot('0')).to.be.revertedWith('illegal snapshotId');
        expect(await this.keplerToken.currentSnapshotId()).to.be.equal('0');
        await this.keplerToken.connect(this.caller).createSnapshot('1');
        expect(await this.keplerToken.currentSnapshotId()).to.be.equal('1');
        expect(await this.keplerToken.balanceOf(this.caller.address)).to.be.equal('0');
        await this.keplerToken.connect(this.deployer).mint(this.caller.address, '1000000000000000000');
        expect(await this.keplerToken.balanceOf(this.caller.address)).to.be.equal('1000000000000000000');
        expect(await this.keplerToken.getUserSnapshot(this.caller.address)).to.be.equal('0');
        await this.keplerToken.connect(this.caller).transfer(this.deployer.address, '100000000000000000');
        expect(await this.keplerToken.getUserSnapshot(this.caller.address)).to.be.equal('0');
        await this.keplerToken.connect(this.caller).createSnapshot('2');
        expect(await this.keplerToken.currentSnapshotId()).to.be.equal('2');
        expect(await this.keplerToken.getUserSnapshot(this.caller.address)).to.be.equal('900000000000000000');
        await this.keplerToken.connect(this.caller).transfer(this.deployer.address, '100000000000000000');
        expect(await this.keplerToken.getUserSnapshot(this.caller.address)).to.be.equal('900000000000000000');
    });

});
