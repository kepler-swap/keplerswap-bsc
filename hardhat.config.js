require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("hardhat-spdx-license-identifier");
require('hardhat-deploy');
require ('hardhat-abi-exporter');
require("@nomiclabs/hardhat-ethers");
require('hardhat-contract-sizer');
require("dotenv/config")

const m_accounts = {
  mnemonic: "lend pledge soda sorry suspect sure pumpkin jelly purse blood hawk often usual night junk outer rescue feature addict mom stay ramp family anchor"
}

let accounts = [];
var fs = require("fs");
var read = require('read');
var util = require('util');
const keythereum = require("keythereum");
const prompt = require('prompt-sync')();
(async function() {
    try {
        const root = '.keystore';
        var pa = fs.readdirSync(root);
        for (let index = 0; index < pa.length; index ++) {
            let ele = pa[index];
            let fullPath = root + '/' + ele;
		    var info = fs.statSync(fullPath);
            //console.dir(ele);
		    if(!info.isDirectory() && ele.endsWith(".keystore")){
                const content = fs.readFileSync(fullPath, 'utf8');
                const json = JSON.parse(content);
                const password = prompt('Input password for 0x' + json.address + ': ', {echo: '*'});
                //console.dir(password);
                const privatekey = keythereum.recover(password, json).toString('hex');
                //console.dir(privatekey);
                accounts.push('0x' + privatekey);
                //console.dir(keystore);
		    }
	    }
    } catch (ex) {
    }
    try {
        const file = '.secret';
        var info = fs.statSync(file);
        if (!info.isDirectory()) {
            const content = fs.readFileSync(file, 'utf8');
            let lines = content.split('\n');
            for (let index = 0; index < lines.length; index ++) {
                let line = lines[index];
                if (line == undefined || line == '') {
                    continue;
                }
                if (!line.startsWith('0x') || !line.startsWith('0x')) {
                    line = '0x' + line;
                }
                accounts.push(line);
            }
        }
    } catch (ex) {
    }
})();
module.exports = {
    defaultNetwork: "hardhat",
    abiExporter: {
        path: "./abi",
        clear: false,
        flat: true,
        // only: [],
        // except: []
    },
    namedAccounts: {
        deployer: {
            default: 0,
        },
        admin: {
            default: 1,
        },
        fund: {
            default: 2,
        },
        testUser1: {
            default: 3,
        },
        testUser2: {
            default: 4,
        },
        testUser3: {
            default: 5,
        },
        testUser4: {
            default: 6,
        }
    },
    networks: {
        bscmain: {
            //url: `https://bsc-dataseed3.binance.org`,
            url: `https://bsc-dataseed1.defibit.io/`,
            accounts: m_accounts,
            //gasPrice: 1.3 * 1000000000,
            chainId: 56,
            gasMultiplier: 1.5,
            timeout: 999999999,
        },
        bsctest: {
            url: `https://data-seed-prebsc-2-s1.binance.org:8545`,
            accounts: { 
		mnemonic: `lend pledge soda sorry suspect sure pumpkin jelly purse blood hawk often usual night junk outer rescue feature addict mom stay ramp family anchor`,
		count:1000
	           },
            //gasPrice: 1.3 * 1000000000,
            chainId: 97,
            tags: ["test"],
            timeout: 999999999,
        },
        hardhat: {
            forking: {
                enabled: false,
                //url: `https://bsc-dataseed1.defibit.io/`
                url: `https://bsc-dataseed1.ninicoin.io/`,
                //url: `https://bsc-dataseed3.binance.org/`
                //url: `https://data-seed-prebsc-1-s1.binance.org:8545`
                //blockNumber: 8215578,
            },
            live: true,
            saveDeployments: true,
            tags: ["test", "local"],
            //chainId: 56,
            timeout: 2000000,
        }
    },
    solidity: {
        /*
        version: "0.5.16",
        settings: {
            optimizer: {
                enabled: true,
            }
        }
        */
        compilers: [
            {
                version: "0.7.6",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
        ],
    },
    contractSizer: {
        alphaSort: true,
        runOnCompile: true
    },
    spdxLicenseIdentifier: {
        overwrite: true,
        runOnCompile: true,
    },
    mocha: {
        timeout: 2000000,
    },
    etherscan: {
     apiKey: process.env.ETHERSCAN_KEY,
   }
};
