
// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25; // EVM: london
import "lib/forge-std/src/console.sol"; // TODO delete logging, uncomment morpho
import {MorphoBalancesLib} from "./imports/morpho/libraries/MorphoBalancesLib.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "lib/solmate/src/utils/ReentrancyGuard.sol";
import {Pool} from "lib/aave-v3-core/contracts/protocol/pool/Pool.sol";
import {IMorpho, MarketParams} from "./imports/morpho/IMorpho.sol";
import {OFTOwnable2Step} from "./imports/OFTOwnable2Step.sol";
import {ERC4626} from "lib/solmate/src/tokens/ERC4626.sol";
import {FullMath} from "./imports/math/FullMath.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
interface ICollection is IERC721 {
    function latestTokenId()
    external view returns (uint);
}
// http://42.fr Piscine...
import "./MOulinette.sol";
contract Quid is OFTOwnable2Step, 
    IERC721Receiver, ReentrancyGuard { 
    using SafeTransferLib for ERC20;
    using SafeTransferLib for ERC4626;
    uint public AVG_ROI;
    uint public START;
    // "Walked in the
    // kitchen, found a
    // [Pod] to [Piscine]" ~ 2 tune chi
    Pod[43][24] Piscine; // 24 batches
    uint constant PENNY = 1e16; // 0.01
    // in for a penny, in for a pound...
    uint constant LAMBO = 16508; // NFT
    // 44th day stores batch's total...
    uint constant public DAYS = 42 days;
    uint public START_PRICE = 50 * PENNY;
    struct Pod { uint credit; uint debit; }
    uint[90] public WEIGHTS; // sum of weights
    mapping(address => uint) internal perVault;
    mapping(address => address) internal vaults;
    mapping (address => bool[24]) public hasVoted;
    mapping (address => uint) internal lastRedeemed;
    // token-holders vote for deductibles, and their
    // QD balances are applied to the total weights
    // for the voted % (weights are the balances)
    // index 0 is the largest possible vote = 9%
    // index 89 represents the smallest one = 1%
    uint public deployed; uint internal K = 17;
    uint public SUM; // sum(weights[0...k]):
    mapping (address => uint) public feeVotes;
    address[][24] public voters; // by batch
    mapping (address => bool) public winners;
    // ^the mapping prevents duplicates
    address payable public Moulinette; 
    address public immutable AAVE;
    address public immutable USDC;
    address public immutable DAI;
    address public immutable SDAI;
    address public immutable USDS;
    address public immutable SFRAX;
    address public immutable SUSDS;
    address public immutable FRAX;
    address public immutable CRVUSD;
    address public immutable SCRVUSD;
    address public immutable USDE;
    address public immutable SUSDE;
    uint public COLLATERAL; // ^
    uint constant WAD = 1e18;
    modifier onlyGenerators {
        address sender = msg.sender;
        require(sender == Moulinette ||
                sender == address(this), "!?");
        _;
    } // en.wiktionary.org/wiki/moulinette
    constructor(address _mo, address _usdc, 
        address _usde, address _susde,
        /* address _frax, address _sfrax,
         address _sdai, */ address _dai,
        address _usds, address _susds,
        address _crv, address _scrv, address _aave)
        OFTOwnable2Step("QU!D", "QD", LZ, QUID) { 
        AAVE = _aave; // START = 1733333333; // TODO base
        START = block.timestamp; // test-only
        /* SDAI = _sdai; */ deployed = START; 
        USDC = _usdc; USDE = _usde; 
        DAI = _dai; SUSDE = _susde; 
        USDS = _usds; SUSDS = _susds; 
        CRVUSD = _crv; SCRVUSD = _scrv;
        /* FRAX = _frax; SFRAX = _sfrax;
        vaults[FRAX] = SFRAX;
        vaults[DAI] = SDAI */
        vaults[DAI] = DAI;
        vaults[USDC] = USDC; 
        vaults[USDE] = SUSDE;
        vaults[USDS] = SUSDS;
        Moulinette = payable(_mo);
        if (address(MO(Moulinette).token0()) == USDC) {
            require(address(MO(Moulinette).token1())
            == address(MO(Moulinette).WETH9()), "42");
            ERC20(USDS).approve(SUSDS, type(uint).max);
            // ERC20(USDC).approve(AAVE, )
            ERC20(CRVUSD).approve(SCRVUSD, type(uint).max);
            ERC20(USDE).approve(SUSDE, type(uint).max);
            // ERC20(DAI).approve(SDAI, type(uint).max);
            // ERC20(FRAX).approve(SFRAX,  type(uint).max); // unstake and...
            // https://curve.fi/#/ethereum/pools/factory-stable-ng-32/deposit
            // SDAI can always be bought and unstaked for DAI to payoff debt
            // in Morpho deposit. must protect SUSDE collateral at all costs
            ERC4626(SUSDE).approve(MORPHO, type(uint).max);
            ERC20(DAI).approve(MORPHO, type(uint).max);
        } else { require(address(MO(Moulinette).token1())
              == USDC && address(MO(Moulinette).token0())
                == address(MO(Moulinette).WETH9()), "42");
                // ID = // TODO deploy market and hardcode
        }
    } uint constant GRIEVANCES = 113310303333333333333333;
    uint constant CUT = 4920121799152111; // of 3yr total:
    uint constant TITHE = GRIEVANCES / 10; // base min.
    uint constant BACKEND = 666666666666666666666666; 
    uint constant QD = 41666666666666664; // ~4.2% ^
    mapping(address => uint[24]) public consideration;
    // https://www.law.cornell.edu/wex/consideration
    uint constant public MAX_PER_DAY = 777_777 * WAD;
    function _min(uint _a, uint _b) internal
        pure returns (uint) { return (_a < _b) ?
                                      _a : _b;
    }
    function _minAmount(address from,
        address token, uint amount)
        internal returns (uint usd) {
        bool isDollar = false; // $ 
        if (token == SCRVUSD
         || token == SFRAX
         || token == SUSDE
         || token == SUSDS
         || token == SDAI) {
            // if (zeroForOne) TODO
            isDollar = true; amount = _min(
            ERC4626(token).balanceOf(from),
            ERC4626(token).convertToShares(amount));
            usd = ERC4626(token).convertToAssets(amount);
            ERC4626(token).transferFrom(msg.sender,
                            address(this), amount);
                            perVault[token] += usd;
                            // can't use per vault like
                            // this because value changes TODO
        } else if (token == DAI  ||
                   token == USDS ||
                   token == USDC || 
                   token == FRAX ||
                   token == USDE ||
                   token == CRVUSD) {
                   isDollar = true;
                usd = _min(amount,
                ERC20(token).balanceOf(from));
                address vault = vaults[token];
                perVault[vault] += usd;
                if (vault != USDC) {
                    ERC20(token).transferFrom(from,
                                address(this), usd);
                    amount = ERC4626(vault).deposit(
                                usd, address(this));
                } else { _depositUSDC(from, usd); }
        } require(isDollar && amount > 0, "$");
            // ERC20(token).transfer(
            //     ICollection(F8N).ownerOf(LAMBO), usd *),
    } 
    function _minAmountL2(address from,
        address token, uint amount) 
        internal returns (uint usd) {
        if (token == CRVUSD
         || token == USDE
         || token == USDS
         || token == DAI) {

        } else if (token == SCRVUSD
                || token == SUSDE
                || token == SUSDS) {

        } 
        // ERC20(token).transfer(
        //     ICollection(F8N).ownerOf(LAMBO), usd *),
    }

    // function withdrawUSDC(uint amount) onlyGenerators TODO

    function _depositUSDC(address from, 
        uint amount) internal {
        ERC20(USDC).transferFrom(
        from, Moulinette, amount);
        // apply discount to usd TODO
        // based on % of USDC in
        // total composition...
        Pool(AAVE).supply(USDC, 
        amount, address(this), 0);
    }

    function lastRedeem(address who) public view
        returns (uint) { return lastRedeemed[who]; }
   
    function qd_amt_to_dollar_amt(uint qd_amt) public
        view returns (uint amount) { uint in_days = (
            (block.timestamp - START) / 1 days
        );  amount = (in_days * PENNY
            + START_PRICE) * qd_amt / WAD;
    } // the current ^^^^ to mint()
    function get_total_supply_cap()
        public view returns (uint) {
        uint batch = currentBatch();
        uint in_days = ( // used in frontend...
            (block.timestamp - START) / 1 days
        ) + 1; return in_days * MAX_PER_DAY -
               Piscine[batch][42].credit;
    }
    function get_total_deposits(bool usdc)
        public view returns (uint total) {
        /* total += _min(perVault[SDAI], ERC4626(
            SDAI).maxWithdraw(address(this)));
           total += _min(perVault[SFRAX], ERC4626(
            SFRAX).maxWithdraw(address(this)));
        */ // TODO uncomment for L1 mainnet deploy

        if (MO(Moulinette).POOL().token0() == USDC) { // L2
            // total += 

            // total += 
        } else { // one for zero means ETH is token1
        // and we sell it for token0, used to buy ^
            total += _min(perVault[SUSDE], ERC4626(
                SUSDE).maxWithdraw(address(this)));
        }
        return usdc ? total + perVault[USDC]
             * 1e12 : total;
    }

    function vote(uint new_vote) external {
        uint batch = currentBatch(); // 0-24
        if (batch < 24
        && !hasVoted[msg.sender][batch]) {
            (uint carry,) = MO(Moulinette).get_info(msg.sender);
        if (carry > TITHE) { hasVoted[msg.sender][batch] = true;
                             voters[batch].push(msg.sender); }
        } uint old_vote = feeVotes[msg.sender];
        old_vote = old_vote == 0 ? 17 : old_vote;
        require(new_vote != old_vote &&
                new_vote <= 89, "bad vote");
        // +11 max vote = 9.0% deductible...
        uint stake = this.balanceOf(msg.sender);
        feeVotes[msg.sender] = new_vote;
        _calculateMedian(stake, old_vote,
                         stake, new_vote);
    }

    function _batchup(uint batch) internal {
        batch = _min(1, batch);
        require(batch < 25, "!");
        Pod memory day = Piscine[batch - 1][42];
        AVG_ROI += FullMath.mulDiv(WAD,
        day.credit - day.debit, day.debit);
        MO(Moulinette).setMetrics(AVG_ROI /
            (DAYS / 1 days) * batch);
            START = block.timestamp;
    }
    function currentBatch()
        public view returns (uint batch) {
        batch = (block.timestamp - deployed) / DAYS;
        // for the last 8 batches to be
        // redeemable, batch reaches 32,
        // for 24 mature batches total
        // require(batch < 33, "3 years");
    }
    function matureBatches()
        public view returns (uint) {
        uint batch = currentBatch();
        if (batch < 8) { return 0; }
        else if (batch < 33) {
            return batch - 8;
        } else { return 24; }
    }
    function matureBalanceOf(address account)
        public view returns (uint total) {
        uint batches = matureBatches();
        for (uint i = 0; i < batches; i++) {
            total += consideration[account][i];
        }
    }

    // turning a generator is what redeems it
    function turn(address from, uint value)
        public onlyGenerators returns (uint) {
        uint balance_from = this.balanceOf(from);
        lastRedeemed[from] = currentBatch();
        _transferHelper(from, address(0), value);
        // carry.debit will be untouched here...
        return MO(Moulinette).transferHelper(from,
                address(0), value, balance_from);
    }
    function transfer(address to, uint amount)
        public override returns (bool) {
        uint balance_from = this.balanceOf(msg.sender);
        uint value = _min(amount, balance_from);
        uint from_vote = feeVotes[msg.sender];
        bool result = true;
        if (to == Moulinette) {
            _burn(msg.sender, value);
        } else if (to != address(0)) {
            uint to_vote = feeVotes[to];
            uint balance_to = this.balanceOf(to);
            result = super.transfer(to, value);
            _calculateMedian(this.balanceOf(to),
                to_vote, balance_to, to_vote);
        } _transferHelper(msg.sender, to, value);
        uint sent = MO(Moulinette).transferHelper(
            msg.sender, to, value, balance_from);
        if (value != sent) { value = amount - sent;
            _mint(msg.sender, value);
            consideration[msg.sender][currentBatch()] += value;
        } else { _calculateMedian(this.balanceOf(msg.sender),
                        from_vote, balance_from, from_vote);
        } return result;
    }
    function transferFrom(address from, address to,
        uint amount) public override returns (bool) {
        uint balance_from = this.balanceOf(from);
        uint value = _min(amount, balance_from);
        uint from_vote = feeVotes[to];
        bool result = true;
        if (msg.sender != Moulinette) {
            uint to_vote = feeVotes[to];
            uint balance_to = this.balanceOf(to);
            result = super.transferFrom(from, to, value);
            _calculateMedian(this.balanceOf(to), to_vote,
                                balance_to, to_vote);
        } MO(Moulinette).transferHelper(
          from, to, value, balance_from);
        _transferHelper(from, to, value);
        _calculateMedian(this.balanceOf(from),
            from_vote, balance_from, from_vote);
        return result;
    }

    /** https://x.com/QuidMint/status/1833820062714601782
     *  Find value of k in range(0, len(Weights)) such that
     *  sum(Weights[0:k]) = sum(Weights[k:len(Weights)+1]) = sum(Weights) / 2
     *  If there is no such value of k, there must be a value of k
     *  in the same range range(0, len(Weights)) such that
     *  sum(Weights[0:k]) > sum(Weights) / 2
     */ // TODO debug
    function _calculateMedian(uint old_stake, uint old_vote,
        uint new_stake, uint new_vote) internal {
        if (old_vote != 17 && old_stake != 0) {
            WEIGHTS[old_vote] -= _min(
                WEIGHTS[old_vote], old_stake
            );
            if (old_vote <= K) {
                SUM -= _min(SUM, old_stake);
            }
        }   if (new_stake != 0) {
                if (new_vote <= K) {
                    SUM += new_stake;
                }
                WEIGHTS[new_vote] += new_stake;
        } uint mid = this.totalSupply() / 2;
        if (mid != 0) {
            if (K > new_vote) {
                while (K >= 1 && (
                    (SUM - WEIGHTS[K]) >= mid
                )) { SUM -= WEIGHTS[K]; K -= 1; }
            } else {
                while (SUM < mid) {
                    K += 1; SUM += WEIGHTS[K];
                }
            } MO(Moulinette).setFee(K);
        }  else { SUM = 0; } // reset
    }

    function _transferHelper(address from,
        address to, uint amount) internal {
        require(amount > WAD, "min. 1 QD");
        int i; // must be int or tx reverts
        // when we go below 0 in the loop
        if (to == address(0)) {
            i = int(matureBatches());
            _burn(from, amount);
        } 
        else { i = int(currentBatch()); }
        while (amount > 0 && i >= 0) { uint k = uint(i);
            uint amt = consideration[from][k]; // QD...
            if (amt > 0) { amt = _min(amount, amt);
                consideration[from][k] -= amt;
                if (to != address(0)) {
                    consideration[to][k] += amt;
                }   amount -= amt;
            }   i -= 1;
        }   require(amount == 0, "transfer");
    }

    function mint(address pledge, uint amount, address token)
        public nonReentrant { uint batch = currentBatch(); // 0-24
        if (token == address(this)) { _mint(pledge, amount); // QD
            consideration[pledge][batch] += amount; // redeem
            require(msg.sender == Moulinette, "keine anung");
        }   else if (block.timestamp <= START + DAYS && batch < 24) {
                uint in_days = ((block.timestamp - START) / 1 days);
                require(Piscine[batch][42].credit + amount <
                        (in_days + 1) * MAX_PER_DAY, "cap");
                // Yesterday's price is NOT today's price,
                // and when I think I'm running low, you're
                uint price = in_days * PENNY + START_PRICE;
                uint cost = _minAmount(pledge, token,
                    FullMath.mulDiv(price, amount, WAD));
                // _minAmount may return less being paid,
                // so we must calculate amount twice here:
                amount = FullMath.mulDiv(WAD, cost, price);
                consideration[pledge][batch] += amount;
                _mint(pledge, amount); // totalSupply++
                MO(Moulinette).mint(pledge, cost, amount);
                Piscine[batch][in_days].credit += amount;
                Piscine[batch][in_days].debit += cost;
                // 44th row is the total for the batch
                Piscine[batch][42].credit += amount + 
                FullMath.mulDiv(amount, QD, WAD); 
                Piscine[batch][42].debit += cost - 
                FullMath.mulDiv(cost, CUT, WAD);  
            } 
        } address constant LZ = 0x1a44076050125825900e736c501f859c50fE728c;
         address constant F8N = 0x3B3ee1931Dc30C1957379FAc9aba94D1C48a5405;
        address constant QUID = 0x42cc020Ef5e9681364ABB5aba26F39626F1874A4;
      address constant MORPHO = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    bytes32 constant ID = 0x1247f1c237eceae0602eab1470a5061a6dd8f734ba88c7cdc5d6109fb0026b28; // TODO deploy on base
    /** Whenever an {IERC721} `tokenId` token is transferred to this ERC20: ratcheting batch
     * @dev Safe transfer `tokenId` token from `from` to `address(this)`, checking that the
    recipient prevent tokens from being forever locked. An NFT is used as the _delegate is 
    an attribution of character, 
    * - `tokenId` token must exist and be owned by `from`
     * - If the caller is not `from`, it must have been allowed
     *   to move this token by either {approve} or {setApprovalForAll}.
     * - {onERC721Received} is called after a safeTransferFrom...
     * - It must return its Solidity selector to confirm the token transfer.
     *   If any other value is returned or the interface is not implemented
     *   by the recipient, the transfer will be reverted.
     */
    // QuidMint...foundation.app/@quid
    function onERC721Received(address,
        address from, // previous owner...
        uint tokenId, bytes calldata data)
        external override returns (bytes4) { 
        uint batch = currentBatch(); // 1 - 25 (3 years)
        require(block.timestamp > START + DAYS, "early");
        // pay if batch raised 70% only, otherwise if all
        // refunds were paid out (this piece is gas comp.)
        // by putting the stables into curve deposits, we
        // send in the pools in constructor, creating for 
        // L2 deploy. 
        if (tokenId == LAMBO && ICollection(F8N).ownerOf(
            LAMBO) == address(this)) { address winner;
            uint cut = GRIEVANCES / 2; uint count = 0;
            ICollection(F8N).transferFrom( // return
                address(this), QUID, LAMBO); // NFT...
            uint backend = BACKEND; cut = backend / 12;
            
            if (voters[batch - 1].length >= 10 && data.length >= 32) {
                bytes32 _seed = abi.decode(data[:32], (bytes32));
                for (uint i = 0; count < 10 && i < 30; i++) {
                    uint random = uint(keccak256(
                        abi.encodePacked(_seed,
                        block.prevrandao, i))) %
                        voters[batch - 1].length;
                        winner = voters[batch - 1][random];
                    if (!winners[winner]) {
                        count += 1; winners[winner] == true;
                        backend -= cut; _mint(winner, cut);
                        consideration[winner][batch] += cut;
                    }
                }
            } cut = backend; _mint(from, cut); // keep
            consideration[from][batch] += cut; // in QD
            _batchup(batch); // "like boomerang, I need
            // a repeat...same level, same rebel that
            // never settled and overcame get owe"
        } return this.onERC721Received.selector;
    }
    // failsafe to reboot
    // in case NFT owner
    // is unavailable to
    // rest the clock...
    function batchup()
        public nonReentrant {
        if (block.timestamp >
        START + DAYS + 3 days) {
        _batchup(currentBatch());

    }}

    function morph(address to, uint amount)
        public onlyGenerators returns (uint) {
            uint total = get_total_deposits(false);
            // total does not include USDC because
            // we never transfer it out, we only
            // keep it in AAVE, or (when needed):
            // use it for the Uniswap LP position,
            // converting to WETH in MO.withdraw
            if (msg.sender == address(this)) {
                // TODO account cost in mint()
                amount = _min(amount,
                    FullMath.mulDiv(total,
                        PENNY * 2 / 10, WAD));
        }   require(amount > 0, "no thing");
            uint dai; uint usde; uint frax;

        (uint delta, uint cap ) = MO(Moulinette).capitalisation(0, false);
        uint borrowed = 0;
        /*
        MarketParams memory params = IMorpho(MORPHO).idToMarketParams(ID);
        uint borrowed = MorphoBalancesLib.expectedBorrowAssets(
                        IMorpho(MORPHO), params, address(this));

        if (delta == 0 && borrowed > 0) {
            // TODO if zeroForOne it's L2
            ERC4626(SDAI).withdraw(borrowed,
                address(this), address(this));
                perVault[SDAI] -= borrowed;
            IMorpho(MORPHO).repay(params,
                borrowed, 0, address(this), "");

            IMorpho(MORPHO).withdrawCollateral(params,
                COLLATERAL, address(this), address(this));
        }
        else if (delta > 0 && perVault[SUSDE] > delta) {
            uint collat = delta + delta / 5; // safety margin
            collat = _min(collat, perVault[SUSDE] - COLLATERAL);
            if (collat > 0) {
                IMorpho(MORPHO).supplyCollateral(params,
                    ERC4626(SUSDE).convertToShares(
                        collat), address(this), "");

                COLLATERAL += collat; delta = collat - collat / 5;
                (dai, ) = IMorpho(MORPHO).borrow(params, delta, 0,
                                    address(this), address(this));

                perVault[SDAI] += dai;
                ERC4626(SDAI).deposit(
                    dai, address(this));
            }
        } */ // TODO create morpho market on Base
        // require(cap > 70, "minimum reserve requirement");
        dai = FullMath.mulDiv(amount, FullMath.mulDiv(WAD,
                                perVault[DAI], total), WAD);
                                dai = _min(perVault[DAI] -
                                            borrowed, dai); // TODO SDAI

        usde = FullMath.mulDiv(amount, FullMath.mulDiv(WAD,
                                perVault[SUSDE], total), WAD);
                                usde = _min(perVault[SUSDE] -
                                            COLLATERAL, usde);
        // frax = _min(perVault[SFRAX], amount - (dai + usde));
        if (dai > 0) {
            /*
            ERC4626(SDAI).withdraw(dai,
                    to, address(this));
                    perVault[SDAI] -= dai;
            */ // TODO enable on L1 mainnet
        } /* if (frax > 0) {
              ERC4626(SFRAX).withdraw(frax,
                        to, address(this));
                        perVault[SFRAX] -= frax;
        } */ if (usde > 0) {
                ERC4626(SUSDE).withdraw(usde,
                        to, address(this));
                        perVault[SUSDE] -= usde;
        } return (dai + frax + usde); // total $
    }
}
