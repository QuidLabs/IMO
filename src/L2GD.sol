
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4 <0.9.0;
import "lib/forge-std/src/console.sol"; // TODO delete logging before mainnet
import {MorphoBalancesLib} from "./imports/morpho/libraries/MorphoBalancesLib.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {AggregatorV3Interface} from "./imports/AggregatorV3Interface.sol";
import {ReentrancyGuard} from "lib/solmate/src/utils/ReentrancyGuard.sol";
import {IMorpho, MarketParams} from "./imports/morpho/IMorpho.sol";
import {ERC4626} from "lib/solmate/src/tokens/ERC4626.sol";
import {ERC6909} from "lib/solmate/src/tokens/ERC6909.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import "./imports/SortedSet.sol";

interface ISCRVOracle { 
    function pricePerShare(uint ts) 
    external view returns (uint);
} // these two Oracle contracts are only used on L2
import {IDSROracle} from "./imports/IDSROracle.sol";
import {FullMath} from "./imports/math/FullMath.sol";

import {MO} from "./Mindwill.sol"; 
contract L2Good is ERC6909, ReentrancyGuard { 
    using SafeTransferLib for ERC20;
    using SafeTransferLib for ERC4626;
    using SortedSetLib for SortedSetLib.Set;
    
    uint public ROI; uint public START;
    Pod[43][24] Piscine; // 24 batches
    
    uint constant PENNY = 1e16;
    bytes32 public immutable ID; // Morph
    
    uint constant public DAYS = 42 days;
    uint public START_PRICE = 50 * PENNY;
    
    struct Pod { uint credit; uint debit; }
    
    mapping(address => Pod) public perVault;
    mapping(address => address) public vaults;

    mapping(address => uint) public totalBalances;
    mapping(address => SortedSetLib.Set) private perBatch;
    
    mapping(uint256 id => uint256 amount) public totalSupplies;
    mapping(address account => mapping(// legacy ERC20 version
            address spender => uint256)) private _allowances;
    
    mapping (address => bool[24]) public hasVoted;
    // voted for enum as what was voted on, and
    // token-holders vote for deductibles, their
    // GD balances are applied to total weights
    // for voted % (weights are the balances)
    uint public deployed; uint internal K = 28;
    uint public SUM; uint[33] public WEIGHTS;
    mapping (address => uint) public feeVotes;
    address[][24] public voters; // by batch
    mapping (address => bool) public winners;
    
    // ^ the mapping prevents duplicates...
    address payable public Mindwill;
    address public immutable SCRVUSD;
    address public immutable CRVUSD;
    address public immutable SFRAX;
    address public immutable SUSDE;
    address public immutable SUSDS;
    address public immutable SGHO;
    address public immutable SDAI;
    address public immutable USDS;
    address public immutable DAI;
    address public immutable GHO;
    address public immutable USDC;
    address public immutable USDT;
    address public immutable USDE;
    address public immutable FRAX;
    
    IDSROracle internal DSR;
    ISCRVOracle internal CRV;
    uint constant WAD = 1e18;
    uint private _totalSupply;
    string private _name = "QU!D";
    string private _symbol = "GD";
    modifier onlyUs { // the good,
        // and the batter, Mindwill
        address sender = msg.sender;
        require(sender == Mindwill ||
                sender == address(this), "!?"); _;
    }
    constructor(address _mo,
        address _vaultUSDC, address _usdt,
        address _vaultUSDT, bytes32 _morpho,
        address _usde, address _susde, 
        address _frax, address _sfrax,
        address _sdai, address _dai,
        address _usds, address _susds,
        address _crv, address _scrv,
        address _gho, address _sgho) {
        USDC = address(MO(Mindwill).token1());
        vaults[USDC] = _vaultUSDC; USDT = _usdt;
        
        SGHO = _sgho; GHO = _gho; 
        SDAI = _sdai; DAI = _dai;
        SUSDS = _susds; USDS = _usds;
        SFRAX = _sfrax; FRAX = _frax; 
        SUSDE = _susde; USDE = _usde; 
        SCRVUSD = _scrv; CRVUSD = _crv;
        
        vaults[DAI] = SDAI;
        vaults[USDS] = SUSDS;
        vaults[USDE] = SUSDE;
        vaults[CRVUSD] = SCRVUSD;
        Mindwill = payable(_mo); deployed = START; 
        ID = _morpho; START = block.timestamp;
        ERC20(USDC).approve(_vaultUSDC, type(uint).max);
        ERC20(SUSDE).approve(MORPHO, type(uint).max); // deployed 
        ERC20(USDC).approve(MORPHO, type(uint).max); // on Base...
        DSR = IDSROracle(0x65d946e533748A998B1f0E430803e39A6388f7a1); // only Base
        CRV = ISCRVOracle(0x3d8EADb739D1Ef95dd53D718e4810721837c69c1);
        // ^ 0x3d8EADb739D1Ef95dd53D718e4810721837c69c1 // <----- Base
        //  0x3195A313F409714e1f173ca095Dba7BfBb5767F7 // <----- Arbitrum
    } 
    uint constant GRIEVANCES = 113310303333333333333333;
    uint constant CUT = 4920121799152111; // over 3yr
    uint constant KICKBACK = 666666666666666666666666;
    uint constant public MAX_PER_DAY = 777_777 * WAD;
    
    function get_total_deposits
        (bool usdc) public view
        // this is only *part* of the captalisation()
        returns (uint total) { // handle USDC first
        total += usdc ? ERC4626(vaults[USDC]).maxWithdraw(
                                 address(this)) * 1e12 : 0;
        // TODO on Arbitrum there's no Morpho vault yet...
        // total += perVault[FRAX].debit; // ARB only
        total += perVault[USDE].debit;
        total += FullMath.mulDiv(_getPrice(SUSDE),
                    perVault[SUSDE].debit, WAD);
        total += FullMath.mulDiv(_getPrice(SUSDS),
                    perVault[SUSDS].debit, WAD);
        total += perVault[USDS].debit;
        total += perVault[DAI].debit;
        total += perVault[CRVUSD].debit;
        total += FullMath.mulDiv(_getPrice(SCRVUSD),
                    perVault[SCRVUSD].debit, WAD); 
    }
    function _deposit(address from,
        address token, uint amount)
        internal returns (uint usd) {
        
        bool isDollar = false;
        if (token == SCRVUSD ||
            token == SUSDS ||  
            token == SUSDE) { isDollar = true;
            uint price = _getPrice(token); 
            amount = FullMath.min(
                ERC20(token).balanceOf(from),
                FullMath.mulDiv(amount, WAD, price)
            ); 
            usd = FullMath.mulDiv(amount, price, WAD);
            perVault[token].debit += amount;
        } 
        else if (token == DAI  || token == USDS ||
                 token == USDC || token == USDE || 
                 token == CRVUSD) { isDollar = true; 
                 usd = FullMath.min(amount, 
                        ERC20(token).allowance(
                           from, address(this)));

                        ERC20(token).transferFrom(from,
                                 address(this), usd);

                   if (token == USDC || token == USDT) {
                        address vault = vaults[token];
                        amount = ERC4626(vault).deposit(
                                       usd, address(this));
                        perVault[vault].debit += amount;
                    } 
                    else { perVault[token].debit += usd; }
        }           require(isDollar && amount > 0, "$");
    }

    function _send(address to, address token, 
        uint amount) internal returns (uint sent) {
        if (amount > 0) { sent = FullMath.min(
            amount, ERC20(token).balanceOf(
                                address(this)));
            ERC20(token).transfer(to, sent);
            perVault[token].debit -= sent;
        }
    }

    function approve(address spender, 
        uint256 value) public returns (bool) {
        require(spender != address(0), "invalid spender");
        _allowances[msg.sender][spender] = value;
        return true;
    }

    // takes $ amount input in units of 1e18...
    function withdrawUSDC(uint amount) public
        onlyUs returns (uint withdrawn) {
        if (amount > 0) { 
            address vault = vaults[USDC];
             withdrawn = FullMath.min(
                amount / 1e12, 
                ERC4626(vault).maxWithdraw(
                            address(this)));

            if (withdrawn > 0) {
                ERC4626(vault).withdraw(withdrawn, 
                    Mindwill, address(this)); 
            }
        } else { return 0; }
    } // TODO deploy Morpho 
    // vault on Arbitrum...

    function gd_amt_to_dollar_amt(uint gd_amt) public
        view returns (uint amount) { uint in_days = (
            (block.timestamp - START) / 1 days
        );  amount = FullMath.mulDiv((in_days * 
            PENNY + START_PRICE), gd_amt, WAD);
    } // get the current ^^^^ to mint() GD...
    function get_total_supply_cap()
        public view returns (uint) {
        uint batch = currentBatch();
        uint in_days = ( // used in frontend...
            (block.timestamp - START) / 1 days
        ) + 1; return in_days * MAX_PER_DAY -
                 Piscine[batch][42].credit;
    }
    
    function reachUp()
        public nonReentrant {
        if (block.timestamp > // 45d
            START + DAYS + 3 days) {
            uint keep = GRIEVANCES;
            // this.morph(QUID, keep);
            _reachUp(currentBatch(), 
                QUID, KICKBACK);
        } // 16M GD over 24... 
    } 
    function _reachUp(uint batch, 
        address to, uint cut) internal {
        batch = FullMath.min(1, batch);
        
        _mint(to, batch, cut);
        START = block.timestamp; // right now
        
        Pod memory day = Piscine[batch - 1][42]; 
        // ROI aggregates all batches' days...
        console.log("debitsky", day.debit);
        ROI += FullMath.mulDiv(WAD, day.credit - 
                         day.debit, day.debit);
        console.log("whats the issue");
        // ROI in MO is snapshot (avg. per day)
        MO(Mindwill).setMetrics(ROI / ((DAYS 
                     / 1 days) * batch)); 
    } 
    /**
     * @dev Returns the current reading of our internal clock.
     */
    function currentBatch() public view returns
        (uint batch) { batch = (block.timestamp - 
                        deployed) / DAYS;
    } 
    /**
     * @dev Returns the name of our token.
     */
    function name() public view 
        virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of our token.
     */
    function symbol() public view 
        virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Tokens usually opt for a value of 18, 
     * imitating the relationship between Ether and Wei. 
     */
    function decimals() public view 
        virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {ERC20-totalSupply}.
     */
    function totalSupply() public view
        virtual returns (uint) {
        return _totalSupply;
    }

    function _til(uint when) 
        internal view returns (uint til) {
        uint current = currentBatch();
        if (when == 0) { 
            til = current + 1;
        } else { // cannot project 
            // into the past, or...
            til = FullMath.max(when,
                        current + 1);
            // any more than 4 years 
            // "into the future...
            til = FullMath.min(when, 
                        current + 33);
        } // time keeps on slippin'"
    }

    function matureBatches(uint[] memory batches)
        public view returns (uint i) { 
        for (i = batches.length; i > 0; --i) {
            if (batches[i] <= currentBatch()) 
                break;
        }
    } 

    // TODO revise    
    function matureBatches() // 0 is 1yr...
        public view returns (uint) { // in 3
        uint batch = currentBatch(); // 1-33
        if (batch < 8) { return 0; } 
        else { return batch - 8; } 
    } 
    function matureBalanceOf(address account)
        public view returns (uint total) {
        uint batches = matureBatches();
        for (uint i = 0; i < batches; i++) 
            total += balanceOf[account][i]; 
    } // redeeming matured GD calls turn() from MO
    function turn(address from, // whose balance
        uint value) public 
        onlyUs returns (uint) {
        uint oldBalanceFrom = totalBalances[from];
        uint sent = _transferHelper(
        from, address(0), value);
        // carry.debit will be untouched here...
        return MO(Mindwill).transferHelper(from,
            address(0), sent, oldBalanceFrom);
    }

    // eventually a balance may be spread
    // over enough batches that this will
    // run out of gas, so there will be
    // no choice other than to use the 
    // more granular version of transfer
    function _transferHelper(address from, 
        address to, uint amount) 
        internal returns (uint sent) {
        // must be int or tx reverts when we go below 0 in loop
        uint[] memory batches = perBatch[from].getSortedSet();
        // if i = 0 then this will either give us one iteration,
        // or exit with index out of bounds, both make sense...
        bool toZero = to == address(0);
        bool burning = toZero || to == Mindwill;
        int i = toZero ? 
            int(matureBatches(batches)) :
            int(batches.length - 1);
            // if length is zero this
            // may cause error code 11
            // which is totally legal
        while (amount > 0 && i >= 0) { 
            uint k = batches[uint(i)];
            uint amt = balanceOf[from][k];
            if (amt > 0) { 
                amt = FullMath.min(amount, amt);
                balanceOf[from][k] -= amt;
                if (!burning) {
                    perBatch[to].insert(k);
                    balanceOf[to][k] += amt;
                } else {
                    totalSupplies[k] -= sent;
                }
                if (balanceOf[from][k] == 0) {
                    perBatch[from].remove(k);
                }
                amount -= amt; 
                sent += amt;
            }   i -= 1; 
        } 
        totalBalances[from] -= sent;
        if (burning) {
            _totalSupply -= sent;
        } else {
            totalBalances[to] += sent;
        }
    }

    /**
     * @dev A transfer which doesn't specifying the 
     * batch will proceed backwards from most recent
     * to oldest batch until the transfer amount is 
     * fulfilled entirely. Tokenholders that desire 
     * a more granular result should use the other
     * transfer function (we do not override 6909)
     */
    function _transfer(address from, address to,
        uint amount) internal returns (bool) {
        uint senderVote = feeVotes[from];
        // ^ this variable allows us to only
        // read from storage once to save gas
        
        uint oldBalanceFrom = totalBalances[from];
        uint oldBalanceTo = totalBalances[to];
        uint value = _transferHelper(
                from, to, amount);
        
        uint sent = MO(Mindwill).transferHelper(
             from, to, value, oldBalanceFrom);
        
        if (value != sent) { // this is only for
        // the situation where to == address(MO): 
        // burning debt, and in the case where we 
        // tried to burn more than was available
            value -= sent; // value is now excess
            // which is the amount we can't burn;
            // _transfeHelper displaced the entire 
            // value from various maturities, to 
            // undo this perfectly would be too much
            // work, so we just mint delta as current 
            _mint(from, currentBatch() + 2, value);
            value = sent; // mint increases supply
        } 
        _calculateMedian(oldBalanceFrom, senderVote, 
                 oldBalanceFrom - value, senderVote);
        // rebalace the median with updated stake...
        if (to != address(0)) {
            uint receiverVote = feeVotes[to];
            _calculateMedian(oldBalanceTo, receiverVote, 
                     oldBalanceTo + value, receiverVote);
        } return true;
    }

    function transfer(address to, // receiver
        uint amount) public returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    function transferFrom(address from, 
        address to, uint amount) public 
        returns (bool) {
        if (msg.sender != from 
            && !isOperator[from][msg.sender]) {
            if (to == Mindwill) {
                require(msg.sender == Mindwill, "403");
            }    
            uint256 allowed = _allowances[from][msg.sender];
            if (allowed != type(uint256).max) {
                _allowances[from][msg.sender] = allowed - amount;
            }
        } return _transfer(from, to, amount);
    }

    function vote(uint new_vote/*, caps*/) external {
        uint batch = currentBatch(); // 0-24
        if (!hasVoted[msg.sender][batch]) {
            (uint carry,) = MO(Mindwill).get_info(msg.sender);
            if (carry > GRIEVANCES / 10) { 
                hasVoted[msg.sender][batch] = true;
                voters[batch].push(msg.sender); 
            }
        } uint old_vote = feeVotes[msg.sender];
        old_vote = old_vote == 0 ? 28 : old_vote;
        require(new_vote != old_vote &&
                new_vote < 33, "bad vote");
        uint stake = totalBalances[msg.sender];
        feeVotes[msg.sender] = new_vote;
        _calculateMedian(stake, old_vote,
                         stake, new_vote);
    }
    /** https://x.com/QuidMint/status/1833820062714601782
     *  Find value of k in range(0, len(Weights)) such that
     *  sum(Weights[0:k]) = sum(Weights[k:len(Weights)+1]) = sum(Weights) / 2
     *  If there is no such value of k, there must be a value of k
     *  in the same range range(0, len(Weights)) such that
     *  sum(Weights[0:k]) > sum(Weights) / 2
     */ 
    function _calculateMedian(// for fee
        uint old_stake, uint old_vote,
        uint new_stake, uint new_vote) internal {
        if (old_vote != 28 && old_stake != 0) {
            WEIGHTS[old_vote] -= FullMath.min(
                WEIGHTS[old_vote], old_stake);
            if (old_vote <= K) { 
                SUM -= FullMath.min(SUM, old_stake); 
            }
        }   
        if (new_stake != 0) { 
            if (new_vote <= K) {
                SUM += new_stake; 
            }
            WEIGHTS[new_vote] += new_stake; 
        }
        uint mid = SUM / 2; 
        if (mid != 0) {
            if (K > new_vote) {
                while (K >= 1 && 
                    ((SUM - WEIGHTS[K]) >= mid)) { 
                        SUM -= WEIGHTS[K]; 
                        K -= 1;
                    }
            } else { 
                while (SUM < mid) { 
                    K += 1;
                    SUM += WEIGHTS[K]; 
                }
            } 
        } else { 
            K = new_vote;
            SUM = new_stake;
        } 
        MO(Mindwill).setFee(K);
    }
    function _getPrice(address token) internal 
        view returns (uint price) { // L2 only
        if (token == SUSDE) { // in absence of ERC4626 locally
            (, int answer,, uint ts,) = AggregatorV3Interface(
            0xdEd37FC1400B8022968441356f771639ad1B23aA).latestRoundData();
            // 0xdEd37FC1400B8022968441356f771639ad1B23aA // Base
            // 0x605EA726F0259a30db5b7c9ef39Df9fE78665C44 // ARB
            price = uint(answer); require(ts > 0 
                && ts <= block.timestamp, "link");
            console.log("SUSDE obtained price", price);
        } else if (token == SCRVUSD) { 
            price = CRV.pricePerShare(block.timestamp);
            console.log("SCRVUSD obtained price", price);
        } else if (token == SUSDS) {
            price = DSR.getConversionRateBinomialApprox() / 1e9;
            console.log("SUSDS obtained price", price);
        }
        require(price >= WAD, "price");
    } // function used only on Base...

    function _mint(address receiver,
        uint256 id, uint256 amount
    ) internal override {
        _totalSupply += amount;
        totalSupplies[id] += amount;
        perBatch[receiver].insert(id);

        totalBalances[receiver] += amount;
        balanceOf[receiver][id] += amount;

        emit Transfer(msg.sender,
            address(0), receiver,
            id, amount);
    }
    
    // systematic uncertainty + unsystematic = total
    // demand uncertainty. typically systematic will
    // dominate unsystematic. in my experience, the 
    // 2 tend to break according to pareto principle
    function mint(address pledge, uint amount, 
        address token, uint when) 
        public nonReentrant { 
        uint batch = _til(when);
        if (token == address(this)) {
            require(msg.sender == Mindwill, "403");
            _mint(pledge, batch, amount);
        }   else if (block.timestamp <= START + DAYS) { 
                uint in_days = ((block.timestamp - START) / 1 days);
                require(amount >= WAD * 10 && (in_days + 1)
                    * MAX_PER_DAY >= Piscine[batch][42].credit 
                    + amount, "cap"); uint price = in_days * 
                                        PENNY + START_PRICE;  
                uint cost = FullMath.mulDiv( // to mint GD
                        price, amount, WAD); _deposit(
                                pledge, token, cost);
                _mint(pledge, 
                batch, amount);
                
                MO(Mindwill).mint(pledge, cost, amount);
                Piscine[batch][in_days].credit += amount;
                Piscine[batch][in_days].debit += cost;
                // 43rd row is the total for the batch
                Piscine[batch][42].credit += amount;
                Piscine[batch][42].debit += cost; 
            }
        } 
        address public constant QUID = 0x42cc020Ef5e9681364ABB5aba26F39626F1874A4;
      address public constant MORPHO = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
      // Arbitrum: 0x6c247b1F6182318877311737BaC0844bAa518F5e
      // Polygon: 0x1bF0c2541F820E775182832f06c0B7Fc27A25f67
    function morph(address to, uint amount) 
        public onlyUs returns (uint sent) {
        bool l2 = MO(Mindwill).token1isWETH();
        uint total = get_total_deposits(false);
        // this total function accounts for both
        // perVault.debit and perVault.credit as
        // part of what makes up capitalisation,
        // but...credit cannot be withdrawn, so
        // we have to count twice; second time
        // being in the 1st for loop of morph() 
        // in order to get amounts debit-able
        if (msg.sender == address(this)) {    
            // get batch which just ended
            uint batch = currentBatch() - 1;
            uint raised = Piscine[batch][42].debit;
            uint cut = FullMath.mulDiv(raised, CUT, WAD); 
            amount = FullMath.min(amount, cut);
            Piscine[batch][42].debit -= amount;
        } require(amount > 0, "no thing");
        uint inDollars; address vault; uint i; // for loop
        uint[7] memory amounts; address[7] memory tokens; 
        uint sharesWithdrawn; address repay = l2 ? vaults[USDC] : SDAI; 
        MarketParams memory params = IMorpho(MORPHO).idToMarketParams(ID);
        (uint delta, uint cap) = MO(Mindwill).capitalisation(0, false);
        uint borrowed = MorphoBalancesLib.expectedBorrowAssets(
                        // on L2 this is USDC, on L1 it's DAI...
                        IMorpho(MORPHO), params, address(this));  
            tokens = [DAI, USDS, USDE, CRVUSD, FRAX, USDT, GHO]; 
        uint collat; // hardcoded ^^ to one, but it can be changed... 
        // because the following for loop is compatible with any token,
        // or even multiple, to pledge as collateral in morpho market
        
        amounts[4] = perVault[USDT].debit; 
        amounts[0] = perVault[DAI].debit; // no SDAI on Base
        // amounts[5] = perVault[FRAX].debit; // TODO Arbitrum
        // there is no GHO on Base, and no Morpho vault of USDT
        for (i = 1; i < 4; i++) { vault = vaults[tokens[i]];
            // can have combinations of (e.g.) USDS & SUSDS
            amounts[i] = perVault[tokens[i]].debit +
                FullMath.mulDiv(_getPrice(vault),
                    perVault[vault].debit, WAD); 
        } 
        inDollars = FullMath.mulDiv(_getPrice(SUSDE), 
                        perVault[SUSDE].debit, WAD);

        collat = FullMath.min(delta + delta / 9, inDollars);
        collat = FullMath.mulDiv(WAD, collat, _getPrice(SUSDE));
        
        if (collat > 0 && delta > 0 && inDollars > delta) {
            IMorpho(MORPHO).supplyCollateral(
            params, collat, address(this), "");
            perVault[SUSDE].credit += collat; 
            perVault[SUSDE].debit -= collat;
            (borrowed,) = IMorpho(MORPHO).borrow(params, collat, 0,
                                    address(this), address(this));

            perVault[repay].credit += ERC4626(repay).deposit( 
                                     borrowed, address(this));
        } 
        else if (borrowed > 0 && cap == 100) { 
            delta = delta > perVault[repay].credit ? 
                            perVault[repay].credit : delta;

            delta = FullMath.min(borrowed, delta);
            (sharesWithdrawn,) = IMorpho(MORPHO).repay(params, 
                ERC4626(repay).withdraw(delta, address(this), 
                address(this)), 0, address(this), "");

            perVault[repay].credit -= sharesWithdrawn;
            inDollars = ERC4626(repay).convertToAssets(
                                        sharesWithdrawn);
           
            collat = FullMath.min(collat, FullMath.mulDiv(
                         WAD, inDollars, _getPrice(SUSDE)));
            
            IMorpho(MORPHO).withdrawCollateral(params, 
                collat, address(this), address(this));
                    
            perVault[SUSDE].credit -= collat;
            perVault[SUSDE].debit += collat;
        } 
        else if (borrowed == 0 && perVault[SUSDE].credit > 0) {
            IMorpho(MORPHO).withdrawCollateral(params, 
            perVault[SUSDE].credit, address(this), address(this));
            perVault[SUSDE].debit += perVault[SUSDE].credit;
            perVault[SUSDE].credit = 0;
        }       
        for (i = 1; i < 4; i++) { 
            // first we try to exhaust the unstaked versions, as
            // they are not yield-bearing (preferrable to keep)
            amounts[i] = FullMath.mulDiv(amount, FullMath.mulDiv(
                                            WAD, amounts[i], total), WAD);
            
            inDollars = FullMath.min(amounts[i],
                    ERC20(tokens[i]).balanceOf(
                                  address(this)));
            
            ERC20(tokens[i]).transfer(to, inDollars);
            sent += inDollars; amounts[i] -= inDollars;
            perVault[tokens[i]].debit -= inDollars;
            
            if (amounts[i] > 0) {
                // get the shares tokens
                vault = vaults[tokens[i]];
                // inDollars is not really
                // ^^^^^^^^^ but in shares:
                inDollars = FullMath.min(
                    ERC20(vault).balanceOf(
                        address(this)), FullMath.mulDiv(
                                        amounts[i], WAD, 
                                        _getPrice(vault)));
                
                perVault[vault].debit -= inDollars;
                ERC20(vault).transfer(to, inDollars);
                sent += FullMath.mulDiv(inDollars,
                            _getPrice(vault), WAD);
            }   
        } 
        sent += _send(to, tokens[4], FullMath.mulDiv( // USDT
                                amount, FullMath.mulDiv(WAD, 
                                    amounts[4], total), WAD));
                                    // TODO precision 6 digits

        sent += _send(to, tokens[0], FullMath.mulDiv( // DAI
                                amount, FullMath.mulDiv(WAD, 
                                    amounts[0], total), WAD));
                                        
        /* TODO only for Arbitrum, there is no FRAX on Base
            sent += _send(to, tokens[5], FullMath.mulDiv(
                        amount, FullMath.mulDiv(WAD, 
                            amounts[5], total), WAD));
        */
        // require(sent == amount, "morph");
        // this would be a nice invariant, but
        // in the case where we have borrowed
        // funds from Morpho, it won't pass
    }
}

