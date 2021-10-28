module.exports = async function ({
    ethers,
    getNamedAccounts,
    deployments,
    getChainId,
    getUnnamedAccounts,
}) {
    const {deploy} = deployments;
    const {deployer} = await ethers.getNamedSigners();

    await deploy('Random', {
        from: deployer.address,
        args: [],
        log: true,
    });
    let random = await ethers.getContract('Random');

    await deploy('LuckyPool', {
        from: deployer.address,
        args: [random.address],
        log: true,
    });
    let luckyPool = await ethers.getContract('LuckyPool');
	
	/**
    let sds = await ethers.getContractAt('KeplerToken', '0xBa88A299B180e92f04bD33D66fDD4F327E4F12a9');
    tx = await sds.connect(deployer).mint(deployer.address, '1000000000000000000');
    tx = await tx.wait();
    tx = await sds.connect(deployer).approve(luckyPool.address, '1000000000000000000');
    tx = await tx.wait();
    tx = await luckyPool.connect(deployer).doHardWork('0x5035c6ec97c6691aef53b8ba7485d202d9c74554', '0xBa88A299B180e92f04bD33D66fDD4F327E4F12a9', '1000000000000000000');
    tx = await tx.wait();

    let usdt = await ethers.getContractAt('MockToken', '0xc37091C04b3023fDCf292BDa563dE4914ae251C7');
    tx = await usdt.connect(deployer).mint(deployer.address, '2000000000000000000');
    tx = await tx.wait();
    tx = await usdt.connect(deployer).approve(luckyPool.address, '2000000000000000000');
    tx = await tx.wait();
    tx = await luckyPool.connect(deployer).doHardWork('0x5035c6ec97c6691aef53b8ba7485d202d9c74554', '0xc37091C04b3023fDCf292BDa563dE4914ae251C7', '2000000000000000000');
    tx = await tx.wait();
	**/
};

module.exports.tags = ['LuckyPool'];
module.exports.dependencies = [];
