module.exports = async function ({
    ethers,
    getNamedAccounts,
    deployments,
    getChainId,
    getUnnamedAccounts,
}) {
    const {deploy} = deployments;
    const {deployer} = await ethers.getNamedSigners();

    let deployResult = await deploy('Lens', {
        from: deployer.address,
        args: [],
        log: true,
        proxy: {
            proxyContract: 'OptimizedTransparentProxy',
        },
    });
};

module.exports.tags = ['Lens'];
module.exports.dependencies = [];
