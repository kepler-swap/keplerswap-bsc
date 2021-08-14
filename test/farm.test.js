//const { TOKEN, RICHACCOUNT } = require('../config/address.js');
const chai = require("chai");
const expect = chai.expect;
//console.dir(chai);
//chai.should()
//chai.use(chaiAsPromised)

describe("MasterChef", () => {

    before(async function () {
        await deployments.fixture(['MockToken', 'KeplerFactory', 'KeplerRouter', 'MasterChef']);
        let { deployer } = await ethers.getNamedSigners();
        this.deployer = deployer;
        this.keplerFactory = await ethers.getContract('KeplerFactory');
        this.keplerRouter = await ethers.getContract('KeplerRouter');
        this.masterChef = await ethers.getContract('MasterChef');
        this.WBNB = await ethers.getContract('MockToken_WBNB');
        this.USDT = await ethers.getContract('MockToken_USDT');
        this.AAVE = await ethers.getContract('MockToken_AAVE');

        let signers = await ethers.getSigners();
        this.caller = signers[9];
    });

    beforeEach(async function () {
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
        expect(await this.keplerFactory.getPair(this.USDT.address, this.AAVE.address)).to.be.not.equal('0x0000');
        this.pairUSDT_AAVE = await ethers.getContractAt('KeplerPair', await this.keplerFactory.getPair(this.USDT.address, this.AAVE.address));
        expect(await this.pairUSDT_AAVE.balanceOf(this.caller.address)).to.be.equal('10000000000000000000');
    });

    it("doHardWork", async function() {
        await this.USDT.mint(this.caller.address, '10000000000000000000');
        await this.AAVE.mint(this.caller.address, '10000000000000000000');

        await this.USDT.connect(this.caller).approve(this.masterChef.address, '10000000000000000000');
        await this.masterChef.connect(this.caller).doMiner(this.pairUSDT_AAVE.address, this.USDT.address, '10000000000000000000');
        await this.AAVE.connect(this.caller).approve(this.masterChef.address, '10000000000000000000');
        await this.masterChef.connect(this.caller).doMiner(this.pairUSDT_AAVE.address, this.AAVE.address, '10000000000000000000');
    })

    it("deposit", async function() {
        await this.pairUSDT_AAVE.connect(this.caller).approve(this.masterChef.address, '1000000000000000000'); 
        await this.masterChef.connect(this.caller).deposit(this.pairUSDT_AAVE.address, '1000000000000000000', 0);
        expect(await this.pairUSDT_AAVE.balanceOf(this.masterChef.address)).to.be.equal('1000000000000000000');
    });
    it("doHardworkAgain", async function() {
        await this.USDT.mint(this.caller.address, '10000000000000000000');
        await this.AAVE.mint(this.caller.address, '10000000000000000000');

        await this.USDT.connect(this.caller).approve(this.masterChef.address, '10000000000000000000');
        await this.masterChef.connect(this.caller).doMiner(this.pairUSDT_AAVE.address, this.USDT.address, '10000000000000000000');
        balanceBefore = await this.USDT.balanceOf(this.caller.address);
        await this.masterChef.connect(this.caller).deposit(this.pairUSDT_AAVE.address, '0', 0);
        balanceAfter = await this.USDT.balanceOf(this.caller.address);
        //console.log("claim balance: ", balanceAfter.sub(balanceBefore).toString());
        expect(balanceAfter.sub(balanceBefore)).to.be.equal('9999999999999999999');
    });
    it("withdraw", async function() {
        balanceBefore = await this.pairUSDT_AAVE.balanceOf(this.caller.address);
        await this.masterChef.connect(this.caller).withdraw(this.pairUSDT_AAVE.address, 0);
        balanceAfter = await this.pairUSDT_AAVE.balanceOf(this.caller.address);
        //console.log("withdraw balance: ", balanceAfter.sub(balanceBefore).toString());
        expect(balanceAfter.sub(balanceBefore)).to.be.equal('1000000000000000000');
    });
});
