module.exports = async function ({
    ethers,
    getNamedAccounts,
    deployments,
    getChainId,
    getUnnamedAccounts,
}) {
    const {deploy} = deployments;
    const {deployer} = await ethers.getNamedSigners();

    let crycle = await ethers.getContract('Crycle');

    let deployResult = await deploy('CrycleFarm', {
        from: deployer.address,
        args: [crycle.address],
        log: true,
    });
};

module.exports.tags = ['CrycleFarm'];
module.exports.dependencies = ["Crycle"];
