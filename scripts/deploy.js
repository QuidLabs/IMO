
const { ethers } = require("hardhat")
const { resolve } = require("path");
const fs = require('fs')
const BN = require('bn.js')
// require('dotenv').config()
const { config: dotenvConfig } = require("dotenv");
dotenvConfig({ path: resolve(__dirname, "../.env") });

async function getContract(name, addr, signer) {
  const CONTRACT = await ethers.getContractFactory(name)
  const contract = await CONTRACT.attach(addr).connect(signer)
  return contract;
}

const addressesFilePath = resolve(__dirname, "deployedAddresses.json")
function load(path) {
  if (fs.existsSync(path)) {
    const data = fs.readFileSync(path, 'utf-8')
    return JSON.parse(data);
  }
  return {};
  // TODO write to constant.jsx
}

// Save the deployed contract addresses to the file
function saveAddresses(addresses) {
  fs.writeFileSync(addressesFilePath, JSON.stringify(addresses, null, 2))
}

async function deployContracts() {
    try {
      console.log('deploy mocks')
      let mockToken = await ethers.getContractFactory("mockToken")
      let mockVault = await ethers.getContractFactory("mockVault")
      
      const mockUSDe = await mockToken.deploy()
      const USDeToken = await mockUSDe.getAddress()
      console.log('USDe deployed at', USDeToken)

      const mockSUSDe = await mockVault.deploy(USDeToken)
      const sUSDeToken = await mockSUSDe.getAddress()
      console.log('sUSDe deployed at', sUSDeToken)

      console.log('deploying MO')
      const MO = await ethers.getContractFactory("MO")

      const mo = await MO.deploy(USDeToken, sUSDeToken)
      const MOaddress = await mo.getAddress()
      console.log("MO deployed at", MOaddress)

      const QD = await ethers.getContractFactory("Quid")
      const qd = await QD.deploy(MOaddress)
      
      const QDaddress = await qd.getAddress()
      console.log("QD deployed at", QDaddress)
      
      // Save addresses to the file
      const addresses = {
        USDe: USDeToken,
        sUSDe: sUSDeToken,
        Moulinette: MOaddress,
        Quid: QDaddress
      }
      saveAddresses(addresses)
      console.log("setQuid")
      
      var tx = await mo.setQuid(QDaddress)
      await tx.wait()
      
      console.log("set price")  
      tx = await mo.set_price_eth(false, true) 
      console.log("START");
      await tx.wait()
      
      tx = await qd.restart()
      return addresses
    }
    catch (error) {
      console.error("Error deployment:", error)
    }
}

