// const BigNumber = require('bignumber.js');

// module.exports = async function ({
//     ethers,
//     getNamedAccounts,
//     deployments,
//     getChainId,
//     getUnnamedAccounts,
// }) {
//     const {deployer} = await ethers.getNamedSigners();
//     const {testUser1, testUser2, testUser3, testUser4} = await ethers.getNamedSigners();
//     if (!hre.network.tags.local && !hre.network.tags.test) {
//         return;
//     }
//     console.log("begin init test data");
//     let keplerToken = await ethers.getContract('KeplerToken');
//     let USDT = await ethers.getContract('MockToken_USDT');
//     let AAVE = await ethers.getContract('MockToken_AAVE');
//     let user = await ethers.getContract('User');
//     let testUsers = [testUser1, testUser2, testUser3, testUser4];
//     let masterChef = await ethers.getContract('MasterChef');
//     let factory = await ethers.getContract('KeplerFactory');
//     let router = await ethers.getContract('KeplerRouter');
//     const INIT_SDS = new BigNumber('1000000000000000000000000');
//     const INIT_USDT = new BigNumber('1000000000000000000000000');
//     const INIT_AAVE = new BigNumber('1000000000000000000000000');
//     for (let i = 0; i < testUsers.length; i ++) {
//         let testUser = testUsers[i].address;
//         let balanceSDS = new BigNumber((await keplerToken.balanceOf(testUser)).toString());
//         if (balanceSDS.comparedTo(INIT_SDS) < 0) {
//             tx = await keplerToken.connect(deployer).mint(testUser, INIT_SDS.minus(balanceSDS).toFixed(0))
//             tx = await tx.wait();
//             console.log("mint ", INIT_SDS.minus(balanceSDS).toFixed(0), " SDS to ", testUser);
//         }
//         let balanceUSDT = new BigNumber((await USDT.balanceOf(testUser)).toString());
//         if (balanceUSDT.comparedTo(INIT_USDT) < 0) {
//             tx = await USDT.connect(deployer).mint(testUser, INIT_USDT.minus(balanceUSDT).toFixed(0))
//             tx = await tx.wait();
//             console.log("mint ", INIT_USDT.minus(balanceUSDT).toFixed(0), " USDT to ", testUser);
//         }
//         let balanceAAVE = new BigNumber((await AAVE.balanceOf(testUser)).toString());
//         if (balanceAAVE.comparedTo(INIT_AAVE) < 0) {
//             tx = await AAVE.connect(deployer).mint(testUser, INIT_AAVE.minus(balanceAAVE).toFixed(0))
//             tx = await tx.wait();
//             console.log("mint ", INIT_AAVE.minus(balanceAAVE).toFixed(0), " AAVE to ", testUser);
//         }
//     }
//     //invite
//     if ((await user.userExists(testUser1.address)) == false) {
//         tx = await user.connect(testUser1).registe(user.address);
//         tx = await tx.wait();
//         console.log(testUser1.address, " registed by ", user.address);
//     }
//     if ((await user.userExists(testUser2.address)) == false) {
//         tx = await user.connect(testUser2).registe(testUser1.address);
//         tx = await tx.wait();
//         console.log(testUser2.address, " registed by ", testUser1.address);
//     }
//     if ((await user.userExists(testUser3.address)) == false) {
//         tx = await user.connect(testUser3).registe(testUser1.address);
//         tx = await tx.wait();
//         console.log(testUser3.address, " registed by ", testUser1.address);
//     }
//     if ((await user.userExists(testUser4.address)) == false) {
//         tx = await user.connect(testUser4).registe(testUser2.address);
//         tx = await tx.wait();
//         console.log(testUser4.address, " registed by ", testUser2.address);
//     }
//     let pairSDS_USDT = await ethers.getContractAt('KeplerPair', await factory.expectPairFor(keplerToken.address, USDT.address));
//     for (let i = 0; i < testUsers.length; i ++) {
//         let testUser = testUsers[i];
//         let lockOrder = await masterChef.userLockInfo(pairSDS_USDT.address, testUser.address, 0);
//         if ((new BigNumber(lockOrder.amount.toString())).comparedTo(new BigNumber('0')) == 0) {
//             tx = await USDT.connect(testUser).approve(router.address, '500000000000000000000');
//             tx = await tx.wait();
//             tx = await keplerToken.connect(testUser).approve(router.address, '500000000000000000000');
//             tx = await tx.wait();
//             tx = await router.connect(testUser).addLiquidity(
//                 USDT.address,
//                 keplerToken.address,
//                 '500000000000000000000',
//                 '500000000000000000000',
//                 0,
//                 0,
//                 testUser.address,
//                 Math.floor(new Date().getTime() / 1000) + 1000,
//                 3,
//             );
//             tx = await tx.wait();
//             console.log(testUser.address, "add liquidity 500USDT/500SDS");
//         }
//     }
// };

// module.exports.tags = ['TestInit'];
// module.exports.dependencies = ['DeployAll']
