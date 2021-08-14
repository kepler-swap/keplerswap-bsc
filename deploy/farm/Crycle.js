module.exports = async function ({
    ethers,
    getNamedAccounts,
    deployments,
    getChainId,
    getUnnamedAccounts,
}) {
    const {deploy} = deployments;
    const {deployer} = await ethers.getNamedSigners();
    let user = await ethers.getContract('User');
    let masterChef = await ethers.getContract('MasterChef');
    let keplerFactory = await ethers.getContract('KeplerFactory');
    let keplerToken = await ethers.getContract('KeplerToken');
    let {BUSDAddress} = await getNamedAccounts();
    if (hre.network.tags.local || hre.network.tags.test) {
        let busd = await ethers.getContract('MockToken_USDT');
        BUSDAddress = busd.address;
    }
    let pair = await keplerFactory.expectPairFor(keplerToken.address, BUSDAddress);
    let deployResult = await deploy('Crycle', {
        from: deployer.address,
        args: [user.address, masterChef.address, pair, BUSDAddress, keplerToken.address, keplerFactory.address],
        log: true,
    });
    let crycle = await ethers.getContract('Crycle');

    currentCaller = await keplerToken.snapshotCreateCaller();
    if (currentCaller != crycle.address) {
        tx = await keplerToken.setSnapshotCreateCaller(crycle.address);
        tx = await tx.wait();
    }
    currentCaller = await masterChef.snapshotCreateCaller();
    if (currentCaller != crycle.address) {
        tx = await masterChef.setSnapshotCreateCaller(crycle.address);
        tx = await tx.wait();
    }
    currentCaller = await keplerFactory.snapshotCreateCaller();
    if (currentCaller != crycle.address) {
        tx = await keplerFactory.setSnapshotCreateCaller(crycle.address);
        tx = await tx.wait();
    }
};

module.exports.tags = ['Crycle'];
module.exports.dependencies = ["User", "MasterChef", "KeplerFactory", "KeplerToken", "MockToken"];
