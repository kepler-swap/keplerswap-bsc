module.exports = async function ({
    ethers,
    getNamedAccounts,
    deployments,
    getChainId,
    getUnnamedAccounts,
}) {
    const {deploy} = deployments;
    let {WBNBAddress} = await getNamedAccounts();
    const {deployer} = await ethers.getNamedSigners();
    if (hre.network.tags.local || hre.network.tags.test) {
        let WBNB = await ethers.getContract('MockToken_WBNB');
        WBNBAddress = WBNB.address;
    }
    let masterChef = await ethers.getContract('MasterChef');
    let keplerFactory = await ethers.getContract('KeplerFactory');
    let deployResult = await deploy('KeplerRouter', {
        from: deployer.address,
        args: [keplerFactory.address, WBNBAddress, masterChef.address],
        log: true,
    });
};

module.exports.tags = ['KeplerRouter'];
module.exports.dependencies = ['KeplerFactory', 'MockToken', 'MasterChef'];
