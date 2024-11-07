
// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.8; // EVM: london
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
    mapping(address => uint) public vaultShares; // $
    // re-deposited staked stablecoins in a basket...
    // https://www.law.cornell.edu/wex/consideration
    mapping(address => uint[16]) public consideration;
    // of legally sufficient value, bargained-for in 
    // an exchange agreement, for the breach of which
    // Moulinette gives an equitable remedy, and whose 
    // performance is recognised as reasonable duty or
    // tender (an unconditional offer to perform)...
    uint constant public MAX_PER_DAY = 777_777 * WAD;
    uint[90] public WEIGHTS; // sum of weights... 
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
    ERC4626 public immutable SUSDE;
    ERC20 public immutable USDE;
    // ERC4626 public immutable SFRAX;
    // ERC20 public immutable FRAX;
    // ERC4626 public immutable SDAI;
    // ERC20 public immutable DAI; 
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
        deployed = block.timestamp; // 11/11
        Moulinette = _mo; chainlink = _link;
        USDE = ERC20(_usde); SUSDE = ERC4626(_susde);
        // FRAX = ERC20(_frax); SFRAX = ERC4626(_sfrax);
        // DAI = ERC20(_dai); SDAI = ERC4626(_susde);
        // USDE.approve(_susde,  type(uint256).max);
        // FRAX.approve(_sfrax,  type(uint256).max);
        // DAI.approve(_sdai, type(uint256).max);
        SUSDE.approve(MORPHO, type(uint256).max);
    }
    
    function _min(uint _a, uint _b) internal 
        pure returns (uint) { return (_a < _b) ?
                                      _a : _b;
    } 
    function _minAmount(address from, address token, 
        uint amount) internal view returns (uint) {
        amount = _min(amount, ERC20(token).balanceOf(from));
        require(amount > 0, "insufficient balance"); return amount;
    }
    function qd_amt_to_dollar_amt(uint qd_amt) public 
        view returns (uint amount) { uint in_days = (
            (block.timestamp - START) / 1 days
        );  
        amount = (in_days * PENNY + START_PRICE) * qd_amt / WAD;
    }
    function get_total_deposits() public 
        view returns (uint total) {
        for (uint i = 0; i <= currentBatch(); i++) {
            total += Piscine[i][43].debit;
        }
    }
    function get_total_supply_cap() 
        public view returns (uint) {
        uint batch = currentBatch();
        uint in_days = ( // used in frontend...
            (block.timestamp - START) / 1 days
        ) + 1; return in_days * MAX_PER_DAY -
               Piscine[batch][43].credit; 
    }

    function get_shares_value() 
        public view returns (uint) {
        uint susde = SUSDE.convertToAssets(
            vaultShares[address(SUSDE)]
        ); /* uint sfrax = SFRAX.convertToAssets(
            vaultShares[address(SFRAX)]
        );  uint sdai = SDAI.convertToAssets(
            vaultShares[address(SDAI)]  
        ); */ return susde; // + sfrax + sdai; TODO
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
        } // TODO remove this testing fu
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
        if (to == address(0)) { // TODO when regular cdp burn this is not the right path
            i = int(matureBatches()); 
            _burn(from, amount);
            // no _calculateMedian `to`
        } else { i = int(currentBatch()); 
            console.log("MedianTransferHelper...TO", 
                balance_to, to_vote, this.balanceOf(to));
            // _calculateMedian(this.balanceOf(to), to_vote,
            //                     balance_to, to_vote);
        }   // loop from newest to oldest batch
        // until requested amount fulfilled...
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
                    require( /* token == address(DAI) || token == address(SDAI)
                    || token == address(FRAX) || token == address(FRAX) || */ 
                    token == address(USDE) || token == address(SUSDE), "$"); 
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
                    // so we must calculate amount twice here...
                    amount = FullMath.mulDiv(WAD, cost, price); 
                    consideration[pledge][batch] += amount;
                    _mint(pledge, amount); // totalSupply++
                    consideration[pledge][batch] += amount; 
                    Piscine[batch][in_days].credit += amount;
                    Piscine[batch][in_days].debit += cost;
                    Piscine[batch][43].credit += amount;  
                    Piscine[batch][43].debit += cost;
                    // TODO charge 20bps on the cost
                    MO(Moulinette).mint(pledge, cost, amount);
                    if (token == address(USDE)) {
                        USDE.transferFrom(msg.sender, address(this), cost); 
                        shares = SUSDE.deposit(cost, address(this));  
                        vaultShares[address(SUSDE)] += shares; 
                        IMorpho(MORPHO).supply(
                            IMorpho((MORPHO)).idToMarketParams(ID), 
                            amount, 0, address(this), ""); 
                    }}} address constant F8N = 0x3B3ee1931Dc30C1957379FAc9aba94D1C48a5405; 
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
            uint batch = currentBatch() - 1;
            // TODO is approval necessary?
            ICollection(F8N).transferFrom(
                address(this), from, LAMBO); 
            uint QD = draw(from, GRIEVANCES); 
            mint(from, QD, address(USDE)); 
            // TODO mint(QD / 2, from, MO(Moulinette).DAI())
            if (START != 0) { // BACKEND / 8 wu tang...TODO
                // uint random = uint(keccak256(
                //     abi.encodePacked(_seed, 
                //     block.prevrandao))) 
                // % voters[batch].length;
                // console.log("random....", random);
                // MO(Moulinette).setMetrics(AVG_ROI); 
                require(block.timestamp >= START + DAYS 
                && batch < 17, "re-up"); // "like a boomerang
            } // ...I need a...^^^^^^ same level, same rebel
            START = block.timestamp; //  a visionary, division 
            // is scary" ~ Logic...so the SEC won't let me be, 
            // they tried shut down on youtube.com/@quidmint
            consideration[from][batch] += BACKEND; // QD...
            // in the frontend, we do transferFrom in order
            // to receive NFT & pass in calldata for lotto
        } return this.onERC721Received.selector; // TODO ^
    }

    // TODO remove, testing only
    function restart() public { 
        if (START != 0) { uint batch = currentBatch();
            Pod memory day = Piscine[batch - 1][43];  
            AVG_ROI += FullMath.mulDiv(WAD, 
            day.credit - day.debit, day.debit);
            console.log("Restart...", batch, AVG_ROI);
            MO(Moulinette).setMetrics(AVG_ROI / 
                (DAYS / 1 days) * batch
            );  require(block.timestamp > START + DAYS &&
                    currentBatch() < 17, "can't restart");
        }  START = block.timestamp;            
    }

    function draw(address to, uint amount) 
        public onlyGenerators returns (uint QD) { 
            if (msg.sender == address(this)) { 
            amount = _min(amount, FullMath.mulDiv(
                get_shares_value(), PENNY * 2 / 10, 1));
            QD = MO(Moulinette).dollar_amt_to_qd_amt(
                MO(Moulinette).capitalisation(0, false), 
                    amount / 2); to = owner; 
        } 
        if (MO(Moulinette).capitalisation(0, false) > 100 && amount > 0) { 
            uint reserveSUSDE = ERC4626(SUSDE).balanceOf(address(this));
            require(amount <= get_shares_value(), "SUSDE");
            IMorpho(MORPHO).withdraw(IMorpho((MORPHO)).idToMarketParams(ID),
                    amount, 0, address(this), msg.sender);
    }


            // TODO does ^^^ return shares?
            // amount = _min(reserveSUSDE, amount);
            // require(pledges[address(this)].carry.debit 
            //     == reserveSDAI + reserveSUSDE, "don't add up");

            // uint totalBalance = reserveSDAI + reserveSUSDE;
            // uint newTotalBalance = totalBalance - amount;
            // uint targetBalance = newTotalBalance / 2;

            // uint withdrawFromSDAI = reserveSDAI > targetBalance ? 
            //                         reserveSDAI - targetBalance : 0;
            // uint withdrawFromSUSDE = reserveSUSDE > targetBalance ? 
            //                          reserveSUSDE - targetBalance : 0;

            // uint totalWithdrawn = withdrawFromSDAI + withdrawFromSUSDE;
            // if (totalWithdrawn < amount) {
            //     uint remainingAmount = amount - totalWithdrawn;
            //     if (reserveSDAI - withdrawFromSDAI > remainingAmount / 2) {
            //         withdrawFromSDAI += remainingAmount / 2;
            //         remainingAmount -= remainingAmount / 2;
            //     } else {
            //         withdrawFromSDAI += reserveSDAI - withdrawFromSDAI;
            //         remainingAmount -= reserveSDAI - withdrawFromSDAI;
            //     }
            //     if (reserveSUSDE - withdrawFromSUSDE > remainingAmount) {
            //         withdrawFromSUSDE += remainingAmount;
            //     } else {
            //         withdrawFromSUSDE += reserveSUSDE - withdrawFromSUSDE;
            //     }
            // }
            // ERC4626(SDAI).redeem(withdrawFromSDAI, to, address(this));
            ERC4626(SUSDE).withdraw(amount, to, address(this));
            // redeem takes amount of sUSDe you want to turn into USDe. 
            // withdraw specifies amount of USDe you wish to withdraw, 
            // and will pull the required amount of sUSDe from sender. 
            // TODO steps to withdraw from morpho (mainnet)
        }
    }
}