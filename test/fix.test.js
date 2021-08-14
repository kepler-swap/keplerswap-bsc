//const { TOKEN, RICHACCOUNT } = require('../config/address.js');
const chai = require("chai");
const expect = chai.expect;
//console.dir(chai);
//chai.should()
//chai.use(chaiAsPromised)

describe("Fix", () => {

    before(async function () {
        await deployments.fixture(['TestInit']);
        let { deployer, feeTo } = await ethers.getNamedSigners();
        const {testUser1, testUser2, testUser3, testUser4} = await ethers.getNamedSigners();
        this.deployer = deployer;
        this.caller = testUser2;

        const {fund, vote} = await getNamedAccounts();
        this.fund = fund;
        this.vote = vote;

        this.keplerFactory = await ethers.getContract('KeplerFactory');
        this.keplerRouter = await ethers.getContract('KeplerRouter');
        this.feeDispatcher = await ethers.getContract('FeeDispatcher');
        this.keplerToken = await ethers.getContract('KeplerToken');
        this.masterChef = await ethers.getContract('MasterChef');
        this.inviterContract = await ethers.getContract('Inviter');
        this.luckyPool = await ethers.getContract('LuckyPool');
        this.crycle = await ethers.getContract('Crycle');
        this.lens = await ethers.getContract('Lens');
        this.user = await ethers.getContract('User');
        this.WBNB = await ethers.getContract('MockToken_WBNB');
        this.USDT = await ethers.getContract('MockToken_USDT');
        this.AAVE = await ethers.getContract('MockToken_AAVE');
        this.SDS = await ethers.getContract('KeplerToken');
    });
    
    beforeEach(async function () {
    });

    it("Fix", async function() {
        await this.USDT.connect(this.caller).approve(this.keplerRouter.address, '10000000000000000000');
        await this.keplerRouter.connect(this.caller).swapExactTokensForTokens(
            '10000000000000000000',
            '0',
            [this.USDT.address, this.SDS.address],
            this.caller.address,
            Math.floor(new Date().getTime() / 1000) + 1000,
        );
        
        await this.USDT.connect(this.caller).approve(this.keplerRouter.address, '105000000000000000000');
        await this.SDS.connect(this.caller).approve(this.keplerRouter.address, '104134800000000000000');
        await this.keplerRouter.connect(this.caller).addLiquidity(
            this.USDT.address,
            this.SDS.address,
            '105000000000000000000',
            '104134800000000000000',
            0,
            0,
            this.caller.address,
            Math.floor(new Date().getTime() / 1000) + 1000,
            0,
        );

        await this.USDT.connect(this.caller).approve(this.keplerRouter.address, '105000000000000000000');
        await this.SDS.connect(this.caller).approve(this.keplerRouter.address, '104134800000000000000');
        await this.keplerRouter.connect(this.caller).addLiquidity(
            this.USDT.address,
            this.SDS.address,
            '105000000000000000000',
            '104134800000000000000',
            0,
            0,
            this.caller.address,
            Math.floor(new Date().getTime() / 1000) + 1000,
            0,
        );

    });
});
