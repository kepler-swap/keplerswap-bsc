module.exports = async function ({
    ethers,
    getNamedAccounts,
    deployments,
    getChainId,
    getUnnamedAccounts,
}) {
};

module.exports.tags = ['DeployAll'];
module.exports.dependencies = ['User', 'MockToken', 'KeplerRouter', 'FeeDispatcher', 'Lens'];
