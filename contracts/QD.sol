
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.8.8; 
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {FullMath} from "./interfaces/math/FullMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/AggregatorV3Interface.sol";
interface ICollection is IERC721 {
    function latestTokenId() 
    external view returns (uint);
}   import "./MOulinette.sol";
contract Quid is ERC20, 
    IERC721Receiver {
    uint public START;  
    // "Walked in the 
    // kitchen, found a 
    // [Pod] to [Piscine]" ~ tune chi
    Pod[44][16] Piscine; // 16 batches
    // 44th day stores batch's total...
    event Medianizer(uint k, uint sum_w_k); // TODO test
    event TransferHelper(uint amount);
    uint public blocktimestamp; // TODO remove (Sepolia)
    uint constant LAMBO = 16508; // TODO mainnet only
    uint constant public WAD = 1e18; 
    uint constant PENNY = WAD / 100;
    uint constant DIME = 10 * WAD;
    uint constant public DAYS = 43 days;
    uint public START_PRICE = 50 * PENNY;
    struct Pod { uint credit; uint debit; } 
    uint constant GRIEVANCES = 134420 * WAD; // in USDe
    uint constant BACKEND = 444477 * WAD; // x 16 (QD)
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
    // weights are also carried over transfers...
    // index 0 is the largest possible vote = 9%
    // index 89 represents the smallest one = 1%
    uint public deployed; uint internal K = 17;
    uint public SUM; // sum(weights[0...k]):
    mapping (address => uint) public feeVotes;
    address[][16] public voters; // by batch
    address public Moulinette; // windmill
    modifier onlyGenerators { // top G...
        address sender = msg.sender;
        require(sender == Moulinette ||
                sender == address(this), "!");
        _;
    } // en.wiktionary.org/wiki/MOulinette 
    modifier postLaunch { // of the windmill
        require(currentBatch() > 0, "after");  
        _; 
    }
    function fast_forward(uint period) external { 
        // TODO remove...only for testing on Sepolia
        if (period == 0) { blocktimestamp += 360 days; } 
        else { blocktimestamp += 1 days * period; }   
        if (period >= 43) { restart(); }
    } 
    
    constructor(address _mo) ERC20("QU!D", "QD") {
        Moulinette = _mo; deployed = block.timestamp;
        blocktimestamp = deployed;
    }
    
    function _min(uint _a, uint _b) internal 
        pure returns (uint) { return (_a < _b) ?
                                      _a : _b;
    } 
    function _minAmount(address from, address token, 
        uint amount) internal view returns (uint) {
        amount = _min(amount, IERC20(token).balanceOf(from));
        require(amount > 0, "insufficient balance"); return amount;
    }

    function qd_amt_to_dollar_amt(uint qd_amt,  // used in frontend
        uint block_timestamp) public view returns (uint amount) {
        uint in_days = ((block_timestamp - START) / 1 days); 
        amount = (in_days * PENNY + START_PRICE) * qd_amt / WAD;
    }
    function get_total_supply_cap(uint block_timestamp) 
        public view returns (uint total_supply_cap) {
        uint in_days = ( // used in frontend only...
            (block_timestamp - START) / 1 days
        ) + 1; total_supply_cap = in_days * MAX_PER_DAY; 
    }

    function vote(uint new_vote) external postLaunch {
        uint batch = currentBatch();
        if (batch < 16 && !hasVoted[msg.sender][batch]) {
            hasVoted[msg.sender][batch] = true;
            voters[batch].push(msg.sender);
        }
        uint old_vote = feeVotes[msg.sender];
        require(new_vote != old_vote &&
                new_vote < 89, "bad vote");
        feeVotes[msg.sender] = new_vote;
        uint stake = balanceOf(msg.sender);
        _calculateMedian(stake, new_vote, 
                         stake, old_vote);
    }

    function currentBatch() public view returns (uint batch) {
        batch = (blocktimestamp - deployed) / DAYS;
        // for last 8 batches to be redeemable, batch reaches 24
        require(batch < 24, "42"); 
    }
    function matureBatches() 
        public view returns (uint) {
        uint batch = currentBatch(); 
        if (batch < 8) { return 0; }
        else if (batch < 24) {
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

    function burn(address from, uint value) public
        onlyGenerators { _transferHelper(from, address(0), value); 
        MO(Moulinette).transferHelper(from, address(0), value); 
        // burn shouldn't affect carry.debit values of `from` or `to`
    }
    function transfer(address to, uint value) 
        public override(ERC20) returns (bool) {
        MO(Moulinette).transferHelper(msg.sender, 
            to, value); _transferHelper(msg.sender, 
            to, value); return true;      
    }
    function transferFrom(address from, address to, uint value) 
        public override(ERC20) returns (bool) {
        _spendAllowance(from, msg.sender, value);
        MO(Moulinette).transferHelper(from, 
            to, value); _transferHelper(from, 
            to, value); return true;
    }
    
    function getPrice() 
        public view returns (uint price) {
        AggregatorV3Interface chainlink; 
        // ETH-USD 24hr Realized Volatility
        // 0x31D04174D0e1643963b38d87f26b0675Bb7dC96e
        // ETH-USD 30-Day Realized Volatility
        // 0x8e604308BD61d975bc6aE7903747785Db7dE97e2
        // ETH-USD 7-Day Realized Volatility
        // 0xF3140662cE17fDee0A6675F9a511aDbc4f394003
        chainlink = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (, int priceAnswer,, uint timeStamp,) = chainlink.latestRoundData();
        price = uint(priceAnswer);
        require(timeStamp > 0 
            && timeStamp <= block.timestamp 
            && priceAnswer >= 0, "price");
        uint8 answerDigits = chainlink.decimals();
        // Aggregator returns an 8-digit precision, 
        // but we handle the case of future changes
        if (answerDigits > 18) { price /= 10 ** (answerDigits - 18); }
        else if (answerDigits < 18) { price *= 10 ** (18 - answerDigits); } 
    }
    function calc_avg_return() public view returns 
        (uint minted, uint avg_roi) { uint x = 0;
        uint batch = currentBatch(); 
        uint num_days = DAYS / 1 days;
        batch = (batch > 16) ? 16 : batch;
        uint total = num_days * (batch + 1);
        while (x <= batch) { uint so_far = 0; 
            for (uint y = 0; y < num_days; y++) {
                Pod memory day = Piscine[x][y]; 
                if (day.credit > 0 && day.debit > 0) {
                    avg_roi += FullMath.mulDiv(WAD, 
                    day.credit - day.debit, day.debit);  
                    so_far += day.credit;
                } else { total -= 1; }
            }   minted += so_far; x++;
        }   avg_roi /= total; 
    }

    /** https://x.com/QuidMint/status/1833820062714601782
     *  Find value of k in range(0, len(Weights)) such that 
     *  sum(Weights[0:k]) = sum(Weights[k:len(Weights)+1]) = sum(Weights) / 2
     *  If there is no such value of k, there must be a value of k 
     *  in the same range range(0, len(Weights)) such that 
     *  sum(Weights[0:k]) > sum(Weights) / 2
     */ 
    function _calculateMedian(uint new_stake, uint new_vote, 
        uint old_stake, uint old_vote) internal postLaunch { 
        // TODO emit some events to make sure this works properly
        if (old_vote != 17 && old_stake != 0) { 
            WEIGHTS[old_vote] -= old_stake;
            if (old_vote <= K) {   
                SUM -= old_stake;
            }
        }
        if (new_stake != 0) {
            if (new_vote <= K) {
                SUM += new_stake;
            }         
            WEIGHTS[new_vote] += new_stake;
        }   uint mid = totalSupply() / 2;
        if (mid != 0) {
            if (K > new_vote) {
                while (K >= 1 && (
                    (SUM - WEIGHTS[K]) >= mid
                )) { SUM -= WEIGHTS[K]; K -= 1; }
            } else { 
                while (SUM < mid) { 
                    K += 1; SUM += WEIGHTS[K];
                    // TODO emit event
                }
            } MO(Moulinette).setFee(K);
        }  else { SUM = 0; } // reset
    }

    function _transferHelper(address from, 
        address to, uint amount) internal {
        uint balance_from = balanceOf(from); 
        uint balance_to = balanceOf(to); 
        uint from_vote = feeVotes[from];
        uint to_vote = feeVotes[to];

        amount = _min(amount, balanceOf(from));
        require(amount > WAD, "insufficient QD"); 
        int i; // must be int otherwise tx reverts
        // when we go below 0 in the while loop...
        if (to == address(0)) {
            i = int(matureBatches()); 
            _burn(msg.sender, amount);
            // no _calculateMedian `to`
        } else { 
            i = int(currentBatch()); 
            _transfer(msg.sender, to, amount);
            // _calculateMedian(balance_to, to_vote, 
            //            balanceOf(to), to_vote);
        }
        // loop from newest to oldest batch
        // until requested amount fulfilled
        while (amount > 0 && i >= 0) { uint k = uint(i);    
            uint amt = consideration[msg.sender][k];
            emit TransferHelper(amt);
            if (amt > 0) { amt = _min(amount, amt);
                consideration[msg.sender][k] -= amt;
                // `to` may be address(0) but it's 
                // irrelevant, wastes a bit of gas
                consideration[to][k] += amt; 
                amount -= amt;
            }   i -= 1;
        }
        require(amount == 0, "transfer");
        // _calculateMedian(balance_from, from_vote, 
        //             balanceOf(from), from_vote);
    }

    function mint(uint amount, address pledge, 
        address token) external onlyGenerators
        returns (uint cost) { uint batch = currentBatch();
        if (token == address(this)) { _mint(pledge, amount);
            consideration[pledge][batch] += amount; // QD...
        }
        else if (blocktimestamp < START + DAYS) {
            // TODO if (token == address(this)) { parlay
            // re-use QD to buy QD at better rate

            uint in_days = ((blocktimestamp - START) / 1 days);
            require(amount >= DIME, "mint more QD");
            Pod memory total = Piscine[batch][43];
            Pod memory day = Piscine[batch][in_days]; 
            uint supply_cap = (in_days + 1) * MAX_PER_DAY; 
            require(total.credit + amount < supply_cap, "cap"); 
            // Yesterday's price is NOT today's price,
            // and when I think I'm running low, you're 
            // all I need, I wanna feel that in a chit
            uint price = in_days * PENNY + START_PRICE;
            cost = _minAmount(pledge, token, // USDe
                FullMath.mulDiv(price, amount, WAD)
            );
            // we calculate amount twice because maybe
            // _minAmount returns less than expected...
            amount = FullMath.mulDiv(WAD, cost, price); 
            consideration[pledge][batch] += amount;
            _mint(pledge, amount); // totalSupply++
            day.credit += amount; day.debit += cost;
            total.credit += amount; total.debit += cost;
            Piscine[batch][in_days] = day;
            Piscine[batch][43] = total;  
        }
    }

    address constant F8N = 0x3B3ee1931Dc30C1957379FAc9aba94D1C48a5405; 
    /** Whenever an {IERC721} `tokenId` token is transferred to this ERC20:
     * @dev Safe transfer `tokenId` token from `from` to `address(this)`, 
     * checking that recipient prevent tokens from being forever locked.
     * - `tokenId` token must exist and be owned by `from`
     * - If the caller is not `from`, it must have been allowed 
     *   to move this token by either {approve} or {setApprovalForAll}.
     * - {onERC721Received} is called after a safeTransferFrom...
     * - It must return its Solidity selector to confirm the token transfer.
     *   If any other value is returned or the interface is not implemented
     *   by the recipient, the transfer will be reverted. TODO ONLY MAINNET
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
            (uint minted, uint roi) = calc_avg_return();
            address winner = from; uint batch;
            if (START != 0) { // if not 1st ^
                batch = currentBatch() - 1;
                uint random = uint(keccak256(
                    abi.encodePacked(_seed, 
                    blockhash(block.number - 1))
                )) % voters[batch].length;
                winner = voters[batch][random];
                MO(Moulinette).setMetrics(roi, minted);
                require(blocktimestamp >= START + DAYS 
                    && batch < 17, "hit final repeat");
            } // "like a boomerang...I need a ^^^^^^
            START = blocktimestamp; // "same level...
            // same rebel that never settled..." Logic,
            // so the SEC won't let me be, they tried to 
            // shut me down on MTV...youtube.com/@QuidMint
            consideration[winner][batch] += BACKEND; // QD
            // TODO 8 lottery winners, make sure no repeats;
            // in the frontend, we do transferFrom in order
            // to receive NFT & pass in calldata for lotto
            // for (uint who = 0; who < 8, who++) { winner[who]
            //      _mint(winner, BACKEND); 
            // }
            ICollection(F8N).transferFrom(address(this), from, LAMBO); 
            // uint qd = MO(Moulinette).draw(from, GRIEVANCES); 
            // half gets re-deposited to mint more QD at .50
            // "they want their grievances aired on the assumption
            // that all right-thinking persons would be persuaded
            // that problems of the world can be solved," by true 
            // dough, Pierre, not your unsual money, version mint
        } // TODO check off by one with batch
        return this.onERC721Received.selector; 
    }

    function restart() public { // TODO remove, Sepolia only
        if (START != 0) {
            (uint minted, uint roi) = calc_avg_return();
            MO(Moulinette).setMetrics(roi, minted);
            require(blocktimestamp > START + DAYS &&
                    currentBatch() < 17, "can't restart");
        }  
        START = blocktimestamp;      
    }
}