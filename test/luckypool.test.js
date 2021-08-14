//const { TOKEN, RICHACCOUNT } = require('../config/address.js');
const chai = require("chai");
const expect = chai.expect;
//console.dir(chai);
//chai.should()
//chai.use(chaiAsPromised)

describe("LuckyPool", () => {

    before(async function () {
        await deployments.fixture(['LuckyPool', 'Swap', 'MockToken', 'FeeDispatcher']);
        const {deployer} = await ethers.getNamedSigners();

        this.random = await ethers.getContract('Random');
        this.luckyPool = await ethers.getContract('LuckyPool');
        this.factory = await ethers.getContract('KeplerFactory');
        this.router = await ethers.getContract('KeplerRouter');
        this.user = await ethers.getContract('User');
        this.admin = deployer;

        this.USDT = await ethers.getContract('MockToken_USDT');
        this.AAVE = await ethers.getContract('MockToken_AAVE');
        this.ADA = await ethers.getContract('MockToken_ADA');
        this.ALICE = await ethers.getContract('MockToken_ALICE');
        this.ALPACA = await ethers.getContract('MockToken_ALPACA');
        this.ALPHA = await ethers.getContract('MockToken_ALPHA');

        let signers = await ethers.getSigners();
        this.luckyUser1 = signers[1];
        this.luckyUser2 = signers[2];
        this.luckyUser3 = signers[3];
        this.luckyUser4 = signers[4];
        this.luckyUser5 = signers[5];
        this.luckyUser6 = signers[6];
        this.luckyUser7 = signers[7];
        this.luckyUser8 = signers[8];
        this.luckyUser9 = signers[9];
        this.luckyUser10 = signers[10];
    });

    beforeEach(async function () {
    });

    it("CheckBegin", async function() {
        let currentPoolId = await this.luckyPool.currentPoolId();
        expect(currentPoolId).to.be.equal(0);
        let luckyInfo = await this.luckyPool.luckyInfos(currentPoolId);
        //console.dir(luckyInfo);
        //console.dir(luckyInfo.beginAt.toString());
        expect(luckyInfo.beginAt).to.be.below(Math.floor(new Date()));
        expect(luckyInfo.countAt).to.be.equal(0);
        expect(luckyInfo.openAt).to.be.equal(0);
        expect(luckyInfo.finishAt).to.be.equal(0);
        expect(luckyInfo.luckyPairsNum).to.be.equal(0);

        await this.luckyPool.beginLuckyPool();
        currentPoolId = await this.luckyPool.currentPoolId();
        expect(currentPoolId).to.be.equal(0);
    });

    it("Registe", async function() {
        await this.user.connect(this.admin).registe('0x0000000000000000000000000000000000000001');
    });

    it("CreatePair", async function() {
        //AAVE-USDT
        amount0 = '10000000000000000000';
        amount1 = '10000000000000000000';
        await this.USDT.connect(this.admin).mint(this.admin.address, amount0);
        await this.AAVE.connect(this.admin).mint(this.admin.address, amount1);
        await this.USDT.connect(this.admin).approve(this.router.address, amount0);
        await this.AAVE.connect(this.admin).approve(this.router.address, amount1);
        await this.router.connect(this.admin).addLiquidity(
            this.USDT.address,
            this.AAVE.address,
            amount0,
            amount1,
            0,
            0,
            this.admin.address,
            Math.floor(new Date().getTime() / 1000) + 1000,
            0,
        );
        this.pairUSDT_AAVE = await ethers.getContractAt('KeplerPair', await this.factory.getPair(this.USDT.address, this.AAVE.address));
        //ADA-USDT
        await this.USDT.connect(this.admin).mint(this.admin.address, amount0);
        await this.ADA.connect(this.admin).mint(this.admin.address, amount1);
        await this.USDT.connect(this.admin).approve(this.router.address, amount0);
        await this.ADA.connect(this.admin).approve(this.router.address, amount1);
        await this.router.connect(this.admin).addLiquidity(
            this.USDT.address,
            this.ADA.address,
            amount0,
            amount1,
            0,
            0,
            this.admin.address,
            Math.floor(new Date().getTime() / 1000) + 1000,
            0,
        );
        this.pairUSDT_ADA = await ethers.getContractAt('KeplerPair', await this.factory.getPair(this.USDT.address, this.ADA.address));
        //ALICE-USDT
        await this.USDT.connect(this.admin).mint(this.admin.address, amount0);
        await this.ALICE.connect(this.admin).mint(this.admin.address, amount1);
        await this.USDT.connect(this.admin).approve(this.router.address, amount0);
        await this.ALICE.connect(this.admin).approve(this.router.address, amount1);
        await this.router.connect(this.admin).addLiquidity(
            this.USDT.address,
            this.ALICE.address,
            amount0,
            amount1,
            0,
            0,
            this.admin.address,
            Math.floor(new Date().getTime() / 1000) + 1000,
            0,
        );
        this.pairUSDT_ALICE = await ethers.getContractAt('KeplerPair', await this.factory.getPair(this.USDT.address, this.ALICE.address));
        //ALPACA-USDT
        await this.USDT.connect(this.admin).mint(this.admin.address, amount0);
        await this.ALPACA.connect(this.admin).mint(this.admin.address, amount1);
        await this.USDT.connect(this.admin).approve(this.router.address, amount0);
        await this.ALPACA.connect(this.admin).approve(this.router.address, amount1);
        await this.router.connect(this.admin).addLiquidity(
            this.USDT.address,
            this.ALPACA.address,
            amount0,
            amount1,
            0,
            0,
            this.admin.address,
            Math.floor(new Date().getTime() / 1000) + 1000,
            0,
        );
        this.pairUSDT_ALPACA = await ethers.getContractAt('KeplerPair', await this.factory.getPair(this.USDT.address, this.ALPACA.address));
        //ALPHA-USDT
        await this.USDT.connect(this.admin).mint(this.admin.address, amount0);
        await this.ALPHA.connect(this.admin).mint(this.admin.address, amount1);
        await this.USDT.connect(this.admin).approve(this.router.address, amount0);
        await this.ALPHA.connect(this.admin).approve(this.router.address, amount1);
        await this.router.connect(this.admin).addLiquidity(
            this.USDT.address,
            this.ALPHA.address,
            amount0,
            amount1,
            0,
            0,
            this.admin.address,
            Math.floor(new Date().getTime() / 1000) + 1000,
            0,
        );
        this.pairUSDT_ALPHA = await ethers.getContractAt('KeplerPair', await this.factory.getPair(this.USDT.address, this.ALPHA.address));
    });

    it("Swap", async function() {
        let amount = '1000000000000000000';
        await this.USDT.connect(this.admin).mint(this.admin.address, amount); 
        await this.USDT.connect(this.admin).approve(this.router.address, amount);
        await this.router.connect(this.admin).swapExactTokensForTokens(
            amount,
            '0',
            [this.USDT.address, this.AAVE.address],
            this.admin.address,
            Math.floor(new Date().getTime() / 1000) + 1000,
        );

        await this.AAVE.connect(this.admin).mint(this.admin.address, amount); 
        await this.AAVE.connect(this.admin).approve(this.router.address, amount);
        await this.router.connect(this.admin).swapExactTokensForTokens(
            amount,
            '0',
            [this.AAVE.address, this.USDT.address],
            this.admin.address,
            Math.floor(new Date().getTime() / 1000) + 1000,
        );
    });

    it("StartLuckyPool", async function() {
        await this.luckyPool.connect(this.admin).openLuckyPool(
            [
                this.luckyUser1.address, this.luckyUser2.address, this.luckyUser3.address, this.luckyUser4.address, this.luckyUser5.address, 
                this.luckyUser6.address, this.luckyUser7.address, this.luckyUser8.address, this.luckyUser9.address, this.luckyUser10.address
            ],
            //[this.pairUSDT_AAVE.address, this.pairUSDT_ADA.address, this.pairUSDT_ALICE.address, this.pairUSDT_ALPACA.address, this.pairUSDT_ALPHA.address],
            [this.pairUSDT_AAVE.address],
            [10]
        );
        let currentPoolId = await this.luckyPool.currentPoolId();
        expect(currentPoolId).to.be.equal(1);
        let luckyInfo = await this.luckyPool.luckyInfos(currentPoolId);
        //console.dir(luckyInfo);
        //console.dir(luckyInfo.beginAt.toString());
        expect(luckyInfo.beginAt).to.be.below(Math.floor(new Date()));
        expect(luckyInfo.countAt).to.be.equal(0);
        expect(luckyInfo.openAt).to.be.equal(0);
        expect(luckyInfo.finishAt).to.be.equal(0);
        expect(luckyInfo.luckyPairsNum).to.be.equal(0);

        await this.luckyPool.beginLuckyPool();
        currentPoolId = await this.luckyPool.currentPoolId();
        expect(currentPoolId).to.be.equal(1);

        let rewardPoolId = await this.luckyPool.rewardPoolId();
        //console.dir(rewardPoolId.toString());
        let changeTimestamp = Math.floor((new Date()) / 1000) + 24 * 3600 + 1000;
        //console.log("timestamp: ", changeTimestamp);
        await network.provider.send("evm_mine", [changeTimestamp]);
        luckyPool = await this.luckyPool.luckyInfos(0)
        //console.dir(luckyPool);
        rewardPoolId = await this.luckyPool.rewardPoolId();
        expect(rewardPoolId).to.be.equal('0');
        //console.dir(rewardPoolId.toString());
        
    });

    it("Claim", async function() {
        expect(await this.luckyPool.avaliableUsers(0, this.pairUSDT_AAVE.address, this.luckyUser1.address)).to.be.equal(true);
        await this.luckyPool.connect(this.luckyUser1).claim(this.pairUSDT_AAVE.address, "123");
        expect(await this.luckyPool.openUsers(0, this.pairUSDT_AAVE.address, this.luckyUser1.address)).to.be.equal(true);
        expect(await this.luckyPool.luckyUsers0(0, this.pairUSDT_AAVE.address, this.luckyUser1.address)).to.be.equal(0);
        expect(await this.luckyPool.luckyUsers1(0, this.pairUSDT_AAVE.address, this.luckyUser1.address)).to.be.equal(0);

        await this.luckyPool.connect(this.luckyUser2).claim(this.pairUSDT_AAVE.address, "123");
        await this.luckyPool.connect(this.luckyUser3).claim(this.pairUSDT_AAVE.address, "123");
        await this.luckyPool.connect(this.luckyUser4).claim(this.pairUSDT_AAVE.address, "123");
        await this.luckyPool.connect(this.luckyUser5).claim(this.pairUSDT_AAVE.address, "123");
        await this.luckyPool.connect(this.luckyUser6).claim(this.pairUSDT_AAVE.address, "123");
        await this.luckyPool.connect(this.luckyUser7).claim(this.pairUSDT_AAVE.address, "123");
        await this.luckyPool.connect(this.luckyUser8).claim(this.pairUSDT_AAVE.address, "123");
        await this.luckyPool.connect(this.luckyUser9).claim(this.pairUSDT_AAVE.address, "123");
        await this.luckyPool.connect(this.luckyUser10).claim(this.pairUSDT_AAVE.address, "123");

        let rewardInfo = await this.luckyPool.rewardInfos(0, this.pairUSDT_AAVE.address);
        console.dir(rewardInfo.reward0.toString());
        console.dir(rewardInfo.reward1.toString());
    });
});
