
## iM ~~Opinion~~ [Offer](http://hackmd.io/@quid/mint) 
insurers `mint` **Q**ui**D** for  
`USDe`xUSDS...Over 2yr  
are 16 chances  to `mint`:  
8 per year times [43 days](https://bit.ly/3q4tShS),   
"yesterday's price is *not*  
today's," 46% `AVG_ROI`  
(before `redeem`); [when](https://github.com/QuidLabs/IMO/blob/main/contracts/MOulinette.sol#L355)   
accounts receivable (QD)  

equal to payables for future  
cash flow from ΞTH deployed  
in UniV3 over time...fees are  
retained to capitalise QD with  
**gradated** `fold` [deductibles](https://github.com/QuidLabs/IMO/blob/main/contracts/MOulinette.sol#L800)  

hedging against 10% drops,  
ΞTH insured can't exceed $  
staked as insurance capital,  
[as well as sUSDe](https://github.com/QuidLabs/IMO/blob/main/contracts/MOulinette.sol#L691), and the  
total coverage [carryable](https://en.wikipedia.org/wiki/Cost_of_carry) is  
capped by `carry.debit`.

Levering long while buying  
insurance (at the same time)  
protects against liquidations.  
Deductible is initially [357](http://www.niagaramasons.com/Info%20Stuff/The%20Winding%20Staircase.PDF)bp;   

APY is [distributed](https://www.youtube.com/clip/UgkxOMAUJfrx-_ABwnargyEURpPygXEXJ_d9) relative to  
one's ROI vs. `AVG_ROI`, by    
absorbing liabilties upon  
maturity, when any holder  

may `redeem` 1 QD for $1.  
Voting is incentivised by  
8 x 55k QD, distributed  
16x `onERC721Received`.  

- electric ignition system (nervous system):  
  `deposit` ΞTH if nervous about its price,  
  or USDe to maximise your time value of $

- `repackNFT`: fuel management system...  
   most of the functionality is internal (send  
    wei gas to cylinders, combined with air)
    - controlled by the electrical system,  
  as are its sensors, observing temp.  
  (TWAP) and air density (tick range)

- `redeem` engine has a cooling system for absorbing  
  ~~liabilities~~ breaks, ~~clutch~~ CDP hydraulic `withdraw` 
  - cannot withdraw without steering (`vote`)...  
  and suspension is related: determines your  
  ride quality (`fold` suspension/liquidation)

Speaking of cars, another decent  
analogy is [carbide](https://www.instagram.com/p/C_t_orDph5p/) lamps...**fiat** *lux*  
(let there be light); regarding lime,  
note 🇺🇦 [70/30](https://www.instagram.com/p/DAgKU2dxtUq/) here  corresponds  
to the initial capitalisation of QD...  
Earth's surface is also 71% liquid,     

`Offer` time value QD = [💯%]() backed   
 © 2022-2026 QuidMint Foundation  
This software `README` is about material   
of Quid Labs; quid.io owned by QU!D LTD  
THIS `README` IS PROVIDED "AS IS," AND  
© HOLDERS MAKE NO REPRESENTATIONS  

WARRANTIES, EXPRESS OR IMPLIED, INCLUDING,   
NOT LIMITED TO, MERCHANTABILITY WARRANTIES    
OF [FITNESS](https://x.com/QuidMint/status/1840815343364677821) FOR A PARTICULAR PURPOSE OR TITLE.  

THE CONTENTS OF `README` ARE SUITABLE FOR  
IMPLEMENTATION WITHOUT INFRINGING ANY 3RD  
PARTY PATENTS, COPYRIGHTS, OR TRADEMARKS.   
COPYRIGHT HOLDERS WILL NOT BE LIABLE FOR  
DIRECT, INDIRECT, OR [UNUSUAL](https://github.com/QuidLabs/IMO/blob/main/contracts/QD.sol#L36)/CONSEQUENTIAL  
DAMAGES ARISING OUT OF [PERFORMANCE](https://x.com/lex_node/status/1845182121553559770): ANY   
USE OF CONTENTS OR THEIR IMPLEMENTATION.  

### Launch instructions
`npm install` from the root directory,   
`SHOULD_DEPLOY=true npx hardhat run`  
`--network sepolia scripts/`[deploy.js](https://github.com/QuidLabs/IMO/blob/main/scripts/deploy.js)  
`cd ./frontend && npm install && npm run dev`  
if you run it again with `DEPLOY=false` make sure  
to comment out the `fast_forward()` line which  
2 years expends; `currentBatch` 17 is the last.  
