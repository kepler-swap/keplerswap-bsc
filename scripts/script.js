// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const BigNumber = require('bignumber.js');

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
	 
  let keplerTokenFactory = await ethers.getContract('KeplerToken');
	let keplerToken = keplerTokenFactory.attach("0xff46778c28cbb560B8E396C7bc2da4E065ED6259");
  
  let USDTFactory = await ethers.getContract('MockToken_USDT');
	let USDT = USDTFactory.attach("0xc4E81502ECd748BE568bcC59af113DA22aa6f943");
	
	let AAVEFactory = await ethers.getContract('MockToken_AAVE');
	let AAVE = AAVEFactory.attach("0xd25EdA3dbFe0C4806B6539a32b54ca47f9eE6E22");
	
	let userFactory = await ethers.getContract('User');
	let user = userFactory.attach("0x637b3a5682CE227EcA8C860cC8f6430c65F2105d");
	
	let masterChefFactory = await ethers.getContract('MasterChef');
	let masterChef = masterChefFactory.attach("0xA121030d4a0117B7ee3bC004Cec6fa5919Abc3e4");
	
	let keplerFactory = await ethers.getContract('KeplerFactory');
	let factory = keplerFactory.attach("0x5DdA48DBc06eb68F0A3BaCFea66d024CA09e0eb6");
	
  let keplerRouterFactory = await ethers.getContract('KeplerRouter');
  let router = await keplerRouterFactory.attach("0xEED77CD9249598b2280F8c6b547c89f8D6809cbc");
	
	let crycleFactory = await ethers.getContract('Crycle');
  let crycle = await crycleFactory.attach("0x7e7FFDAFe80A400B8ab7772Ef44F6Afc1F9e572a");
	
	const {deployer} = await ethers.getNamedSigners();
  const {testUser1, testUser2, testUser3, testUser4} = await ethers.getNamedSigners();
	console.log(deployer.address);

	let signers = await ethers.getSigners();
	console.log(signers[0].address);
	const INIT_SDS = new BigNumber('1000000000000000000000000');
  const INIT_USDT = new BigNumber('1000000000000000000000000');
  const INIT_AAVE = new BigNumber('1000000000000000000000000');
	
	/**	
	for(let i = 10; i < 40; i ++){
	  // Create Tx Object
	  const tx = {
		to: signers[i].address,
		value: ethers.utils.parseEther('0.05'),
	  };
	  // sendTransaction
	  const receipt = await deployer.sendTransaction(tx);
	  console.log(`Transaction successful with hash: ${receipt.hash}`);
	}
	
	let testUsers = [testUser1, testUser2, testUser3, testUser4];
	for (let i = 0; i < testUsers.length; i ++) {
	  // Create Tx Object
		  const tx = {
			to: testUsers[i].address,
		  console.log(`Transaction successful with hash: ${receipt.hash}`);
	
		value: ethers.utils.parseEther('0.05'),
	  };
	  // sendTransaction
	  const receipt = await deployer.sendTransaction(tx);
	**/	
  
	for (let i = 10; i < 40; i ++) {
        let testUser = signers[i].address;
        let balanceSDS = new BigNumber((await keplerToken.balanceOf(testUser)).toString());
        if (balanceSDS.comparedTo(INIT_SDS) < 0) {
            tx = await keplerToken.connect(deployer).mint(testUser, INIT_SDS.minus(balanceSDS).toFixed(0))
            tx = await tx.wait();
            console.log("mint ", INIT_SDS.minus(balanceSDS).toFixed(0), " SDS to ", testUser);
        }
        let balanceUSDT = new BigNumber((await USDT.balanceOf(testUser)).toString());
        if (balanceUSDT.comparedTo(INIT_USDT) < 0) {
            tx = await USDT.connect(deployer).mint(testUser, INIT_USDT.minus(balanceUSDT).toFixed(0))
            tx = await tx.wait();
            console.log("mint ", INIT_USDT.minus(balanceUSDT).toFixed(0), " USDT to ", testUser);
        }
        let balanceAAVE = new BigNumber((await AAVE.balanceOf(testUser)).toString());
        if (balanceAAVE.comparedTo(INIT_AAVE) < 0) {
            tx = await AAVE.connect(deployer).mint(testUser, INIT_AAVE.minus(balanceAAVE).toFixed(0))
            tx = await tx.wait();
            console.log("mint ", INIT_AAVE.minus(balanceAAVE).toFixed(0), " AAVE to ", testUser);
        }
    }
	
		
	if ((await user.userExists(signers[10].address)) == false) {
		tx = await user.connect(signers[10]).registe(testUser1.address);
		tx = await tx.wait();
		console.log(signers[10].address, " registed by ",testUser1.address);
	}
	
	for (let i = 11; i < 40; i ++) {
		if ((await user.userExists(signers[i].address)) == false) {
			tx = await user.connect(signers[i]).registe(signers[i-1].address);
			tx = await tx.wait();
			console.log(signers[i].address, " registed by ",signers[i-1].address);
		}
	}
	
	
	let total =  100000;	
	let pairSDS_USDT = await ethers.getContractAt('KeplerPair', await factory.expectPairFor(keplerToken.address, USDT.address));

    for (let i = 10; i < 40; i ++) {
        let testUser = signers[i];
        let lockOrder = await masterChef.userLockInfo(pairSDS_USDT.address, testUser.address, 0);
		    console.log(lockOrder.amount.toString())
		
        //if ((new BigNumber(lockOrder.amount.toString())).comparedTo(new BigNumber('0')) == 0) {
            tx = await USDT.connect(testUser).approve(router.address, ethers.utils.parseEther("" +total));
            tx = await tx.wait();
            tx = await keplerToken.connect(testUser).approve(router.address, ethers.utils.parseEther("" +total));
            tx = await tx.wait();
            tx = await router.connect(testUser).addLiquidity(
                USDT.address,
                keplerToken.address,
                ethers.utils.parseEther("" +total),
                ethers.utils.parseEther("" +total),
                0,
                0,
                testUser.address,
                Math.floor(new Date().getTime() / 1000) + 1000,
                3,
            );
            tx = await tx.wait();
            console.log(i,testUser.address, "add liquidity 500USDT/500SDS");
        //}
		total -=1;
    }
	
	for (let i = 10; i < 40; i ++) {
		let testUser = signers[i];
		await crycle.connect(testUser).createCrycle("title" + 1 , "mainfest", "telegram");
		console.log(i);
	}
	
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