async function main() { // run some tests on our contracts... 
    const shouldDeploy = process.env.SHOULD_DEPLOY !== 'false'
    var addresses;
    if (!shouldDeploy) {
      console.log("not deploying")
      addresses = load(addressesFilePath)
      if (!addresses.Quid) {
        throw new Error("can't load addresses")
      }
    }
    else {
      addresses = await deployContracts()
    }
    const provider = ethers.provider
    
    const latestBlock = await provider.getBlockNumber()
    
    const beneficiary = new ethers.Wallet(process.env.PRIVATE_KEY_1, provider)
    const secondary = new ethers.Wallet(process.env.PRIVATE_KEY_2, provider)
    
    const MO = await getContract("MO", addresses.Moulinette, beneficiary)
    const MOWithSecondary = await getContract("MO", addresses.Moulinette, secondary)
    
    const QD = await getContract("Quid", addresses.Quid, beneficiary)
    const QDwithSecondary = await getContract("Quid", addresses.Quid, secondary)
    
    const USDE = await getContract("mockToken", addresses.USDe, beneficiary)
    const USDEwithSecondary = await getContract("mockToken", addresses.USDe, secondary)

    const sUSDE = await getContract("mockVault", addresses.sUSDe, beneficiary)
     
    const fromBlock = latestBlock - 1000
    const toBlock = latestBlock
    // Create a filter to get all logs emitted
    var filter = { address: addresses.Moulinette, 
        fromBlock: fromBlock, toBlock: toBlock 
    };
    // Query logs based on the filter
    const logsMO = await provider.getLogs(filter)
    logsMO.forEach((log) => {
      try {
          // Decode the log using the contract's interface
          const parsedLog = MO.interface.parseLog(log)
          // Custom handling of BigInt serialization
          const argsWithBigIntConverted = JSON.stringify(parsedLog.args, (key, value) =>
              value.toString()
          )
          console.log(`Event: ${parsedLog.name}`)
          console.log(`Args: ${argsWithBigIntConverted}`)
      } catch (error) {
          console.error("Error decoding log:", error)
      }
      console.log(`Block Number: ${log.blockNumber}`)
      console.log(`Transaction Hash: ${log.transactionHash}`)
      console.log('----------------------------------------')
    });
    // event SpecificEvent(address quid);
    // MO.on("SpecificEvent", (quidAddress) => {
    //   console.log(`Quid address set to: ${quidAddress}`);
    // });
    // filter = { address: addresses.Quid, 
    //     fromBlock: fromBlock, toBlock: toBlock 
    // };
    // // Query logs based on the filter
    // const logsQD = await provider.getLogs(filter);
    // // TODO test medianiser
    // logsQD.forEach((log) => {
    //     try {
    //         // Decode the log using the contract's interface
    //         const parsedLog = QD.interface.parseLog(log);
    //         // Custom handling of BigInt serialization
    //         const argsWithBigIntConverted = JSON.stringify(parsedLog.args, (key, value) =>
    //             value.toString()
    //         );
    //         console.log(`Event: ${parsedLog.name}`);
    //         console.log(`Args: ${argsWithBigIntConverted}`);
    //     } catch (error) {
    //         console.error("Error decoding log:", error);
    //     }
    //     console.log(`Block Number: ${log.blockNumber}`);
    //     console.log(`Transaction Hash: ${log.transactionHash}`);
    //     console.log('----------------------------------------');
    // });
    var balance
    var tx; var receipt
    const threeWeeks = '22' // in seconds
    const sixWeeks = '44'

    const grant = '50000000000000000000'
    const bill = '100000000000000000000'
    const rack = '1000000000000000000000'
    if (shouldDeploy) {
      console.log('minting 1k USDE to', beneficiary.address)
      await USDE.mint()
      console.log('minting 1k USDE to', secondary.address)
      await USDEwithSecondary.mint()

      balance = await USDE.balanceOf(beneficiary.address)
      console.log('balance beneficiary', balance)

      balance = await USDE.balanceOf(secondary.address)
      console.log('balance beneficiary', balance)

      console.log('approving beneficiary')
      tx = await USDE.approve(addresses.Moulinette, rack)
      await tx.wait()
  
      tx = await USDEwithSecondary.approve(addresses.Moulinette, rack)
      await tx.wait()
  
      receipt = await USDE.allowance(beneficiary.address, addresses.Moulinette)
      console.log('allowance', receipt)
      receipt = await USDEwithSecondary.allowance(secondary.address, addresses.Moulinette)
      console.log('allowance', receipt)
    }
    try {
      tx = await MO.deposit(beneficiary.address, bill, addresses.USDe, false)
      await tx.wait() 
      console.log('fastForwarding')
      tx = await QD.fast_forward(threeWeeks)
      await tx.wait() 
      
      // fastForward a bit, try deposit again
      tx = await MOWithSecondary.deposit(secondary.address, bill, addresses.USDe, false)
      await tx.wait() 

      balance = await QD.balanceOf(beneficiary.address)
      console.log('balance of beneficiary', balance)
      balance = await QD.balanceOf(secondary.address)
      console.log('balance of secondary', balance)
    }
    catch (error) {
      console.error("Error in USDe deposit:", error)
    }
    balance = await sUSDE.balanceOf(addresses.Moulinette)
    console.log('sUSDe balance MO after', balance)
    
    tx = await QD.fast_forward(sixWeeks)
    await tx.wait() 

    // TODO transfer QD from one to the other and 
    // observe how the transferHelper and creditHelper
    // will respond
    tx = await QDwithSecondary.transfer(beneficiary.address, grant)
    await tx.wait()

    tx = await MO.get_info(beneficiary.address)
    console.log("get_info(beneficiary):", tx.toString())

    tx = await MO.get_info(secondary.address)
    console.log("get_info(secondary):", tx.toString())
    
    // const amountInWei = ethers.parseEther("0.01");
    // const largeAmountInWei = ethers.parseEther("0.1");
    // const WETH = '0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14';
    // var myETH = await provider.getBalance(beneficiary) 
    // var before = new BN(myETH.toString())
    // console.log('myETH before deposit', before.toString())
    // // now that we have insurance capital (USDe), we can 
    // // actually insure some ETH (up to $265 worth)
    // //const gasLimit = 5_000_000; // High gas limit

    // try {
    //   tx = await MO.deposit(beneficiary, 0, WETH, false, {
    //     value: amountInWei // Attach Ether to transaction
    //     //gasLimit 
    //   });
    //   await tx.wait()
    // } catch (error) {
    //     console.error("Error in ETH deposit:", error)
    // }
    
    // tx = await MO.get_more_info(addresses.Moulinette)
    // console.log("get_more_info(MO):", tx.toString());
    
    // myETH = await provider.getBalance(beneficiary) // TODO print before and after
    // console.log('myETH after deposit', myETH)
    // myETH =  new BN(myETH.toString())
    // var difference = before.sub(myETH)
    // console.log('difference', difference.toString())

    // tx = await MO.get_more_info(beneficiary)
    // console.log("get_more_info(beneficiary):", tx.toString());

    // var cap = await MO.capitalisation(0, false)
    // console.log('capitalisation...', cap.toString())
    
    // try {
    //   tx = await MO.withdraw(bill, true, {
    //     value: largeAmountInWei
    //   })
    //   await tx.wait()
    // } catch (error) {
    //   console.error("Error in withdraw:", error)
    // }
   
    // simulate a price drop, so that we can claim 
    // tx = await MO.set_price_eth(false, false) 
    // await tx.wait()

    // console.log("calling fold")
    // // simulate a price drop, so that we can claim 
    // tx = await MO.fold(beneficiary, amountInWei, false) 
    // await tx.wait() // this seems to work!
 
    // try fold with sell
    // // simulate a price drop, so that we can claim 
    // tx = await MO.fold(beneficiary, amountInWei, true) 
    // await tx.wait() // this seems to work    

    // tx = await MO.get_more_info(beneficiary)
    // console.log("get_more_info() of beneficiary:", tx.toString());

    // tx = await MO.get_more_info(addresses.Moulinette)
    // console.log("get_more_info() of MO:", tx.toString());

    // balance = await QD.balanceOf(beneficiary)
    // console.log('balance QD...', balance)

    // TODO final
    // before we redeem, add another user,
    // add their coverage burden, and liquidation
    // we must do, finally, a fastForward by a year
    // then call redeem and see expected balances 
}  

// We recommend this pattern to be able to 
// use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error)
  process.exitCode = 1
});
