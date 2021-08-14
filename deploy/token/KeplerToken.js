module.exports = async function ({
    ethers,
    getNamedAccounts,
    deployments,
    getChainId,
    getUnnamedAccounts,
}) {

    const {deploy} = deployments;
    const {deployer} = await ethers.getNamedSigners();

    await deploy('KeplerToken', {
        from: deployer.address,
        args: ["seeds", "SDS", 18],
        log: true,
    });
};

module.exports.tags = ['KeplerToken'];
module.exports.dependencies = [];
