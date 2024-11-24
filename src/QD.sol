
// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25; // EVM: london
import "lib/forge-std/src/console.sol"; // TODO delete
import {IMorpho, MarketParams} from "./interfaces/morpho/IMorpho.sol";
import {MorphoBalancesLib} from "./interfaces/morpho/libraries/MorphoBalancesLib.sol";
import {ReentrancyGuard} from "lib/solmate/src/utils/ReentrancyGuard.sol";
import {ERC4626} from "lib/solmate/src/tokens/ERC4626.sol";
import {FullMath} from "./interfaces/math/FullMath.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import "./interfaces/IERC721.sol";
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
contract Quid is ERC20,
    IERC721Receiver,
    ReentrancyGuard {
    uint public AVG_ROI;
    uint public START;
    // "Walked in the
    // kitchen, found a
    // [Pod] to [Piscine]" ~ 2 tune chi
    Pod[44][24] Piscine; // 24 batches
    uint constant PENNY = 1e16; 
    uint constant LAMBO = 16508;
    // 44th day stores batch's total...
    uint constant public DAYS = 42 days;
    uint public START_PRICE = 50 * PENNY;
    // "keep it 8 more than 92 with me..."
    struct Pod { uint credit; uint debit; }
    // "they want their grievances aired on the assumption
    // that all right-thinking persons would be persuaded
    // that problems of the world can be solved," by true
    // dough, Pierre, not your usual money...version mint
    uint constant GRIEVANCES = 113310303333333333333333;
    uint constant BACKEND = 666699333333333333333333;
    mapping(address => uint[24]) public consideration;
    // of legally sufficient value, bargained-for in
    // an exchange agreement, for the breach of which
    // Moulinette gives an equitable remedy, and whose
    // performance is recognised as reasonable duty or
    // tender (an unconditional offer to perform)...
    uint constant public MAX_PER_DAY = 777_777 * WAD;
    uint[90] public WEIGHTS; // sum of weights
    mapping(address => uint) internal perVault;
    mapping(address => address) internal vaults;
    mapping (address => bool[24]) public hasVoted;
    // when a token-holder votes for a fee, their
    // QD balance is applied to the total weights
    // for that fee (weights are the balances)...
    // index 0 is the largest possible vote = 9%
    // index 89 represents the smallest one = 1%
    uint public deployed; uint internal K = 17;
    uint public SUM; // sum(weights[0...k]):
    mapping (address => uint) public feeVotes;
    address[][24] public voters; // by batch
    // based on British Columbia's legislated
    // deposit-return system for leverage 
    // containers, entitled to limit... 
    // total mature batches to only 24,
    // 12 in each batch (jury members)...
    mapping (address => bool) public winners;
    // ^the mapping prevents lotto duplicates
    address payable public Moulinette; // MO
    // en.wiktionary.org/wiki/moulinette
    uint constant STACK = 10000 * WAD;
    address public immutable USDC;
    address public immutable DAI;
    address public immutable SDAI;
    address public immutable SFRAX;
    address public immutable FRAX;
    address public immutable USDE;
    address public immutable SUSDE;
    uint public COLLATERAL; // ^
    uint constant WAD = 1e18;
    modifier onlyGenerators {
        address sender = msg.sender;
        require(sender == Moulinette ||
                sender == address(this), "!?");
        _;
    } 
    constructor(address _mo, // спутник
        address _usde, address _susde,
        address _frax, address _sfrax,
        address _sdai, address _dai)
        ERC20("QU!D", "QD", 18) {
        START = block.timestamp;
        /* START = 1733333333; */
        SDAI = _sdai; DAI = _dai;
        FRAX = _frax; SFRAX = _sfrax;
        USDE = _usde; SUSDE = _susde;
        vaults[USDC] = USDC; vaults[DAI] = SDAI;
        vaults[FRAX] = SFRAX; vaults[USDE] = SUSDE;
        deployed = START; Moulinette = payable(_mo);
        USDC = address(MO(Moulinette).token0());
        ERC20(DAI).approve(_sdai, type(uint256).max);
        ERC20(DAI).approve(MORPHO, type(uint256).max);
        ERC20(FRAX).approve(_sfrax,  type(uint256).max);
        ERC20(USDE).approve(_susde,  type(uint256).max);
        ERC4626(SUSDE).approve(MORPHO, type(uint256).max);
    }
    function _min(uint _a, uint _b) internal
        pure returns (uint) { return (_a < _b) ?
                                      _a : _b;
    } 
    function _minAmount(address from,
        address token, uint amount)
        internal returns (uint usd) {
        bool isDollar = false; // $
        if (token == address(SDAI)
         || token == address(SFRAX) 
         || token == address(SUSDE)) {
            isDollar = true; amount = _min(
                ERC4626(token).balanceOf(from),
                ERC4626(token).convertToShares(amount)
            );
            usd = ERC4626(token).convertToAssets(amount);        
            ERC4626(token).transferFrom(msg.sender,
                            address(this), amount);
                            perVault[token] += usd;
        }  
        else if (token == address(DAI)  ||
                 token == address(FRAX) ||
                 token == address(USDE) ||
                 token == USDC) { 
                isDollar = true; usd = _min(amount,
                ERC20(token).balanceOf(from));
                address vault = vaults[token];
                perVault[vault] += usd;
                if (vault != USDC) {
                    ERC20(token).transferFrom(from,
                                    address(this), usd);

                    amount = ERC4626(vault).deposit(
                                usd, address(this));
                } 
                else { ERC20(USDC).transferFrom(
                        from, Moulinette, usd); 
                }
        } require(isDollar && amount > 0, "$");
    }
    function qd_amt_to_dollar_amt(uint qd_amt) public
        view returns (uint amount) { uint in_days = (
            (block.timestamp - START) / 1 days
        );  amount = (in_days * PENNY
            + START_PRICE) * qd_amt / WAD;
    }
    function get_total_supply_cap()
        public view returns (uint) {
        uint batch = currentBatch();
        uint in_days = ( // used in frontend...
            (block.timestamp - START) / 1 days
        ) + 1; return in_days * MAX_PER_DAY -
               Piscine[batch][43].credit;
    }
    function get_total_deposits(bool usdc)
        public view returns (uint total) {
        total += _min(perVault[SDAI], ERC4626(
            SDAI).maxWithdraw(address(this)));

        total += _min(perVault[SFRAX], ERC4626(
            SFRAX).maxWithdraw(address(this)));

        total += _min(perVault[SUSDE], ERC4626(
            SUSDE).maxWithdraw(address(this)));

        return usdc ? total + 
        perVault[USDC] * 1e12 : total;
    } 
    // TODO decrement USDC which is in UNI? metrics in repack
    // require(msg.sender.code.length == 0, "re-entrancy");
    // require(msg.sender == tx.origin, "re-entrancy");
    function vote(uint new_vote) external {
        uint batch = currentBatch(); // 0-24
        if (batch < 24
        && !hasVoted[msg.sender][batch]) {
            (uint carry,) = MO(Moulinette).get_info(msg.sender);
            if (carry > STACK) {
                hasVoted[msg.sender][batch] = true;
                voters[batch].push(msg.sender);
            }
        }
        uint old_vote = feeVotes[msg.sender];
        require(new_vote != old_vote &&
                new_vote <= 89, "bad vote");
        // +11 max vote = 9.0% deductible...
        feeVotes[msg.sender] = new_vote;
        uint stake = this.balanceOf(msg.sender);
        _calculateMedian(stake, old_vote,
                         stake, new_vote);
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
        public onlyGenerators returns (bool) {
            MO(Moulinette).transferHelper(
            from, address(0), value); _transferHelper(
            from, address(0), value); // burn shouldn't
            // affect carry.debit values of `from` or `to`
    }
    function transfer(address to, uint value)
        public override(ERC20) returns (bool) {
        uint sent = MO(Moulinette).transferHelper(
            msg.sender, to, value); 
            if (sent > 0) {
                _transferHelper(msg.sender,
                to, sent); super.transfer(
                                to, sent);
            }
    }
    function transferFrom(address from, address to,
        uint value) public override(ERC20) returns (bool) {
        MO(Moulinette).transferHelper(from, to, value);
                      _transferHelper(from, to, value);
        if (msg.sender != Moulinette) { // used in fold
            super.transferFrom(from, to, value);
        }
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
                )) { SUM -= WEIGHTS[K]; K -= 1;
                    console.log("MedianizerOne...", K, SUM, WEIGHTS[K]);
                }
            } else { 
                while (SUM < mid) {
                    K += 1; SUM += WEIGHTS[K];
                    console.log("MedianizerTwo...", K, SUM, WEIGHTS[K]);
                }
            } MO(Moulinette).setFee(K);
        }  else { SUM = 0; } // reset
    }

    function _transferHelper(address from,
        address to, uint amount) internal {
        uint from_vote = feeVotes[from];
        uint balance_from = this.balanceOf(from);
        amount = _min(amount, this.balanceOf(from));
        require(amount > WAD, "insufficient QD");
        int i; // must be int otherwise tx reverts
        // when we go below 0 in the while loop...
        if (to == address(0)) {
            i = int(matureBatches());
            _burn(from, amount);
            // no _calculateMedian `to`
        }   else { i = int(currentBatch());
            uint to_vote = feeVotes[to];
            uint balance_to = this.balanceOf(to);
            console.log("MedianTransferHelper...TO",
               balance_to, to_vote, this.balanceOf(to));
            _calculateMedian(this.balanceOf(to), to_vote,
                                balance_to, to_vote);
        }   
        while (amount > 0 && i >= 0) { uint k = uint(i);
            uint amt = consideration[from][k];
            console.log("TransferHelper...", amt);
            if (amt > 0) { amt = _min(amount, amt);
                consideration[from][k] -= amt;
                // `to` may be address(0) but it's
                // irrelevant, wastes a bit of gas
                consideration[to][k] += amt;
                amount -= amt;
            }   i -= 1;
        }   require(amount == 0, "transfer");
        console.log("MedianTransferHelper...FROM",
           balance_from, from_vote);
        _calculateMedian(balance_from, from_vote,
                        balance_from, from_vote);
    }

    function mint(address pledge, uint amount, address token)
        public returns (uint cost, uint shares) { // 7 possible $
            uint batch = currentBatch(); //
            if (token == address(this)) { _mint(pledge, amount);
                consideration[pledge][batch] += amount; // redeemable
                require(msg.sender == Moulinette, "keine authorisation");
            }   else if (block.timestamp <= START + DAYS && batch < 24) {
                    uint in_days = ((block.timestamp - START) / 1 days);
                    require(amount >= 10 * WAD, "mint more QD");
                    require(Piscine[batch][43].credit + amount <
                            (in_days + 1) * MAX_PER_DAY, "cap");
                    // Yesterday's price is NOT today's price,
                    // and when I think I'm running low, you're
                    uint price = in_days * PENNY + START_PRICE;
                    cost = _minAmount(pledge, token,
                        FullMath.mulDiv(price, amount,
                        WAD)); // _minAmount may return less
                    // so we must calculate amount twice here:
                    amount = FullMath.mulDiv(WAD, cost, price);
                    consideration[pledge][batch] += amount;
                    _mint(pledge, amount); // totalSupply++
                    consideration[pledge][batch] += amount;
                    Piscine[batch][in_days].credit += amount;
                    Piscine[batch][in_days].debit += cost;
                    // 44th row is the total for the batch
                    Piscine[batch][43].credit += amount;
                    Piscine[batch][43].debit += cost;
                    MO(Moulinette).mint(pledge, cost, amount);
                }
        } address constant F8N = 0x3B3ee1931Dc30C1957379FAc9aba94D1C48a5405;
         address constant QUID = 0x42cc020Ef5e9681364ABB5aba26F39626F1874A4;
       address constant MORPHO = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    bytes32 constant ID = 0x1247f1c237eceae0602eab1470a5061a6dd8f734ba88c7cdc5d6109fb0026b28;
    /** Whenever an {IERC721} `tokenId` token is transferred to this ERC20: ratcheting batch
     * @dev Safe transfer `tokenId` token from `from` to `address(this)`, checking that the
    recipient prevent tokens from being forever locked.
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
        uint batch = currentBatch(); // 1 - 24 (3 years)
        require(block.timestamp > START + DAYS, "early");
        require(data.length >= 32, "insufficient bytes");
        bytes32 _seed = abi.decode(data[:32], (bytes32));
        if (tokenId == LAMBO && ICollection(F8N).ownerOf(
            LAMBO) == address(this)) { address winner;
            uint cut = GRIEVANCES / 2; uint count = 0;
            ICollection(F8N).transferFrom( // return
                address(this), QUID, LAMBO); // NFT...
            this.draw(QUID, cut); this.draw(from, cut);
            uint backend = BACKEND; cut = backend / 12;
            if (voters[batch - 1].length >= 10) {
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
            _batchup(batch); // "like a boomerang, I need
            // a repeat...same level, same rebel that 
            // never settled and overcame the get owe"
        } return this.onERC721Received.selector;
    }

    function _batchup (uint batch)
        internal { Pod memory day =
        require(batch > 1 && batch < 25, "!");
        Piscine[batch - 1][43];
        
        AVG_ROI += FullMath.mulDiv(WAD,
        day.credit - day.debit, day.debit);
        MO(Moulinette).setMetrics(AVG_ROI /
            (DAYS / 1 days) * batch);
            START = block.timestamp;
    }
    function batchup() public {
        if (block.timestamp > 
        START + DAYS + 3 days) {
        _batchup(currentBatch());
    }}

    function draw(address to, uint amount)
        public onlyGenerators returns (uint) {
            uint total = get_total_deposits(false);
            // total does not include USDC because
            // we never transfer it out, we only
            // use it for the Uniswap LP position,
            // converting to WETH in MO.withdraw
            if (msg.sender == address(this)) {
                amount = _min(amount, 
                    FullMath.mulDiv(total, 
                        PENNY * 2 / 10, WAD));
        }   require(amount > 0, "no thing");
        (uint delta, ) = MO(Moulinette).capitalisation(0, false);
        uint borrowed = this.morph(delta); // can't go below this
        // amount in DAI, because we need to pay it back to Morpho
        uint dai = FullMath.mulDiv(amount, FullMath.mulDiv(WAD,
                                    perVault[SDAI], total), WAD);
                                    dai = _min(perVault[SDAI] -
                                                borrowed, dai);    
        uint usde = FullMath.mulDiv(amount, FullMath.mulDiv(WAD,
                                    perVault[SUSDE], total), WAD);
                                    usde = _min(perVault[SUSDE] - 
                                                COLLATERAL, usde);
        uint frax = _min(perVault[SFRAX], amount - (dai + usde));
        if (dai > 0) { 
            ERC4626(SDAI).withdraw(dai, 
                    to, address(this)); 
                    perVault[SDAI] -= dai;
        } if (frax > 0) { 
              ERC4626(SFRAX).withdraw(frax, 
                        to, address(this)); 
                        perVault[SFRAX] -= frax;
        } if (usde > 0) { 
                ERC4626(SUSDE).withdraw(usde, 
                        to, address(this)); 
                        perVault[SUSDE] -= usde;
        } return dai + frax + usde; // total $
    }

    function morph(uint delta) public onlyGenerators returns (uint borrowed) { 
        MarketParams memory params = IMorpho(MORPHO).idToMarketParams(ID);
        borrowed = MorphoBalancesLib.expectedBorrowAssets(IMorpho(MORPHO), 
            params, address(this)); 
        if (delta == 0 && borrowed > 0) {
            ERC4626(SDAI).withdraw(borrowed, 
                address(this), address(this));
                perVault[SDAI] -= borrowed;
            IMorpho(MORPHO).repay(params,
                borrowed, 0, address(this), "");
            
            IMorpho(MORPHO).withdrawCollateral(params,
                COLLATERAL, address(this), address(this)
            );
        } else if (delta > 0) { 
            uint collat = delta + delta / 5; // safe margin
            collat = _min(collat, perVault[SUSDE] - COLLATERAL);
            IMorpho(MORPHO).supplyCollateral(params,
                ERC4626(SUSDE).convertToShares(
                    collat), address(this), ""
            ); 
            COLLATERAL += collat; delta = collat - collat / 5;
            (uint dai, ) = IMorpho(MORPHO).borrow(params, delta, 
                0, address(this), address(this));  

            perVault[SDAI] += dai; 
            ERC4626(SDAI).deposit(
                dai, address(this));
        } return borrowed; 
    } 
}