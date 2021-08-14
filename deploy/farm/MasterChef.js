module.exports = async function ({
    ethers,
    getNamedAccounts,
    deployments,
    getChainId,
    getUnnamedAccounts,
}) {
    const {deploy} = deployments;
    const {deployer} = await ethers.getNamedSigners();
    let {WBNBAddress} = await getNamedAccounts();
    if (hre.network.tags.local || hre.network.tags.test) {
        let WBNB = await ethers.getContract('MockToken_WBNB');
        WBNBAddress = WBNB.address;
    }

    let user = await ethers.getContract('User');

    let deployResult = await deploy('MasterChef', {
        from: deployer.address,
        args: [user.address, WBNBAddress],
        log: true,
    });
};

module.exports.tags = ['MasterChef'];
module.exports.dependencies = ['User', 'MockToken'];
