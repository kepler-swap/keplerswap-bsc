module.exports = async function ({
    ethers,
    getNamedAccounts,
    deployments,
    getChainId,
    getUnnamedAccounts,
}) {
    const {deploy} = deployments;
    const {deployer} = await ethers.getNamedSigners();

    let deployResult = await deploy('User', {
        from: deployer.address,
        args: [],
        log: true,
    });
};

module.exports.tags = ['User'];
module.exports.dependencies = [];
