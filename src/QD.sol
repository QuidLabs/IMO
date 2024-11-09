
// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25; // EVM: london
import "lib/forge-std/src/console.sol"; // TODO delete
import {IMorpho, Position} from "./interfaces/IMorpho.sol";
import {ERC4626} from "lib/solmate/src/tokens/ERC4626.sol";
import {FullMath} from "./interfaces/math/FullMath.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {Owned} from "lib/solmate/src/auth/Owned.sol";
import "./interfaces/AggregatorV3Interface.sol";
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
import "./MOulinette.sol";
contract Quid is ERC20,
    IERC721Receiver,
    Owned(msg.sender) {
    uint public AVG_ROI;
    uint public START;  
    // "Walked in the 
    // kitchen, found a 
    // [Pod] to [Piscine]" ~ tune chi
    Pod[44][16] Piscine; // 16 batches
    uint constant PENNY = 1e16; 
    uint constant LAMBO = 16508;
    // 44th day stores batch's total...
    uint constant public DAYS = 43 days; 
    uint public START_PRICE = 50 * PENNY; 
    struct Pod { uint credit; uint debit; }
    // "they want their grievances aired on the assumption
    // that all right-thinking persons would be persuaded
    // that problems of the world can be solved," by true 
    // dough, Pierre, not your unsual money, version mint
    uint constant GRIEVANCES = 134420 * WAD; // in USDe
    uint constant BACKEND = 444477 * WAD; // x 16 (QD)
    // "16 bars keep the car running" ~ chamber music
    // https://www.law.cornell.edu/wex/consideration
    mapping(address => uint[16]) public consideration;
    // of legally sufficient value, bargained-for in 
    // an exchange agreement, for the breach of which
    // Moulinette gives an equitable remedy, and whose 
    // performance is recognised as reasonable duty or
    // tender (an unconditional offer to perform)...
    uint constant public MAX_PER_DAY = 777_777 * WAD;
    uint[90] public WEIGHTS; // sum of weights
    mapping(address => uint) internal perVault; 
    mapping(address => address) internal vaults;
    mapping (address => bool[16]) public hasVoted;
    // when a token-holder votes for a fee, their
    // QD balance is applied to the total weights
    // for that fee (weights are the balances)...
    // index 0 is the largest possible vote = 9%
    // index 89 represents the smallest one = 1%
    uint public deployed; uint internal K = 17;
    uint public SUM; // sum(weights[0...k]):
    mapping (address => uint) public feeVotes;
    address[][16] public voters; // by batch
    address public immutable DAI; 
    address public immutable SDAI;
    address public immutable SFRAX;
    address public immutable FRAX;
    address public immutable USDE;
    address public immutable SUSDE;
    uint internal _ETH_PRICE; // TODO 
    address public Moulinette; // windmill
    address internal chainlink;
    uint constant WAD = 1e18;
    modifier onlyGenerators { 
        address sender = msg.sender;
        require(sender == Moulinette ||
                sender == address(this), "!");
        _;
    } // en.wiktionary.org/wiki/MOulinette 
    modifier postLaunch { // of the windmill
        require(currentBatch() > 0, "after");  
        _; 
    }
    constructor(address _mo, address _link,
        address _usde, address _susde, 
        address _frax, address _sfrax,
        address _sdai, address _dai)
        ERC20("QU!D", "QD", 18) { // 2024-26
        START = block.timestamp;            
        deployed = START; // 11/11
        Moulinette = _mo; chainlink = _link;
        SDAI = _sdai; DAI = _dai; vaults[DAI] = SDAI;
        ERC20(DAI).approve(_sdai, type(uint256).max);
        FRAX = _frax; SFRAX = _sfrax; vaults[FRAX] = SFRAX;
        ERC20(FRAX).approve(_sfrax,  type(uint256).max);
        USDE = _usde; SUSDE = _susde; vaults[USDE] = SUSDE;
        ERC20(USDE).approve(_susde,  type(uint256).max);
        ERC4626(SUSDE).approve(MORPHO, type(uint256).max);
    }
    function _min(uint _a, uint _b) internal 
        pure returns (uint) { return (_a < _b) ?
                                      _a : _b;
    } 
    function _minAmount(address from, address token, 
        uint amount) internal returns (uint usd) {
        bool isDollar = false;
        if (token == address(SDAI)
        || token == address(SFRAX) 
        || token == address(SUSDE) ) {
            isDollar = true; usd =_min(amount, 
            ERC4626(token).convertToAssets(
            ERC4626(token).balanceOf(from)));
            perVault[token] += usd;
            amount = ERC4626(token).convertToShares(usd);
            ERC4626(token).transferFrom(msg.sender, 
                            address(this), amount); 
        }   else if (token == address(DAI) ||
                    token == address(FRAX) || 
                    token == address(USDE)) {
                    isDollar = true; usd = _min(amount, 
                    ERC20(token).balanceOf(from));
                    address vault = vaults[token]; perVault[vault] += usd;
                    ERC20(token).transferFrom(from, address(this), usd);
                    amount = ERC4626(vault).deposit(usd, address(this));
        }           require(isDollar && amount > 0 &&  perVault[SUSDE] >= 
        (perVault[SDAI] + perVault[SFRAX] + perVault[SUSDE]) / 2, "$");
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
    function get_total_deposits() 
        public view returns (uint) {
        uint dai = _min(perVault[SDAI], ERC4626(
            SDAI).maxWithdraw(address(this)));
        uint frax = _min(perVault[SFRAX], ERC4626(
            SFRAX).maxWithdraw(address(this)));
        uint usde = _min(perVault[SUSDE], ERC4626(
            SUSDE).maxWithdraw(address(this)));
        return dai + frax + usde; 
    }

    function vote(uint new_vote) external { 
        uint batch = currentBatch(); // 0-16
        if (batch < 16 
        && !hasVoted[msg.sender][batch]) {
            hasVoted[msg.sender][batch] = true;
            voters[batch].push(msg.sender);
        }
        uint old_vote = feeVotes[msg.sender];
        require(new_vote != old_vote &&
                new_vote < 89, "bad vote"); 
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
        // redeemable, batch reaches 24
        require(batch < 25, "42"); 
    }
    function matureBatches() 
        public view returns (uint) {
        uint batch = currentBatch(); 
        if (batch < 8) { return 0; }
        else if (batch < 25) {
            return batch - 8;
        } else { return 16; }
        // over 16 would result
        // in index out of bounds
        // in matureBalanceOf()...
    }
    function matureBalanceOf(address account)
        public view returns (uint total) {
        uint batches = matureBatches();
        for (uint i = 0; i < batches; i++) {
            total += consideration[account][i];
        }
    }
    function turn(address from, uint value) public
        onlyGenerators { MO(Moulinette).transferHelper(
            from, address(0), value); _transferHelper(
            from, address(0), value); // burn shouldn't 
            // affect carry.debit values of `from` or `to`
    }
    function transfer(address to, uint value) 
        public override(ERC20) returns (bool) {
        MO(Moulinette).transferHelper(msg.sender, 
            to, value); _transferHelper(msg.sender, 
            to, value); super.transfer(to, value);
    }
    function transferFrom(address from, address to, uint value) 
        public override(ERC20) returns (bool) {
        MO(Moulinette).transferHelper(from, 
            to, value); _transferHelper(from, 
            to, value); super.transferFrom(from, 
            to, value);
    }

    function set_price_eth(bool up,
        bool refresh) external { 
        if (refresh) { _ETH_PRICE = 0;
            _ETH_PRICE = getPrice();
        }   else { uint delta = _ETH_PRICE / 5;
            _ETH_PRICE = up ? _ETH_PRICE + delta 
                              : _ETH_PRICE - delta;
        } // TODO remove this testing function...
    }
    function getPrice() public 
        view returns (uint price) {
        if (_ETH_PRICE > 0) { 
            return _ETH_PRICE;
        }
        (, int priceAnswer,, 
        uint timeStamp,) = AggregatorV3Interface(chainlink).latestRoundData();
        uint8 answerDigits = AggregatorV3Interface(chainlink).decimals();
        price = uint(priceAnswer);
        require(timeStamp > 0 
            && timeStamp <= block.timestamp 
            && priceAnswer >= 0, "price");
        // Aggregator returns an 8-digit precision, 
        // but we handle the case of future changes
        if (answerDigits > 18) { price /= 10 ** (answerDigits - 18); }
        else if (answerDigits < 18) { price *= 10 ** (18 - answerDigits); } 
    }

    /** https://x.com/QuidMint/status/1833820062714601782
     *  Find value of k in range(0, len(Weights)) such that 
     *  sum(Weights[0:k]) = sum(Weights[k:len(Weights)+1]) = sum(Weights) / 2
     *  If there is no such value of k, there must be a value of k 
     *  in the same range range(0, len(Weights)) such that 
     *  sum(Weights[0:k]) > sum(Weights) / 2
     */ 
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
        uint balance_from = this.balanceOf(from); 
        uint balance_to = this.balanceOf(to); 
        uint from_vote = feeVotes[from];
        uint to_vote = feeVotes[to];
        amount = _min(amount, this.balanceOf(from));
        require(amount > WAD, "insufficient QD"); 
        int i; // must be int otherwise tx reverts
        // when we go below 0 in the while loop...
        if (to == address(0)) { 
            i = int(matureBatches()); 
            _burn(from, amount);
            // no _calculateMedian `to`
        } else { i = int(currentBatch()); 
            console.log("MedianTransferHelper...TO", 
                balance_to, to_vote, this.balanceOf(to));
            // _calculateMedian(this.balanceOf(to), to_vote,
            //                     balance_to, to_vote);
        }   
        while (amount > 0 && i >= 0) { uint k = uint(i);
            uint amt = consideration[from][k];
            // console.log("TransferHelper...", amt);
            if (amt > 0) { amt = _min(amount, amt);
                consideration[from][k] -= amt;
                // `to` may be address(0) but it's 
                // irrelevant, wastes a bit of gas
                consideration[to][k] += amt; 
                amount -= amt;
            }   i -= 1;
        }   require(amount == 0, "transfer");
        console.log("MedianTransferHelper...FROM", 
            balance_from, from_vote, this.balanceOf(from));
        // _calculateMedian(this.balanceOf(from), from_vote, 
        //                     balance_from, from_vote);
    }

    function mint(address pledge, uint amount, address token) 
        public returns (uint cost, uint shares) { 
            uint batch = currentBatch();
            if (token == address(this)) { _mint(pledge, amount); 
                consideration[pledge][batch] += amount; // redeemable
                require(msg.sender == Moulinette, "!"); // authorisation
            }   else if (block.timestamp <= START + DAYS && batch < 16) {
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
                    // 44th row is a total for the batch
                    Piscine[batch][43].credit += amount;  
                    Piscine[batch][43].debit += cost;
                    MO(Moulinette).mint(pledge, cost, amount);            
                }
        } address constant F8N = 0x3B3ee1931Dc30C1957379FAc9aba94D1C48a5405; 
        address constant QUID = 0x42cc020Ef5e9681364ABB5aba26F39626F1874A4;
        address constant FOLD = 0xA0766B65A4f7B1da79a1AF79aC695456eFa28644;
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
        address from, // previous owner 
        uint tokenId, bytes calldata data 
    ) external override returns (bytes4) { 
        address parker = ICollection(F8N).ownerOf(LAMBO);
        require(data.length >= 32, "Insufficient data");
        bytes32 _seed = abi.decode(data[:32], (bytes32));         
        if (tokenId == LAMBO && parker == address(this)) {
            ICollection(F8N).approve(from, LAMBO);
            ICollection(F8N).transferFrom( // return
                address(this), from, LAMBO); 
                draw(from, GRIEVANCES / 3); 
                draw(QUID, GRIEVANCES / 3); 
                draw(FOLD, GRIEVANCES / 3); 
                uint batch = currentBatch();

            Pod memory day = Piscine[batch - 1][43];  
            AVG_ROI += FullMath.mulDiv(WAD, 
            day.credit - day.debit, day.debit);
            MO(Moulinette).setMetrics(AVG_ROI / 
                (DAYS / 1 days) * batch
            );
            // TODO
            console.log("Restart...", batch, AVG_ROI);
                uint random = uint(keccak256(
                    abi.encodePacked(_seed, 
                    block.prevrandao))) 
                % voters[batch].length;
                console.log("random....", random);

            require(block.timestamp >= START + DAYS 
            && batch < 17, "re-up"); // "like a boomerang
            // ...I need a...^^^^^^ same level, same rebel
            START = block.timestamp; // that never settled
            consideration[from][batch] += BACKEND; // QD
            // in the frontend, safetransferFrom in order
            // to receive NFT, pass in calldata for lotto
        } return this.onERC721Received.selector; 
    }

    function draw(address to, uint amount) 
        public onlyGenerators returns (uint QD) { 
            uint total = get_total_deposits();
            if (msg.sender == address(this)) { 
            amount = _min(amount, 
                FullMath.mulDiv(total, 
                    PENNY * 2 / 10, WAD));
        }   require(amount > 0, "no thing");
        if (MO(Moulinette).capitalisation(0, false) > 100) { 
            uint dai = FullMath.mulDiv(amount, FullMath.mulDiv(WAD, 
                                        perVault[SDAI], total), WAD);

            uint frax = FullMath.mulDiv(amount, FullMath.mulDiv(WAD, 
                                        perVault[SFRAX], total), WAD);

            uint usde = FullMath.mulDiv(amount, FullMath.mulDiv(WAD, 
                                        perVault[SUSDE], total), WAD);
            require(amount <= total 
            && (dai + frax + usde) <= amount, "cash imbalance");
            if (dai > 0) {
                ERC4626(SDAI).withdraw(dai, to, address(this));
                perVault[SDAI] -= dai;
            }
            if (frax > 0) {
                ERC4626(SFRAX).withdraw(frax, to, address(this));
                perVault[SFRAX] -= frax;
            }
            if (usde > 0) {
                ERC4626(SUSDE).withdraw(usde, to, address(this));
                perVault[SUSDE] -= usde;
            }
            // TODO uncomment and test after everything else
            /* (uint susde, ) = IMorpho(MORPHO).withdraw(
                IMorpho((MORPHO)).idToMarketParams(ID),
                    amount, 0, address(this), msg.sender); */
                // Morpho conditionally invoked through carry
                // trade if staking reward of sUSDe is higher
                // than cost to borrow DAI and stake as sDAI;
                // needs logic to unwind and payoff debt if 
                // the situation switches to the opposite...
                // conditional invocation should also account
                // for the capitalisation gap, this may be a 
                // systemic lender of last resort bailout hook
        }
    } else if (MO(Moulinette).capitalisation(0, false) < 57)
}