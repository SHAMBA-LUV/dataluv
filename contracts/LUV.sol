// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 ^0.8.0 ^0.8.1 ^0.8.23 ^0.8.24;

/*
 * ❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️ SHAMBA LUV ❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️
 * 📊 TOTAL SUPPLY: 100000000000000000.000000000000000000 SHAMBA LUV
 *                        100 Quadrillion SHAMBA LUV
 * 
 * 💰 FEE STRUCTURE (5% Total):
 *    • 3% Reflection Fee - hold ❤️ to 💰 ❤️ 
 *    • 1% Liquidity Fee - ❤️ grows
 *    • 1% Team Fee - marketing and project management
 *    • share the ❤️ fee-free wallet-to-wallet transfers
 * 
 * 🔒 MAX TRANSFER: 1% of total supply
 * 🔒 FEES can only be lowered
 * 🔒 contract owner renounces to admin
 * 
 * 💎💎💎💎💎💎💎💎💎💎💎💎💎💎💎💎 HOLD LUV EARN LUV 💎💎💎💎💎💎💎💎💎💎💎💎💎💎💎💎
 */

// OpenZeppelin imports
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Inline interfaces for Remix compatibility
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// Uniswap V3 interfaces for upgradeability
interface IUniswapV3SwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);
}

// Uniswap V2 Interface
interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

/**
 * @title ShambaLuv - Multi-Chain Reflection Token with Wallet-to-Wallet Fee Exemption
 * @dev Optimized for AggLayer deployment
 * @notice No trading pause - focuses on gas efficiency and legitimate admin functions
 * @notice Ready for Uniswap V3 expansion — not implemented by default
 * @notice IMPLEMENTED: Reflection distribution to token holders with GAS OPTIMIZATION
 * @notice Wallet-to-wallet transfers are fee-free share the LUV
 */
