//const { TOKEN, RICHACCOUNT } = require('../config/address.js');
const chai = require("chai");
const expect = chai.expect;
//console.dir(chai);
//chai.should()
//chai.use(chaiAsPromised)

describe("Swap", () => {

    before(async function () {
        await deployments.fixture(['DeployAll']);
        let { deployer, feeTo } = await ethers.getNamedSigners();
        this.deployer = deployer;
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
        this.lens = await ethers.getContract('Lens');
        this.user = await ethers.getContract('User');
        this.crycle = await ethers.getContract('Crycle');
        this.WBNB = await ethers.getContract('MockToken_WBNB');
        this.USDT = await ethers.getContract('MockToken_USDT');
        this.AAVE = await ethers.getContract('MockToken_AAVE');

        let signers = await ethers.getSigners();
        this.inviter = signers[1];
        this.caller = signers[2];
        this.user1 = signers[9];
        this.user2 = signers[8];
        this.user3 = signers[7];
        this.user4 = signers[6];
        this.user5 = signers[5];
        this.user6 = signers[4];
        this.user7 = signers[3];
        
        this.fund = this.destination1;
        this.vote = this.destination2;

    });
    
    beforeEach(async function () {
    });

    it("Registe", async function() {
        await this.user.connect(this.inviter).registe('0x0000000000000000000000000000000000000001');
        await this.user.connect(this.caller).registe(this.inviter.address);
    });
    it("CreateAndDeposit", async function() {
        amount0 = '500000000000000000000';
        amount1 = '500000000000000000000';
        await this.USDT.mint(this.caller.address, amount0);
        await this.keplerToken.mint(this.caller.address, amount1);
        
        await this.USDT.connect(this.caller).approve(this.keplerRouter.address, amount0);
        await this.keplerToken.connect(this.caller).approve(this.keplerRouter.address, amount1);
        
        expect(await this.keplerFactory.getPair(this.USDT.address, this.keplerToken.address)).to.be.equal('0x0000000000000000000000000000000000000000');
        await this.keplerRouter.connect(this.caller).addLiquidity(
            this.USDT.address,
            this.keplerToken.address,
            amount0,
            amount1,
            0,
            0,
            this.caller.address,
            Math.floor(new Date().getTime() / 1000) + 1000,
            3,
        );

    });

    it("CreateCrycle", async function() {
        await this.keplerToken.connect(this.deployer).mint(this.user1.address, '10000000000000000000');
        await this.crycle.connect(this.caller).createCrycle("这是title", "这是mainfest", "这是telegram");
        let crycleInfo = await this.crycle.crycles(this.caller.address);
        //console.dir(crycleInfo);
    });

    it("AddCrycle", async function() {
        await this.crycle.connect(this.user1).addCrycle(this.caller.address);
        expect(await this.crycle.userCrycle(this.user1.address)).to.be.equal(this.caller.address);
    });

    it("StartVote", async function() {
        let startAt = Math.floor(new Date().getTime() / 1000) - 1;
        let countAt = Math.floor(new Date().getTime() / 1000) + 1000;
        let finishAt = Math.floor(new Date().getTime() / 1000) + 2000;
        this.startAt = startAt;
        this.countAt = countAt;
        this.finishAt = finishAt;
        await this.keplerToken.connect(this.deployer).mint(this.crycle.address, '10000000000000000000');
        await this.crycle.connect(this.deployer).startVote(startAt, countAt, finishAt);
    });

    it("doVote", async function() {
        let voteNum = await this.crycle.voteNum(this.user1.address);
        console.log("voteNum: ", voteNum.toString());
        await this.crycle.connect(this.user1).doVote('1000');
    });

    it("doCount", async function() {
        await network.provider.send("evm_mine", [this.countAt]);
        await this.crycle.connect(this.deployer).doCount([this.caller.address]);
    });

    it("claim", async function() {
        balanceBefore = await this.keplerToken.balanceOf(this.caller.address);
        await this.crycle.connect(this.caller).claim("1", this.caller.address);
        balanceAfter = await this.keplerToken.balanceOf(this.caller.address);
        console.log("claim amount: ", balanceAfter.sub(balanceBefore).toString());
    });

    /*     
    it("SwapToken", async function() {
        await this.USDT.mint(this.caller.address, '1000000000000000000'); 
        expect(await this.USDT.balanceOf(this.caller.address)).to.be.equal('1000000000000000000');
        expect(await this.AAVE.balanceOf(this.caller.address)).to.be.equal('0');
        await this.USDT.connect(this.caller).approve(this.keplerRouter.address, '1000000000000000000');
        await this.keplerRouter.connect(this.caller).swapExactTokensForTokens(
            '1000000000000000000',
            '0',
            [this.USDT.address, this.AAVE.address],
            this.caller.address,
            Math.floor(new Date().getTime() / 1000) + 1000,
        );
        expect(await this.USDT.balanceOf(this.caller.address)).to.be.equal('0');
        //expect(await this.AAVE.balanceOf(this.caller.address)).to.be.above('0');
        console.log("swap get amount: ", (await this.AAVE.balanceOf(this.caller.address)).toString());
    });

    it("Claim", async function() {
        pending = await this.lens.pendingMine(this.masterChef.address, this.pairUSDT_AAVE.address, this.USDT.address, this.caller.address);
        console.log("pending USDT: ", pending.toString());
        balanceBefore = await this.USDT.balanceOf(this.caller.address);
        await this.masterChef.connect(this.caller).claimMine(this.pairUSDT_AAVE.address, this.USDT.address);
        balanceAfter = await this.USDT.balanceOf(this.caller.address);
        console.log("claim inviter USDT: ", balanceAfter.sub(balanceBefore).toString());
        expect(balanceAfter.sub(balanceBefore)).to.be.equal(pending);
    });
    */
});
