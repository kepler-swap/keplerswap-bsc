const { TOKENS } = require('../../config/tokens.online.js');
module.exports = async function ({
    ethers,
    getNamedAccounts,
    deployments,
    getChainId,
    getUnnamedAccounts,
}) {

    const {deploy} = deployments;
    const {deployer} = await ethers.getNamedSigners();

    if (!hre.network.tags.local && !hre.network.tags.test) {
        return;
    }
    //console.dir(TOKENS);
    let resultTokens = [];
    let maxNum = 10;
    for (let i = 0; i < TOKENS.length && i < maxNum; i ++) {
        let token = TOKENS[i];
        //console.dir(token);
        if (token.symbol == 'WBNB') {
            //console.dir(token);
            await deploy('MockToken_WBNB', {
                from: deployer.address,
                args: [],
                log: true,
                contract: 'MockWBNB',
            });
        } else {
            await deploy('MockToken_' + token.symbol, {
               from: deployer.address,
               args: [token.name, token.symbol, token.decimals],
               log: true,
               contract: 'MockToken',
            });
        }
    }
};

module.exports.tags = ['MockToken'];
module.exports.dependencies = [];