contract ShambaLuv is ERC20, Ownable, ReentrancyGuard {
    using Address for address payable;

    // ============ CONSTANTS ============
    uint256 private constant TOTAL_SUPPLY = 1e35; // 100 Quadrillion (100e15 * 1e18)
    uint256 private constant BASE_REFLECTION_FEE = 300;  // 3.00%
    uint256 private constant BASE_LIQUIDITY_FEE = 100;   // 1.00%
    uint256 private constant BASE_TEAM_FEE = 100;        // 1.00%
    uint256 private constant FEE_DENOMINATOR = 10000;    // precision
    uint256 private constant TOTAL_FEE_PERCENTAGE = BASE_REFLECTION_FEE + BASE_LIQUIDITY_FEE + BASE_TEAM_FEE;
    
    // Gas optimization constants
    uint256 private constant REFLECTION_BATCH_THRESHOLD = 1e30; // 1 trillion
    uint256 private constant REFLECTION_DENOMINATOR = 1e18;
    
    // Router management - unlimited approval is safe with proper threshold
    uint256 private constant MAX_THRESHOLD = TOTAL_SUPPLY / 50; // Max 2% for any threshold
    
    // Security constants
    uint256 private constant DEFAULT_SLIPPAGE = 500; // 5% default slippage (500 basis points)
    uint256 private constant MAX_SLIPPAGE = 2000; // 20% maximum slippage (2000 basis points)
    uint256 private constant MAX_TIMELOCK_DELAY = 1000 * 365 days; // Maximum 1000 years timelock
    uint256 private constant DEFAULT_TIMELOCK_DELAY = 24 hours; // Default 24 hour timelock
    
    // ============ QUICKSWAP ROUTER ADDRESSES (POLYGON) ============
    address private constant QUICKSWAP_V2_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; // QuickSwap V2 Router
    address private constant QUICKSWAP_V3_ROUTER = 0xF5B509Bb0909A69B1c207e495F687a6C0eE0989e; // QuickSwap V3 Router
    address private constant WPOL = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; // WMATIC (Polygon's WETH)
    
    // ============ STATE VARIABLES ============
    uint256 public teamSwapThreshold = 1e30; // 1 trillion tokens
    uint256 public swapThreshold = 1e30; // 1 trillion tokens for swap trigger
    uint256 public liquidityThreshold = 1e30; // 1 trillion tokens
    uint256 public maxTransferPercent = 100; // Default 1% (100 = 1%, 10000 = 100%)
    uint256 public maxTransferAmount; // Calculated from percent
    bool public maxTransferEnabled = true; // Toggle for max transfer protection on and off

    address public teamWallet;
    address public liquidityWallet; // exempt from reflection rewards
    address public adminWallet;     // exempt from max transfer to create liquidity
    address public pendingAdmin;    // separate admin duty following owner renounce
    bool public adminFinalized;     // owner sets admin one time and one time only

    // Router management - V2 default, V3 upgradeable admin duty
    IUniswapV2Router02 public router; // default router
    IUniswapV3SwapRouter public v3Router; // Optional V3 router
    address private constant WETH = WPOL; // gas optimized constant
    uint256 public lastRouterUpdateTime; // router diagnostic
    uint256 public routerUpdateCount; // show update count
    bool public useV3Router = false; // Toggle between V2 and V3

    // Swap management - trade cannot be paused
    bool public swapEnabled = true;
    bool private inSwap;

    // Wallet-to-wallet fee exemption
    /// @notice Enables or disables 0-fee transfers between EOAs (externally owned accounts)
    bool public walletToWalletFeeExempt = true;

    // Exemptions
    mapping(address => bool) public isExcludedFromFee; // all holders excluded from internal fee
    mapping(address => bool) public isExcludedFromMaxTransfer; // exclude owner
    mapping(address => bool) public isExcludedFromReflection;  // exclude liquidity

    // ============ REFLECTION VARIABLES (GAS OPTIMIZED) ============
    uint256 public reflectionThreshold = 1e30; // 1 trillion tokens
    uint256 public totalReflectionFeesCollected;    // total reflections collected
    uint256 public totalReflectionFeesDistributed;  // total reflections distributed
    uint256 public reflectionIndex; 
    mapping(address => uint256) public lastReflectionIndex;
    mapping(address => uint256) public reflectionBalance;
    
    // Gas optimization: Local total supply tracking
    uint256 private _localTotalSupply;
    
    // Public getter for local total supply
    function localTotalSupply() public view returns (uint256) {
        return _localTotalSupply;
    }
    
    // Gas optimization: Batch reflection processing
    uint256 public accumulatedReflectionFees;
    uint256 public reflectionBatchThreshold = REFLECTION_BATCH_THRESHOLD;
    
    // Security state variables
    uint256 public maxSlippage = DEFAULT_SLIPPAGE; // Current max slippage setting
    uint256 public timelockDelay = DEFAULT_TIMELOCK_DELAY; // Current timelock delay (variable)
    uint256 public routerTimelockDelay = DEFAULT_TIMELOCK_DELAY; // Router-specific timelock delay (variable)
    uint256 public lastCriticalUpdate; // Timestamp of last critical function call
    bool public timelockEnabled = false; // Toggle for timelock protection (disabled by default)
    
    // ============ TIMELOCK ============
    enum OperationState {
        Unset,
        Waiting,
        Ready,
        Done
    }
    
    mapping(bytes32 => uint256) public timelockProposals; // Timelock proposals with timestamps
    mapping(bytes32 => OperationState) public operationStates; // Operation states
    
    // ============ EVENTS ============
    event RouterUpdated(address indexed oldRouter, address indexed newRouter);
    event V3RouterUpdated(address indexed oldV3Router, address indexed newV3Router);
    event RouterVersionToggled(bool useV3);
    event ThresholdsUpdated(uint256 teamThreshold, uint256 liquidityThreshold);
    event MaxTransferUpdated(uint256 oldMax, uint256 newMax);
    event MaxTransferPercentUpdated(uint256 oldPercent, uint256 newPercent);
    event MaxTransferToggled(bool enabled);
    event WalletUpdated(string walletType, address indexed oldWallet, address indexed newWallet);
    event FeeExemptionUpdated(address indexed account, bool status);
    event MaxTransferExemptionUpdated(address indexed account, bool status);
    event ReflectionExemptionUpdated(address indexed account, bool status);
    event SwapEnabledUpdated(bool enabled);
    event EmergencyThresholdUpdate(uint256 oldThreshold, uint256 newThreshold, address indexed by);
    event AdminUpdated(address indexed previousAdmin, address indexed newAdmin);
    event AdminTransferInitiated(address indexed pendingAdmin);
    event AdminRenounced(address indexed oldAdmin, uint256 timestamp);
    event ReflectionDistributed(address indexed holder, uint256 amount);
    event ReflectionThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);
    event ReflectionBatchProcessed(uint256 totalFees, uint256 newIndex);
    event GasOptimizationStats(uint256 localTotalSupply, uint256 accumulatedFees);
    
    // wallet-to-wallet fee exemption
    /// @notice Emitted when a wallet-to-wallet (EOA) transfer occurs with 0% fees
    event WalletToWalletFeeExemptTransfer(address indexed from, address indexed to, uint256 amount);
    /// @notice Emitted when wallet-to-wallet fee exemption is toggled
    event WalletToWalletFeeExemptToggled(bool enabled);
    
    // Slippage protection events
    event SlippageUpdated(uint256 oldSlippage, uint256 newSlippage);
    event SlippageProtectionUsed(uint256 amountIn, uint256 amountOutMin, uint256 actualAmountOut, string routerType);
    event TimelockDelayUpdated(uint256 oldDelay, uint256 newDelay, address indexed by);
    event RouterTimelockDelayUpdated(uint256 oldDelay, uint256 newDelay, address indexed by);
    
    // Timelock events
    event TimelockProposed(bytes32 indexed operationId, uint256 executionTime, address indexed proposer);
    event TimelockExecuted(bytes32 indexed operationId, address indexed executor);
    event TimelockCancelled(bytes32 indexed operationId, address indexed canceller);
    event TimelockToggled(bool enabled, address indexed by);
    
    // Emergency events
    event StuckBalanceCleared(address indexed token, address indexed recipient, uint256 amount, string tokenType);
    event ETHReceived(address indexed from, uint256 amount);

    // ============ MODIFIERS ============
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminWallet, "Not admin");
        _;
    }

    /**
     * @dev Timelock modifier for critical functions
     * @dev Uses block.timestamp for time comparison (safe for timelock delays)
     */
    modifier timelockProtected(bytes32 operationId) {
        if (timelockEnabled) {
            require(timelockProposals[operationId] != 0, "Operation not proposed");
            require(block.timestamp >= timelockProposals[operationId], "Timelock not expired");
            require(operationStates[operationId] == OperationState.Waiting, "Operation not in waiting state");
            
            // Mark operation as ready for execution
            operationStates[operationId] = OperationState.Ready;
        }
        _;
        if (timelockEnabled) {
            // Mark operation as done after execution
            operationStates[operationId] = OperationState.Done;
        }
    } 

    // ============ CONSTRUCTOR ============
    /**
     * @dev Constructor for LUV token
     * @param _teamWallet Address for team fee collection
     * @param _liquidityWallet Address for liquidity fee collection
     * @param _router Router address (use QUICKSWAP_V2_ROUTER for Polygon deployment)
     * 
     * For Polygon deployment, use: QUICKSWAP_V2_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff
     * Team receives WPOL from trading activity
     */
    constructor(
        address _teamWallet,
        address _liquidityWallet,
        address _router
    ) ERC20("SHAMBA", "LUV") Ownable(msg.sender) payable {
        require(_teamWallet != address(0), "Invalid team wallet");
        require(_liquidityWallet != address(0), "Invalid liquidity wallet");
        require(_router != address(0), "Invalid router");
        
        teamWallet = _teamWallet;
        liquidityWallet = _liquidityWallet;
        router = IUniswapV2Router02(_router);
        
        // Exclude owner and liquidity wallet from fees and max transfer
        isExcludedFromFee[msg.sender] = true;
        isExcludedFromMaxTransfer[msg.sender] = true;
        isExcludedFromReflection[liquidityWallet] = true;
        
        // Initialize max transfer amount from percent
        maxTransferAmount = TOTAL_SUPPLY / maxTransferPercent;
        
        // Mint total supply to owner
        _mint(msg.sender, TOTAL_SUPPLY);
        _localTotalSupply = TOTAL_SUPPLY;
    }

    // ============ RECEIVE FUNCTION ============
    receive() external payable {
        emit ETHReceived(msg.sender, msg.value);
    }

    // ============ CORE FUNCTIONS ============
    
    /**
     * @dev Override transfer with fee logic and reflection distribution - NO TRADING PAUSE
     * @dev GAS OPTIMIZED: Uses local total supply tracking and batch reflection processing
     * @dev ENHANCED: wallet-to-wallet transfers are fee-free
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        return _transferWithFees(_msgSender(), to, amount);
    }

    /**
     * @dev Override transferFrom with fee logic and reflection distribution
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        return _transferWithFees(from, to, amount);
    }

    /**
     * @dev Internal transfer function with fee logic and reflection distribution
     * @dev This replaces the need to override _transfer which is not virtual
     */
    function _transferWithFees(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        // Skip fee logic during construction (when from is zero address)
        if (from == address(0)) {
            super._transfer(from, to, amount);
            _localTotalSupply = _localTotalSupply + amount; // Update local total supply
            return true;
        }
        
        require(to != address(0), "Transfer to zero");
        require(amount != 0, "Transfer amount must be positive");

        // Max transfer check - only when enabled
        if (maxTransferEnabled && !isExcludedFromMaxTransfer[from] && !isExcludedFromMaxTransfer[to]) {
            require(amount <= maxTransferAmount, "Transfer exceeds max limit");
        }

        // Wallet-to-wallet fee exemption logic
        bool isWalletToWallet = from.code.length == 0 && to.code.length == 0;
        if (
            isExcludedFromFee[from] ||
            isExcludedFromFee[to] ||
            (walletToWalletFeeExempt && isWalletToWallet)
        ) {
            super._transfer(from, to, amount);

            if (walletToWalletFeeExempt && isWalletToWallet) {
                emit WalletToWalletFeeExemptTransfer(from, to, amount);
            }

            return true;
        }

        // Fee logic for non-exempt transfers (buying/selling)
        uint256 totalFee = (amount * TOTAL_FEE_PERCENTAGE) / FEE_DENOMINATOR;
        uint256 reflectionFee = (amount * BASE_REFLECTION_FEE) / FEE_DENOMINATOR;
        uint256 remaining = amount - totalFee;
        
        // Fee processing - no minimum threshold required
        
        super._transfer(from, to, remaining);
        super._transfer(from, address(this), totalFee);
        
        // Gas optimization: Accumulate reflection fees for batch processing
        if (reflectionFee != 0) {
            accumulatedReflectionFees = accumulatedReflectionFees + reflectionFee;
            totalReflectionFeesCollected = totalReflectionFeesCollected + reflectionFee;
            
            // Process reflections in batches for gas efficiency
            if (accumulatedReflectionFees >= reflectionBatchThreshold) {
                _processReflectionBatch();
            }
        }

        // Auto-swap logic - always enabled when swapEnabled is true
        if (swapEnabled && !inSwap && balanceOf(address(this)) >= swapThreshold) {
            _maybeSwapBack();
        }

        return true;
    }

    /**
     * @dev Gas-optimized batch reflection processing
     * @dev Processes accumulated reflection fees in batches to reduce gas costs
     */
    function _processReflectionBatch() private {
        if (accumulatedReflectionFees == 0 || _localTotalSupply == 0) return;
        
        // Update reflection index with accumulated fees
        reflectionIndex = reflectionIndex + (accumulatedReflectionFees * REFLECTION_DENOMINATOR) / _localTotalSupply;
        
        emit ReflectionBatchProcessed(accumulatedReflectionFees, reflectionIndex);
        
        // Reset accumulated fees
        accumulatedReflectionFees = 0;
    }

    /**
     * @dev Force reflection update - can be called manually to process accumulated fees
     * @dev Useful for gas optimization when fees are below batch threshold
     */
    function forceReflectionUpdate() external {
        _processReflectionBatch();
    }

    /**
     * @dev Calculate minimum output amount based on slippage protection
     * @param amount Input amount
     * @param slippage Slippage in basis points (e.g., 500 = 5%, 2000 = 20%)
     * @return Minimum output amount
     * @notice This function ensures the contract never accepts less than (100% - slippage%) of expected output
     * @notice Example: With 5% slippage (500 basis points), minimum output = amount * 0.95
     */
    function _calculateMinimumOutput(uint256 amount, uint256 slippage) private pure returns (uint256) {
        require(slippage <= MAX_SLIPPAGE, "Slippage too high");
        return amount * (10000 - slippage) / 10000;
    }

    /**
     * @dev Set maximum slippage for swaps
     * @param _maxSlippage New slippage in basis points
     */
    function setMaxSlippage(uint256 _maxSlippage) external onlyOwner {
        require(_maxSlippage <= MAX_SLIPPAGE, "Slippage exceeds maximum");
        require(_maxSlippage != 0, "Slippage must be positive");
        
        uint256 oldSlippage = maxSlippage;
        maxSlippage = _maxSlippage;
        
        emit SlippageUpdated(oldSlippage, _maxSlippage);
    }

    /**
     * @dev Calculate and claim reflections for a holder
     * @dev GAS OPTIMIZED: Uses local total supply for calculations
     */
    function _claimReflections(address holder) private returns (uint256) {
        if (isExcludedFromReflection[holder]) {
            return 0;
        }

        // Process any pending batch first
        if (accumulatedReflectionFees != 0) {
            _processReflectionBatch();
        }

        uint256 currentReflectionIndex = reflectionIndex;
        uint256 lastIndex = lastReflectionIndex[holder];
        uint256 holderBalance = balanceOf(holder);
        
        if (holderBalance == 0 || currentReflectionIndex <= lastIndex) {
            return 0;
        }

        uint256 reflectionAmount;
        unchecked {
            uint256 delta = currentReflectionIndex - lastIndex;
            reflectionAmount = (holderBalance * delta) / REFLECTION_DENOMINATOR;
        }
        
        if (reflectionAmount != 0) {
            reflectionBalance[holder] = reflectionBalance[holder] + reflectionAmount;
            totalReflectionFeesDistributed = totalReflectionFeesDistributed + reflectionAmount;
        }
        
        lastReflectionIndex[holder] = currentReflectionIndex;
        
        return reflectionAmount;
    }

    /**
     * @dev Claim accumulated reflections for the caller
     */
    function claimReflections() external nonReentrant {
        require(!isExcludedFromReflection[msg.sender], "Exempt from reflections");
        uint256 amount = _claimReflections(msg.sender);
        require(amount != 0, "No reflections to claim");
        
        reflectionBalance[msg.sender] = 0;
        _transfer(address(this), msg.sender, amount);
        
        emit ReflectionDistributed(msg.sender, amount);
    }

    /**
     * @dev Get reflection balance for an address
     */
    function getReflectionBalance(address holder) external view returns (uint256) {
        if (isExcludedFromReflection[holder]) {
            return 0;
        }

        uint256 currentReflectionIndex = reflectionIndex;
        uint256 lastIndex = lastReflectionIndex[holder];
        uint256 holderBalance = balanceOf(holder);
        
        if (holderBalance == 0 || currentReflectionIndex <= lastIndex) {
            return reflectionBalance[holder];
        }

        uint256 reflectionAmount;
        unchecked {
            uint256 delta = currentReflectionIndex - lastIndex;
            reflectionAmount = (holderBalance * delta) / REFLECTION_DENOMINATOR;
        }
        return reflectionBalance[holder] + reflectionAmount;
    } 

    // ============ SWAP FUNCTIONS ============
    
    /**
     * @dev Swap accumulated fees for ETH and tokens
     * @dev Always enabled when swapEnabled is true
     */
    function _maybeSwapBack() private swapping {
        uint256 contractBalance = balanceOf(address(this));
        
        if (contractBalance == 0) return;
        
        // Check thresholds
        bool shouldSwapTeam = contractBalance >= teamSwapThreshold;
        bool shouldSwapLiquidity = contractBalance >= liquidityThreshold;
        
        if (!shouldSwapTeam && !shouldSwapLiquidity) return;
        
        uint256 totalFee = BASE_LIQUIDITY_FEE + BASE_TEAM_FEE;
        uint256 swapAmount = (contractBalance * totalFee) / TOTAL_FEE_PERCENTAGE;
        
        if (swapAmount == 0) return;
        
        // Perform swap
        if (useV3Router && address(v3Router) != address(0)) {
            _swapBackV3(swapAmount);
        } else {
            _swapBackV2(swapAmount);
        }
    }

    /**
     * @dev Swap using Uniswap V2 with slippage protection
     */
    function _swapBackV2(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        
        // Calculate minimum output amount based on max slippage setting
        uint256 amountOutMin = _calculateMinimumOutput(amount, maxSlippage);
        
        uint256 beforeBalance = address(this).balance;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );
        uint256 received = address(this).balance - beforeBalance;
        require(received != 0, "No ETH received from swap");
        require(received >= amountOutMin, "Slippage too high");
        
        emit SlippageProtectionUsed(amount, amountOutMin, received, "V2");
        
        uint256 ethBalance = address(this).balance;
        uint256 totalFee = BASE_LIQUIDITY_FEE + BASE_TEAM_FEE;
        
        // Distribute ETH to team and liquidity wallets
        uint256 teamShare = (ethBalance * BASE_TEAM_FEE) / totalFee;
        uint256 liquidityShare = ethBalance - teamShare;
        
        if (teamShare != 0) {
            payable(teamWallet).sendValue(teamShare);
        }
        
        if (liquidityShare != 0) {
            payable(liquidityWallet).sendValue(liquidityShare);
        }
    }

    /**
     * @dev Swap using Uniswap V3 with slippage protection
     */
    function _swapBackV3(uint256 amount) private {
        // Calculate minimum output amount based on max slippage setting
        uint256 amountOutMin = _calculateMinimumOutput(amount, maxSlippage);
        
        IUniswapV3SwapRouter.ExactInputSingleParams memory params = IUniswapV3SwapRouter.ExactInputSingleParams({
            tokenIn: address(this),
            tokenOut: WETH,
            fee: 3000, // 0.3% fee tier
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amount,
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: 0
        });
        
        uint256 amountOut = v3Router.exactInputSingle(params);
        require(amountOut >= amountOutMin, "Slippage too high");
        
        emit SlippageProtectionUsed(amount, amountOutMin, amountOut, "V3");
        
        uint256 totalFee = BASE_LIQUIDITY_FEE + BASE_TEAM_FEE;
        
        // Distribute ETH to team and liquidity wallets
        uint256 teamShare = (amountOut * BASE_TEAM_FEE) / totalFee;
        uint256 liquidityShare = amountOut - teamShare;
        
        if (teamShare != 0) {
            payable(teamWallet).sendValue(teamShare);
        }
        
        if (liquidityShare != 0) {
            payable(liquidityWallet).sendValue(liquidityShare);
        }
    }

    // ============ WALLET-TO-WALLET FEE EXEMPTION ============
    
    /**
     * @dev Toggle wallet-to-wallet fee exemption
     * @dev Owner can control wallet-to-wallet fee exemption
     */
    function setWalletToWalletFeeExempt(bool _exempt) external onlyOwner {
        walletToWalletFeeExempt = _exempt;
        emit WalletToWalletFeeExemptToggled(_exempt);
    }

    // ============ ADMIN WALLET MANAGEMENT ============
    
    function setAdmin(address newAdmin) external onlyOwner {
        require(!adminFinalized, "Admin change already finalized");
        require(newAdmin != address(0), "Zero address");
        require(newAdmin != adminWallet, "Same admin address");
    
        address oldAdmin = adminWallet;
        adminWallet = newAdmin;
        pendingAdmin = address(0); // Clear any pending admin
    
        emit AdminUpdated(oldAdmin, newAdmin);
    }

    /**
     * @dev Change admin by current admin - admin can change admin after finalization
     * @dev admin can renounce
     */
    function changeAdminByAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Zero address");
        emit AdminUpdated(adminWallet, newAdmin);
        adminWallet = newAdmin;
    }
    
    // ============ TIMELOCK MANAGEMENT ============
    
    /**
     * @dev Toggle timelock protection on/off
     * @param _enabled Whether to enable timelock protection
     * @notice Only owner can toggle timelock protection
     */
    function setTimelockEnabled(bool _enabled) external onlyOwner {
        timelockEnabled = _enabled;
        emit TimelockToggled(_enabled, msg.sender);
    }

    /**
     * @dev Propose a timelock operation
     * @param operationId Unique identifier for the operation
     * @param delay Delay in seconds before operation can be executed
     * @notice Only admin can propose timelock operations
     */
    function proposeTimelock(bytes32 operationId, uint256 delay) external onlyAdmin {
        require(timelockEnabled, "Timelock is disabled");
        require(operationId != bytes32(0), "Invalid operation ID");
        require(delay <= MAX_TIMELOCK_DELAY, "Delay too long");
        require(timelockProposals[operationId] == 0, "Operation already proposed");
        
        // Use block.timestamp + delay for execution time
        uint256 executionTime = block.timestamp + delay;
        timelockProposals[operationId] = executionTime;
        operationStates[operationId] = OperationState.Waiting;
        
        emit TimelockProposed(operationId, executionTime, msg.sender);
    }

    /**
     * @dev Cancel a timelock operation
     * @param operationId Unique identifier for the operation
     * @notice Only admin can cancel timelock operations
     */
    function cancelTimelock(bytes32 operationId) external onlyAdmin {
        require(timelockProposals[operationId] != 0, "Operation not found");
        require(operationStates[operationId] == OperationState.Waiting, "Operation not in waiting state");
        
        delete timelockProposals[operationId];
        operationStates[operationId] = OperationState.Unset;
        
        emit TimelockCancelled(operationId, msg.sender);
    }

    /**
     * @dev Get timelock status for an operation
     * @param operationId Unique identifier for the operation
     * @return proposed Whether the operation is proposed
     * @return executionTime When the operation can be executed
     * @return canExecute Whether the operation can be executed now
     * @return state Current state of the operation
     */
    function getTimelockStatus(bytes32 operationId) external view returns (
        bool proposed,
        uint256 executionTime,
        bool canExecute,
        OperationState state
    ) {
        proposed = timelockProposals[operationId] != 0;
        executionTime = timelockProposals[operationId];
        canExecute = proposed && block.timestamp >= executionTime && operationStates[operationId] == OperationState.Waiting;
        state = operationStates[operationId];
    }

    // ============ ROUTER MANAGEMENT ============
    
    /**
     * @dev Update V2 router for multi-chain deployment (e.g., AggLayer)
     * @dev Timelock protected for security - critical router changes require delay
     */
    function updateRouter(address _newRouter) external onlyAdmin timelockProtected(keccak256(abi.encodePacked("updateRouter", _newRouter))) {
        require(_newRouter != address(0), "Zero address");
        require(_newRouter != address(router), "Already set");
        
        address oldRouter = address(router);
        router = IUniswapV2Router02(_newRouter);
        
        // Revoke old approval and set new one
        _approve(address(this), oldRouter, 0);
        _approve(address(this), address(router), type(uint256).max);
        
        lastRouterUpdateTime = block.timestamp;
        routerUpdateCount = routerUpdateCount + 1;
        
        emit RouterUpdated(oldRouter, _newRouter);
    }

    /**
     * @dev Set V3 router for upgradeability
     * @dev Timelock protected for security - critical router changes require delay
     */
    function setV3Router(address _v3Router) external onlyAdmin timelockProtected(keccak256(abi.encodePacked("setV3Router", _v3Router))) {
        address oldV3Router = address(v3Router);
        v3Router = IUniswapV3SwapRouter(_v3Router);
        
        emit V3RouterUpdated(oldV3Router, _v3Router);
    }

    /**
     * @dev Convenience function to set up QuickSwap V3 router
     * @dev Use this after deployment to enable V3 functionality
     * @dev Timelock protected for security - critical router changes require delay
     */
    function setupQuickSwapV3() external onlyAdmin timelockProtected(keccak256(abi.encodePacked("setupQuickSwapV3"))) {
        v3Router = IUniswapV3SwapRouter(QUICKSWAP_V3_ROUTER);
        emit V3RouterUpdated(address(0), QUICKSWAP_V3_ROUTER);
    }

    /**
     * @dev Toggle between V2 and V3 router usage
     * @dev Timelock protected for security - critical router changes require delay
     */
    function toggleRouterVersion() external onlyAdmin timelockProtected(keccak256(abi.encodePacked("toggleRouterVersion"))) {
        require(address(v3Router) != address(0), "V3 router not set");
        useV3Router = !useV3Router;
        
        emit RouterVersionToggled(useV3Router);
    }

    /**
     * @dev Get current router configuration
     */
    function getRouterConfig() external view returns (
        address v2Router,
        address v3RouterAddress,
        bool usingV3,
        uint256 lastUpdate,
        uint256 updateCount
    ) {
        return (
            address(router),
            address(v3Router),
            useV3Router,
            lastRouterUpdateTime,
            routerUpdateCount
        );
    }

    // ============ threshold CONTROLS ============
    
    /**
     * @dev Threshold adjustment use case
     * allow increasing threshold to save gas
     */
    function emergencyIncreaseThresholds(
        uint256 _newTeamThreshold,
        uint256 _newLiquidityThreshold
    ) external onlyAdmin {
        require(_newTeamThreshold >= teamSwapThreshold, "Can only increase");
        require(_newLiquidityThreshold >= liquidityThreshold, "Can only increase");
        require(_newTeamThreshold <= MAX_THRESHOLD, "Exceeds max threshold");
        require(_newLiquidityThreshold <= MAX_THRESHOLD, "Exceeds max threshold");
        
        uint256 oldTeamThreshold = teamSwapThreshold;
        uint256 oldLiquidityThreshold = liquidityThreshold;
        
        teamSwapThreshold = _newTeamThreshold;
        liquidityThreshold = _newLiquidityThreshold;
        
        emit EmergencyThresholdUpdate(oldTeamThreshold, _newTeamThreshold, msg.sender);
        emit EmergencyThresholdUpdate(oldLiquidityThreshold, _newLiquidityThreshold, msg.sender);
    }

    // ============ OWNER FUNCTIONS ============
    
    /**
     * @dev Set thresholds for team and liquidity swaps
     */
    function setThresholds(uint256 _teamThreshold, uint256 _liquidityThreshold) external onlyOwner {
        require(_teamThreshold <= MAX_THRESHOLD, "Exceeds max threshold");
        require(_liquidityThreshold <= MAX_THRESHOLD, "Exceeds max threshold");
        
        teamSwapThreshold = _teamThreshold;
        liquidityThreshold = _liquidityThreshold;
        
        emit ThresholdsUpdated(_teamThreshold, _liquidityThreshold);
    }

    /**
     * @dev Set max transfer percent - controls the percentage of total supply for max transfer
     * @param _newPercent New percentage (100 = 1%, 10000 = 100% = no limit)
     */
    function setMaxTransferPercent(uint256 _newPercent) external onlyOwner {
        require(_newPercent >= 100, "Cannot set below 1% (100)"); // trade cannot be stopped
        require(_newPercent <= 10000, "Cannot set above 100% (10000)"); // max setting is no limit
        
        uint256 oldPercent = maxTransferPercent;
        uint256 oldAmount = maxTransferAmount;
        
        maxTransferPercent = _newPercent;
        maxTransferAmount = TOTAL_SUPPLY / maxTransferPercent;
        
        emit MaxTransferPercentUpdated(oldPercent, _newPercent);
        emit MaxTransferUpdated(oldAmount, maxTransferAmount);
    }

    /**
     * @dev Update max transfer amount - can only be increased for security
     */
    function setMaxTransferAmount(uint256 _newMax) external onlyOwner {
        require(_newMax >= maxTransferAmount, "Cannot reduce max transfer");
        require(_newMax >= TOTAL_SUPPLY / maxTransferPercent, "Cannot set below current percent limit");
        require(_newMax != 0, "Max transfer must be positive");
        
        uint256 oldMax = maxTransferAmount;
        maxTransferAmount = _newMax;
        
        emit MaxTransferUpdated(oldMax, _newMax);
    }

    /**
     * @dev Toggle max transfer protection on/off for secondary guarantee of no limit
     */
    function setMaxTransferEnabled(bool _enabled) external onlyOwner {
        maxTransferEnabled = _enabled;
        emit MaxTransferToggled(_enabled);
    }

    /**
     * @dev Update wallets with validation
     */
    function setTeamWallet(address _teamWallet) external onlyOwner {
        require(_teamWallet != address(0), "Zero address");
        
        address oldWallet = teamWallet;
        teamWallet = _teamWallet;
        
        emit WalletUpdated("team", oldWallet, _teamWallet);
    }

    function setLiquidityWallet(address _liqWallet) external onlyOwner {
        require(_liqWallet != address(0), "Zero address");
        
        address oldWallet = liquidityWallet;
        liquidityWallet = _liqWallet;
        
        emit WalletUpdated("liquidity", oldWallet, _liqWallet);
    } 

    // ============ TIMELOCK DELAY MANAGEMENT ============
    
    /**
     * @dev Set timelock delay for critical functions
     * @param _newDelay New delay in seconds (minimum 1 hour, maximum 1000 years)
     * @notice This function is NOT timelocked to allow emergency adjustments
     * @notice Owner can increase or decrease the delay within bounds
     */
    function setTimelockDelay(uint256 _newDelay) external onlyOwner {
        require(_newDelay <= MAX_TIMELOCK_DELAY, "Delay too long");
        
        uint256 oldDelay = timelockDelay;
        timelockDelay = _newDelay;
        
        emit TimelockDelayUpdated(oldDelay, _newDelay, msg.sender);
    }

    /**
     * @dev Set router-specific timelock delay for admin-controlled functions
     * @param _newDelay New delay in seconds (minimum 1 hour, maximum 1000 years)
     * @notice This function is NOT timelocked to allow emergency adjustments
     * @notice Admin can adjust router timelock delay for router update functions only
     */
    function setRouterTimelockDelay(uint256 _newDelay) external onlyAdmin {
        require(_newDelay <= MAX_TIMELOCK_DELAY, "Delay too long");
        
        uint256 oldDelay = routerTimelockDelay;
        routerTimelockDelay = _newDelay;
        
        emit RouterTimelockDelayUpdated(oldDelay, _newDelay, msg.sender);
    }

    /**
     * @dev Get timelock delay information
     * @return currentDelay Current timelock delay in seconds
     * @return maxDelay Maximum allowed delay
     * @return defaultDelay Default delay value
     * @return enabled Whether timelock protection is enabled
     */
    function getTimelockDelayInfo() external view returns (
        uint256 currentDelay,
        uint256 maxDelay,
        uint256 defaultDelay,
        bool enabled
    ) {
        return (
            timelockDelay,
            MAX_TIMELOCK_DELAY,
            DEFAULT_TIMELOCK_DELAY,
            timelockEnabled
        );
    }

    // ============ EXEMPTION MANAGEMENT ============
    
    function setFeeExemption(address account, bool status) external onlyOwner {
        isExcludedFromFee[account] = status;
        emit FeeExemptionUpdated(account, status);
    }
    
    // owner and liquidity must be max transfer exempt to create liquidity
    function setMaxTransferExemption(address account, bool status) external onlyOwner {
        isExcludedFromMaxTransfer[account] = status;
        emit MaxTransferExemptionUpdated(account, status);
    }

    // set liquidity wallet as reflection exempt
    function setReflectionExemption(address account, bool status) external onlyOwner {
        isExcludedFromReflection[account] = status;
        emit ReflectionExemptionUpdated(account, status);
    }

    // ============ VIEW FUNCTIONS ============
    
    /**
     * @dev Get current fee percentage
     */
    function getFeePercentage() external pure returns (uint256) {
        return TOTAL_FEE_PERCENTAGE;
    }

    /**
     * @dev Get router status
     */
    function getRouterStatus() external view returns (
        address routerAddress,
        uint256 lastUpdate,
        uint256 updateCount
    ) {
        return (
            address(router),
            lastRouterUpdateTime,
            routerUpdateCount
        );
    }

    /**
     * @dev Get swap status (swaps are always enabled)
     */
    function getSwapStatus() external view returns (
        bool enabled,
        uint256 teamThreshold,
        uint256 liquidityThresholdValue,
        uint256 contractBalance
    ) {
        return (
            swapEnabled, // Swaps are always enabled
            teamSwapThreshold,
            liquidityThreshold,
            balanceOf(address(this))
        );
    }

    /**
     * @dev Get reflection statistics
     */
    function getReflectionStats() external view returns (
        uint256 totalCollected,
        uint256 totalDistributed,
        uint256 currentIndex,
        uint256 threshold,
        uint256 accumulated,
        uint256 batchThreshold
    ) {
        return (
            totalReflectionFeesCollected,
            totalReflectionFeesDistributed,
            reflectionIndex,
            reflectionThreshold,
            accumulatedReflectionFees,
            reflectionBatchThreshold
        );
    }

    /**
     * @dev Get gas optimization statistics
     */
    function getGasOptimizationStats() external view returns (
        uint256 localTotalSupplyValue,
        uint256 accumulatedFees,
        uint256 batchThreshold,
        uint256 reflectionDenominator
    ) {
        return (
            localTotalSupply(),
            accumulatedReflectionFees,
            reflectionBatchThreshold,
            REFLECTION_DENOMINATOR
        );
    }

    /**
     * @dev Get wallet-to-wallet fee exemption status
     * @dev includes status check for wallet-to-wallet fee exemption
     */
    function getWalletToWalletFeeExemptStatus() external view returns (
        bool enabled,
        string memory description
    ) {
        return (
            walletToWalletFeeExempt,
            walletToWalletFeeExempt ? 
                "Wallet-to-wallet transfers are fee-free" : 
                "All transfers are subject to fees"
        );
    }

    /**
     * @dev Get current WETH address (WPOL on Polygon)
     */
    function getCurrentWETHAddress() external pure returns (address) {
        return WETH;
    }

    /**
     * @dev Get security settings
     */
    function getSecuritySettings() external view returns (
        uint256 currentSlippage,
        uint256 maxAllowedSlippage,
        uint256 currentTimelockDelay,
        uint256 lastCriticalUpdateTime,
        bool timelockEnabledStatus
    ) {
        return (
            maxSlippage,
            MAX_SLIPPAGE,
            timelockDelay,
            lastCriticalUpdate,
            timelockEnabled
        );
    }

    /**
     * @dev Get detailed slippage protection information
     * @param amount Amount to calculate minimum output for
     * @return currentSlippage Current slippage setting in basis points
     * @return slippagePercentage Current slippage as percentage
     * @return minOutput Minimum output amount for given input
     * @return maxSlippageAllowed Maximum allowed slippage in basis points
     */
    function getSlippageProtectionInfo(uint256 amount) external view returns (
        uint256 currentSlippage,
        uint256 slippagePercentage,
        uint256 minOutput,
        uint256 maxSlippageAllowed
    ) {
        uint256 minOutputAmount = _calculateMinimumOutput(amount, maxSlippage);
        return (
            maxSlippage,
            maxSlippage / 100, // Convert basis points to percentage
            minOutputAmount,
            MAX_SLIPPAGE
        );
    }

    /**
     * @dev Get timelock proposal status
     * @param operationId The operation ID to check
     * @return executionTime When the proposal can be executed
     * @return canExecute Whether the proposal can be executed now
     */
    function getTimelockProposal(bytes32 operationId) external view returns (
        uint256 executionTime,
        bool canExecute
    ) {
        executionTime = timelockProposals[operationId];
        canExecute = executionTime != 0 && block.timestamp >= executionTime;
    }

    // ============ REFLECTION THRESHOLD MANAGEMENT ============
    
    /**
     * @dev Set reflection threshold for batch processing
     */
    function setReflectionThreshold(uint256 _newThreshold) external onlyOwner {
        uint256 oldThreshold = reflectionThreshold;
        reflectionThreshold = _newThreshold;
        emit ReflectionThresholdUpdated(oldThreshold, _newThreshold);
    }

    // ============ RENOUNCE FUNCTIONS ============
    // after owner renounce admin can still update router address in case of update
    // after admin renounce contract is locked in state
    
    /**
     * @dev Owner can renounce ownership
     */
    function renounceOwnership() public virtual override onlyOwner {
        _transferOwnership(address(0)); // Owner becomes address(0)
    }

    /**
     * @dev Admin can renounce admin role
     * @dev Timelock protected for security - critical admin changes require delay
     */
    function renounceAdminRole() external onlyAdmin timelockProtected(keccak256(abi.encodePacked("renounceAdminRole"))) {
        address oldAdmin = adminWallet;
        adminWallet = address(0);
        adminFinalized = true; // Prevent future admin changes
    
        emit AdminRenounced(oldAdmin, block.timestamp);
    }

    // ============ EMERGENCY FUNCTIONS ============
    
    /**
     * @dev Clear stuck balance - rescue tokens accidentally sent to contract
     * @param _token Token address to rescue (use address(0) for ETH/MATIC)
     * @param _to Recipient address
     * @param _amount Amount to rescue
     * @notice Only admin can rescue tokens (works even after owner renounce)
     * @notice Can rescue ANY token including SHAMBA LUV tokens
     */
    function clearStuckBalance(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyAdmin {
        require(_to != address(0), "Cannot send to zero address");
        require(_amount != 0, "Amount must be greater than 0");
        
        if (_token == address(0)) {
            // Rescue ETH/MATIC
            uint256 ethBalance = address(this).balance;
            require(ethBalance >= _amount, "Insufficient ETH balance");
            
            (bool success, ) = payable(_to).call{value: _amount}("");
            require(success, "ETH transfer failed");
            
            emit StuckBalanceCleared(address(0), _to, _amount, "ETH/MATIC");
        } else {
            // Rescue ANY ERC20 token (including SHAMBA LUV)
            IERC20 token = IERC20(_token);
            uint256 tokenBalance = token.balanceOf(address(this));
            require(tokenBalance >= _amount, "Insufficient token balance");
            
            bool success = token.transfer(_to, _amount);
            require(success, "Token transfer failed");
            
            string memory tokenType = _token == address(this) ? "SHAMBA LUV" : "ERC20";
            emit StuckBalanceCleared(_token, _to, _amount, tokenType);
        }
    }
    
    /**
     * @dev Clear entire stuck balance - rescue all tokens of a specific type
     * @param _token Token address to rescue (use address(0) for ETH/MATIC)
     * @param _to Recipient address
     * @notice Only admin can rescue tokens (works even after owner renounce)
     * @notice Can rescue ANY token including SHAMBA LUV tokens
     */
    function clearEntireStuckBalance(
        address _token,
        address _to
    ) external onlyAdmin {
        require(_to != address(0), "Cannot send to zero address");
        
        if (_token == address(0)) {
            // Rescue all ETH/MATIC
            uint256 ethBalance = address(this).balance;
            require(ethBalance != 0, "No ETH balance to rescue");
            
            (bool success, ) = payable(_to).call{value: ethBalance}("");
            require(success, "ETH transfer failed");
            
            emit StuckBalanceCleared(address(0), _to, ethBalance, "ETH/MATIC (Full)");
        } else {
            // Rescue all ERC20 tokens (including SHAMBA LUV)
            IERC20 token = IERC20(_token);
            uint256 tokenBalance = token.balanceOf(address(this));
            require(tokenBalance != 0, "No token balance to rescue");
            
            bool success = token.transfer(_to, tokenBalance);
            require(success, "Token transfer failed");
            
            string memory tokenType = _token == address(this) ? "SHAMBA LUV (Full)" : "ERC20 (Full)";
            emit StuckBalanceCleared(_token, _to, tokenBalance, tokenType);
        }
    }
} 
