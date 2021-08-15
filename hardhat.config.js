require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("hardhat-spdx-license-identifier");
require('hardhat-deploy');
require ('hardhat-abi-exporter');
require("@nomiclabs/hardhat-ethers");
require('hardhat-contract-sizer');
require("dotenv/config")

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
            97: '0x92Ac13DfFf2e421e53dFD2873Ea295EdC9504764',
            56: '0x4acCAC4AdB3D6490AA3e012438bEb33637D8a922',
        },
        /*
        admin: {
            default: 1,
            128: '0x78194d4aE6F0a637F563482cAc143ecE532E8847',
            56: '0x4f7b45C407ec1B106Ba3772e0Ecc7FD4504d3b92',
        },
        */
        fund: {
            default: 1,
            97: '0x92Ac13DfFf2e421e53dFD2873Ea295EdC9504764',
            56: '0x4f7b45C407ec1B106Ba3772e0Ecc7FD4504d3b92',
        },
        testUser1: {
            default: 2,
            97: '0x97bE3C989Fdc7B281cE39F621e48Aa8b9dF53293'
        },
        testUser2: {
            default: 3,
            97: '0xc3f04f82B2e74cE9fABb3434abf5a768d1b6b79D'
        },
        testUser3: {
            default: 4,
            97: '0x215013BA10CA695bBa8a3473CD1f0f57A3843449'
        },
        testUser4: {
            default: 5,
            97: '0xCc049F63c48FFE8134388691323aB9c431a21080'
        }
    },
    networks: {
        bscmain: {
            //url: `https://bsc-dataseed3.binance.org`,
            url: `https://bsc-dataseed1.defibit.io/`,
            accounts: accounts,
            //gasPrice: 1.3 * 1000000000,
            chainId: 56,
            gasMultiplier: 1.5,
        },
        bsctest: {
            url: `https://data-seed-prebsc-2-s1.binance.org:8545`,
            accounts: accounts,
            //gasPrice: 1.3 * 1000000000,
            chainId: 97,
            tags: ["test"],
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
     apiKey: process.env.BSC_API_KEY,
   }
};
