//const { TOKEN, RICHACCOUNT } = require('../config/address.js');
const chai = require("chai");
const expect = chai.expect;
//console.dir(chai);
//chai.should()
//chai.use(chaiAsPromised)

describe("Swap", () => {

    before(async function () {
        await deployments.fixture(['MockToken', 'KeplerFactory', 'KeplerRouter', 'FeeDispatcher', 'KeplerToken', 'MasterChef', 'Inviter', 'Lens', 'LuckyPool']);
        let { deployer } = await ethers.getNamedSigners();
        this.deployer = deployer;
        this.keplerFactory = await ethers.getContract('KeplerFactory');
        this.keplerRouter = await ethers.getContract('KeplerRouter');
        this.feeDispatcher = await ethers.getContract('FeeDispatcher');
        this.keplerToken = await ethers.getContract('KeplerToken');
        this.masterChef = await ethers.getContract('MasterChef');
        this.inviterContract = await ethers.getContract('Inviter');
        this.luckyPool = await ethers.getContract('LuckyPool');
        this.lens = await ethers.getContract('Lens');
        this.user = await ethers.getContract('User');
        this.WBNB = await ethers.getContract('MockToken_WBNB');
        this.USDT = await ethers.getContract('MockToken_USDT');
        this.AAVE = await ethers.getContract('MockToken_AAVE');

        let signers = await ethers.getSigners();
        this.inviter = signers[1];
        this.caller = signers[2];
        this.destination1 = signers[9];
        this.destination2 = signers[8];
        this.destination3 = signers[7];
        this.destination4 = signers[6];
        this.destination5 = signers[5];
        this.destination6 = signers[4];
        this.destination7 = signers[3];
        
        this.fund = this.destination1;
        this.vote = this.destination2;
    });

    beforeEach(async function () {
    });

    it("AddDefaultDestination", async function() {
        expect(await this.feeDispatcher.defaultDestinationLength()).to.be.equal('0');

        await this.feeDispatcher.addDefaultDestination(this.destination1.address, '7500', 0);
        await this.feeDispatcher.addDefaultDestination(this.destination2.address, '500', 1);
        await this.feeDispatcher.addDefaultDestination(this.destination3.address, '1000', 2);
        await this.feeDispatcher.addDefaultDestination(this.destination4.address, '500', 3);
        await this.feeDispatcher.addDefaultDestination(this.destination5.address, '100', 4);
        await this.feeDispatcher.addDefaultDestination(this.destination5.address, '400', 5);
        expect(await this.feeDispatcher.defaultDestinationLength()).to.be.equal('6');
        await expect(this.feeDispatcher.addDefaultDestination(this.destination5.address, '400', 5)).to.be.revertedWith('illegal totalPercent');
        await this.feeDispatcher.delDefaultDestination(5);
        expect(await this.feeDispatcher.defaultDestinationLength()).to.be.equal('5');
        await this.feeDispatcher.delDefaultDestination(2);
        expect(await this.feeDispatcher.defaultDestinationLength()).to.be.equal('4');
        await this.feeDispatcher.delDefaultDestination(0);
        await this.feeDispatcher.delDefaultDestination(0);
        await this.feeDispatcher.delDefaultDestination(0);
        await this.feeDispatcher.delDefaultDestination(0);
        expect(await this.feeDispatcher.defaultDestinationLength()).to.be.equal('0');
    });

    it("AddTokenDestination", async function() {
        expect(await this.feeDispatcher.tokenDestinationLength(this.keplerToken.address)).to.be.equal('0');

        await this.feeDispatcher.addTokenDestination(this.keplerToken.address, this.destination1.address, '7500', 0);
        await this.feeDispatcher.addTokenDestination(this.keplerToken.address, this.destination2.address, '500', 1);
        await this.feeDispatcher.addTokenDestination(this.keplerToken.address, this.destination3.address, '1000', 2);
        await this.feeDispatcher.addTokenDestination(this.keplerToken.address, this.destination4.address, '500', 3);
        await this.feeDispatcher.addTokenDestination(this.keplerToken.address, this.destination5.address, '100', 4);
        await this.feeDispatcher.addTokenDestination(this.keplerToken.address, this.destination5.address, '400', 5);
        expect(await this.feeDispatcher.tokenDestinationLength(this.keplerToken.address)).to.be.equal('6');
        await expect(this.feeDispatcher.addTokenDestination(this.keplerToken.address, this.destination5.address, '400', 5)).to.be.revertedWith('illegal totalPercent');
        await this.feeDispatcher.delTokenDestination(this.keplerToken.address, 5);
        expect(await this.feeDispatcher.tokenDestinationLength(this.keplerToken.address)).to.be.equal('5');
        await this.feeDispatcher.delTokenDestination(this.keplerToken.address, 2);
        expect(await this.feeDispatcher.tokenDestinationLength(this.keplerToken.address)).to.be.equal('4');
        await this.feeDispatcher.delTokenDestination(this.keplerToken.address, 0);
        await this.feeDispatcher.delTokenDestination(this.keplerToken.address, 0);
        await this.feeDispatcher.delTokenDestination(this.keplerToken.address, 0);
        await this.feeDispatcher.delTokenDestination(this.keplerToken.address, 0);
        expect(await this.feeDispatcher.tokenDestinationLength(this.keplerToken.address)).to.be.equal('0');
    });

    it("AddRelateDestination", async function() {
        expect(await this.feeDispatcher.relateDestinationLength(this.keplerToken.address)).to.be.equal('0');

        await this.feeDispatcher.addRelateDestination(this.keplerToken.address, this.destination1.address, '7500', 0);
        await this.feeDispatcher.addRelateDestination(this.keplerToken.address, this.destination2.address, '500', 1);
        await this.feeDispatcher.addRelateDestination(this.keplerToken.address, this.destination3.address, '1000', 2);
        await this.feeDispatcher.addRelateDestination(this.keplerToken.address, this.destination4.address, '500', 3);
        await this.feeDispatcher.addRelateDestination(this.keplerToken.address, this.destination5.address, '100', 4);
        await this.feeDispatcher.addRelateDestination(this.keplerToken.address, this.destination5.address, '400', 5);
        expect(await this.feeDispatcher.relateDestinationLength(this.keplerToken.address)).to.be.equal('6');
        await expect(this.feeDispatcher.addRelateDestination(this.keplerToken.address, this.destination5.address, '400', 5)).to.be.revertedWith('illegal totalPercent');
        await this.feeDispatcher.delRelateDestination(this.keplerToken.address, 5);
        expect(await this.feeDispatcher.relateDestinationLength(this.keplerToken.address)).to.be.equal('5');
        await this.feeDispatcher.delRelateDestination(this.keplerToken.address, 2);
        expect(await this.feeDispatcher.relateDestinationLength(this.keplerToken.address)).to.be.equal('4');
        await this.feeDispatcher.delRelateDestination(this.keplerToken.address, 0);
        await this.feeDispatcher.delRelateDestination(this.keplerToken.address, 0);
        await this.feeDispatcher.delRelateDestination(this.keplerToken.address, 0);
        await this.feeDispatcher.delRelateDestination(this.keplerToken.address, 0);
        expect(await this.feeDispatcher.relateDestinationLength(this.keplerToken.address)).to.be.equal('0');
    });

    it("Registe", async function() {
        await this.user.connect(this.inviter).registe('0x0000000000000000000000000000000000000001');
        await this.user.connect(this.caller).registe(this.inviter.address);
    });

    it("CreateAndDeposit", async function() {
        await this.USDT.mint(this.caller.address, '10000000000000000000');
        await this.AAVE.mint(this.caller.address, '10000000000000000000');
        
        await this.USDT.connect(this.caller).approve(this.keplerRouter.address, '10000000000000000000');
        await this.AAVE.connect(this.caller).approve(this.keplerRouter.address, '10000000000000000000');
        
        expect(await this.keplerFactory.getPair(this.USDT.address, this.AAVE.address)).to.be.equal('0x0000000000000000000000000000000000000000');
        await this.keplerRouter.connect(this.caller).addLiquidity(
            this.USDT.address,
            this.AAVE.address,
            '10000000000000000000',
            '10000000000000000000',
            '10000000000000000000',
            '10000000000000000000',
            this.caller.address,
            Math.floor(new Date().getTime() / 1000) + 1000,
        );
        expect(await this.USDT.balanceOf(this.caller.address)).to.be.equal('0');
        expect(await this.AAVE.balanceOf(this.caller.address)).to.be.equal('0');
        expect(await this.keplerFactory.getPair(this.USDT.address, this.AAVE.address)).to.be.not.equal('0x0000000000000000000000000000000000000000');
        this.pairUSDT_AAVE = await ethers.getContractAt('KeplerPair', await this.keplerFactory.getPair(this.USDT.address, this.AAVE.address));
        expect(await this.pairUSDT_AAVE.balanceOf(this.caller.address)).to.be.equal('10000000000000000000');

        await this.USDT.mint(this.inviter.address, '10000000000000000000');
        await this.AAVE.mint(this.inviter.address, '10000000000000000000');
        
        await this.USDT.connect(this.inviter).approve(this.keplerRouter.address, '10000000000000000000');
        await this.AAVE.connect(this.inviter).approve(this.keplerRouter.address, '10000000000000000000');
        
        //expect(await this.keplerFactory.getPair(this.USDT.address, this.AAVE.address)).to.be.equal('0x0000000000000000000000000000000000000000');
        await this.keplerRouter.connect(this.inviter).addLiquidity(
            this.USDT.address,
            this.AAVE.address,
            '10000000000000000000',
            '10000000000000000000',
            '10000000000000000000',
            '10000000000000000000',
            this.inviter.address,
            Math.floor(new Date().getTime() / 1000) + 1000,
        );
        expect(await this.USDT.balanceOf(this.inviter.address)).to.be.equal('0');
        expect(await this.AAVE.balanceOf(this.inviter.address)).to.be.equal('0');
        //expect(await this.keplerFactory.getPair(this.USDT.address, this.AAVE.address)).to.be.not.equal('0x0000000000000000000000000000000000000000');
        //this.pairUSDT_AAVE = await ethers.getContractAt('KeplerPair', await this.keplerFactory.getPair(this.USDT.address, this.AAVE.address));
        expect(await this.pairUSDT_AAVE.balanceOf(this.inviter.address)).to.be.equal('10000000000000000000');

        await this.USDT.mint(this.caller.address, '10000000000000000000');
        await this.keplerToken.connect(this.deployer).mint(this.caller.address, '10000000000000000000');
        
        await this.USDT.connect(this.caller).approve(this.keplerRouter.address, '10000000000000000000');
        await this.keplerToken.connect(this.caller).approve(this.keplerRouter.address, '10000000000000000000');
        
        expect(await this.keplerFactory.getPair(this.USDT.address, this.keplerToken.address)).to.be.equal('0x0000000000000000000000000000000000000000');
        await this.keplerRouter.connect(this.caller).addLiquidity(
            this.USDT.address,
            this.keplerToken.address,
            '10000000000000000000',
            '10000000000000000000',
            '10000000000000000000',
            '10000000000000000000',
            this.caller.address,
            Math.floor(new Date().getTime() / 1000) + 1000,
        );
        expect(await this.USDT.balanceOf(this.caller.address)).to.be.equal('0');
        expect(await this.keplerToken.balanceOf(this.caller.address)).to.be.equal('0');
        expect(await this.keplerFactory.getPair(this.USDT.address, this.keplerToken.address)).to.be.not.equal('0x0000000000000000000000000000000000000000');
        this.pairUSDT_SDS = await ethers.getContractAt('KeplerPair', await this.keplerFactory.getPair(this.USDT.address, this.keplerToken.address));
        expect(await this.pairUSDT_SDS.balanceOf(this.caller.address)).to.be.equal('10000000000000000000');
    });

    it("LockLiquidity", async function() {
        await this.pairUSDT_AAVE.connect(this.caller).approve(this.masterChef.address, '10000000000000000000');
        await this.masterChef.connect(this.caller).deposit(this.pairUSDT_AAVE.address, '10000000000000000000', 0);
        await this.pairUSDT_AAVE.connect(this.inviter).approve(this.masterChef.address, '10000000000000000000');
        await this.masterChef.connect(this.inviter).deposit(this.pairUSDT_AAVE.address, '10000000000000000000', 0);
    });

    it("doHardWork", async function() {
        await this.feeDispatcher.addDefaultDestination(this.fund.address, '500', 0);
        await this.feeDispatcher.addDefaultDestination(this.masterChef.address, '7500', 1);
        await this.feeDispatcher.addDefaultDestination(this.masterChef.address, '500', 2);
        await this.feeDispatcher.addDefaultDestination(this.inviterContract.address, '500', 5);
        await this.feeDispatcher.addDefaultDestination(this.luckyPool.address, '1000', 0);
        await this.feeDispatcher.addRelateDestination(this.keplerToken.address, this.fund.address, '500', 0);
        await this.feeDispatcher.addTokenDestination(this.keplerToken.address, this.vote.address, '1500', 0);
        await this.feeDispatcher.addTokenDestination(this.keplerToken.address, this.fund.address, '500', 0);
         
        await this.AAVE.connect(this.deployer).mint(this.caller.address, '1000000000000000000');
        expect(await this.AAVE.balanceOf(this.caller.address)).to.be.equal('1000000000000000000');
        await this.AAVE.connect(this.caller).approve(this.feeDispatcher.address, '1000000000000000000');
        balanceBefore = await this.AAVE.balanceOf(this.fund.address);
        await this.feeDispatcher.connect(this.caller).doHardWork(this.pairUSDT_AAVE.address, this.AAVE.address, this.caller.address, '1000000000000000000');
        balanceAfter = await this.AAVE.balanceOf(this.fund.address);
        expect(balanceAfter.sub(balanceBefore)).to.be.equal('50000000000000000');
        pending = await this.lens.pendingMine(this.masterChef.address, this.pairUSDT_AAVE.address, this.AAVE.address, this.caller.address);
        //console.log("pending AAVE: ", pending.toString());
        balanceBefore = await this.AAVE.balanceOf(this.caller.address);
        await this.masterChef.connect(this.caller).claimMine(this.pairUSDT_AAVE.address, this.AAVE.address);
        balanceAfter = await this.AAVE.balanceOf(this.caller.address);
        console.log("claim AAVE: ", balanceAfter.sub(balanceBefore).toString());
        expect(balanceAfter.sub(balanceBefore)).to.be.equal(pending);
        pending = await this.lens.pendingInviteMine(this.masterChef.address, this.pairUSDT_AAVE.address, this.AAVE.address, this.inviter.address);
        //console.log("pending AAVE: ", pending.toString());
        balanceBefore = await this.AAVE.balanceOf(this.inviter.address);
        await this.masterChef.connect(this.inviter).claimInviteMine(this.pairUSDT_AAVE.address, this.AAVE.address);
        balanceAfter = await this.AAVE.balanceOf(this.inviter.address);
        console.log("claim inviter AAVE: ", balanceAfter.sub(balanceBefore).toString());
        expect(balanceAfter.sub(balanceBefore)).to.be.equal(pending);
        pending = await this.lens.pendingInvite(this.inviterContract.address, this.AAVE.address, this.inviter.address);
        balanceBefore = await this.AAVE.balanceOf(this.inviter.address);
        await this.inviterContract.connect(this.inviter).claim(this.AAVE.address);
        balanceAfter = await this.AAVE.balanceOf(this.inviter.address);
        console.log("claim inviterFee AAVE: ", balanceAfter.sub(balanceBefore).toString());
        expect(balanceAfter.sub(balanceBefore)).to.be.equal(pending);

        await this.USDT.connect(this.deployer).mint(this.caller.address, '1000000000000000000');
        expect(await this.USDT.balanceOf(this.caller.address)).to.be.equal('1000000000000000000');
        await this.USDT.connect(this.caller).approve(this.feeDispatcher.address, '1000000000000000000');
        balanceBefore = await this.USDT.balanceOf(this.fund.address);
        await this.feeDispatcher.connect(this.caller).doHardWork(this.pairUSDT_AAVE.address, this.USDT.address, this.caller.address, '1000000000000000000');
        balanceAfter = await this.USDT.balanceOf(this.fund.address);
        expect(balanceAfter.sub(balanceBefore)).to.be.equal('50000000000000000');
        pending = await this.lens.pendingMine(this.masterChef.address, this.pairUSDT_AAVE.address, this.USDT.address, this.caller.address);
        //console.log("pending USDT: ", pending.toString());
        balanceBefore = await this.USDT.balanceOf(this.caller.address);
        await this.masterChef.connect(this.caller).claimMine(this.pairUSDT_AAVE.address, this.USDT.address);
        balanceAfter = await this.USDT.balanceOf(this.caller.address);
        console.log("claim USDT: ", balanceAfter.sub(balanceBefore).toString());
        expect(balanceAfter.sub(balanceBefore)).to.be.equal(pending);
        pending = await this.lens.pendingInviteMine(this.masterChef.address, this.pairUSDT_AAVE.address, this.USDT.address, this.inviter.address);
        //console.log("pending USDT: ", pending.toString());
        balanceBefore = await this.USDT.balanceOf(this.inviter.address);
        await this.masterChef.connect(this.inviter).claimInviteMine(this.pairUSDT_AAVE.address, this.USDT.address);
        balanceAfter = await this.USDT.balanceOf(this.inviter.address);
        console.log("claim inviter USDT: ", balanceAfter.sub(balanceBefore).toString());
        expect(balanceAfter.sub(balanceBefore)).to.be.equal(pending);
        pending = await this.lens.pendingInvite(this.inviterContract.address, this.USDT.address, this.inviter.address);
        balanceBefore = await this.USDT.balanceOf(this.inviter.address);
        await this.inviterContract.connect(this.inviter).claim(this.USDT.address);
        balanceAfter = await this.USDT.balanceOf(this.inviter.address);
        console.log("claim inviterFee USDT: ", balanceAfter.sub(balanceBefore).toString());
        expect(balanceAfter.sub(balanceBefore)).to.be.equal(pending);
        
        /*
        await this.keplerToken.connect(this.deployer).mint(this.caller.address, '1000000000000000000');
        expect(await this.keplerToken.balanceOf(this.caller.address)).to.be.equal('1000000000000000000');
        await this.keplerToken.connect(this.caller).approve(this.feeDispatcher.address, '1000000000000000000');
        balanceBefore = await this.keplerToken.balanceOf(this.fund.address);
        balanceBefore1 = await this.keplerToken.balanceOf(this.vote.address);
        await this.feeDispatcher.connect(this.caller).doHardWork(this.pairUSDT_SDS.address, this.keplerToken.address, this.caller.address, '1000000000000000000');
        balanceAfter = await this.keplerToken.balanceOf(this.fund.address);
        balanceAfter1 = await this.keplerToken.balanceOf(this.vote.address);
        expect(balanceAfter.sub(balanceBefore)).to.be.equal('50000000000000000');
        expect(balanceAfter1.sub(balanceBefore1)).to.be.equal('150000000000000000');
        */
    });

});
