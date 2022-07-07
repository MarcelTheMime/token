// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IPancakeRouter02.sol";
import "./IPancakePair.sol";
import "./IPancakeFactory.sol";


contract ComplexToken is Ownable, IERC20{
    uint8 _decimals;
    mapping(address => bool) public bots;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;
    string private _name;
    string private _symbol;
   
    uint256 private _rewardFee;
    uint256 private _previousRewardFee;

    uint256 private _liquidityFee;
    uint256 private _previousLiquidityFee;

    uint256 private _marketingFee;
    uint256 private _previousMarketingFee;
    bool inSwapAndLiquify;
    uint16 public sellRewardFee;
    uint16 public buyRewardFee;
    uint16 public transferRewardFee;
    uint16 public sellLiquidityFee;
    uint16 public buyLiquidityFee;
    uint16 public transferLiquidityFee;

    uint16 public sellMarketingFee;
    uint16 public buyMarketingFee;
    uint16 public transferMarketingFee;

    address public lpWallet;
    address public marketingWallet;
    bool public isMarketingFeeNativeToken;

    uint256 public maxTransactionAmount;
    uint256 public maxWalletAmount;
    uint256 public minAmountToTakeFee;

    bool public swapAndLiquifyEnabled;
    bool public transferDelayEnabled;
    bool public gasPriceLimitActivated;
    bool public tradingActive;
    bool public limitsInTrade;
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch

    uint256 private _gasPriceLimit;
    IPancakeRouter02 public mainRouter;
    address public mainPair;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isExcludedMaxTransactionAmount;
    mapping(address => bool) public automatedMarketMakerPairs;

    uint256 private _liquidityFeeTokens;
    uint256 private _marketingFeeTokens;
    event LogAddBots(address[] indexed bots);
    event LogRemoveBots(address[] indexed notbots);
    event UpdateLiquidityFee(
        uint16 sellLiquidityFee,
        uint16 buyLiquidityFee,
        uint16 transferLiquidityFee
    );
    event UpdateMarketingFee(
        uint16 sellMarketingFee,
        uint16 buyMarketingFee,
        uint16 transferMarketingFee
    );
    event UpdateRewardFee(
        uint16 sellRewardFee,
        uint16 buyRewardFee,
        uint16 transferRewardFee
    );
    event UpdateLPWallet(address lpWallet);
    event UpdateMarketingWallet(
        address marketingWallet,
        bool isMarketingFeeNativeToken
    );
    event UpdateMaxTransactionAmount(uint256 maxTransactionAmount);
    event UpdateMaxWalletAmount(uint256 maxWalletAmount);
    event UpdateMinAmountToTakeFee(uint256 minAmountToTakeFee);
    event SetAutomatedMarketMakerPair(address pair, bool value);
    event ExcludedMaxTransactionAmount(address updAds, bool isEx);
    event ExcludedFromFee(address account, bool isEx);
    event SwapAndLiquify(uint256 tokensForLiquidity, uint256 bnbForLiquidity);
    event MarketingFeeTaken(
        uint256 marketingFeeTokens,
        uint256 marketingFeeBNBSwapped
    );
    event TradingActivated();
    event Reflect(uint256 amount);

    function initialize(
        string memory __name,
        string memory __symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        address[3] memory _accounts,
        bool _isMarketingFeeNativeToken,
        uint16[9] memory _fees,
        uint256[3] memory _amountLimits
    ) private {
        _decimals = __decimals;
        _name = __name;
        
        _symbol = __symbol;
        _tTotal = _totalSupply * (10**_decimals);
        _rTotal = (MAX - (MAX % _tTotal));
        _rOwned[_msgSender()] = _rTotal;
        _gasPriceLimit = _amountLimits[2] * 1 gwei; 
        
        require(_accounts[0] != address(0), "marketing wallet can not be 0");
        require(_accounts[2] != address(0), "Router address can not be 0");
        
        require(_fees[0]+(_fees[3])+(_fees[6]) <= 300, "Error Fees");
        require(_fees[1]+(_fees[4])+(_fees[7]) <= 300, "Error Fees");
        require(_fees[2]+(_fees[5])+(_fees[8]) <= 300, "Error Fees");
        
        require(_amountLimits[0] <= _totalSupply ,"Error Amount");
        require(_amountLimits[0] > 0,"Error Amount");
        require(_amountLimits[1] <= _totalSupply,"Error Amount");
        require(_amountLimits[1] > 0,"Error Amount");
        
        marketingWallet = _accounts[0];
        lpWallet = _accounts[1];
        
        mainRouter = IPancakeRouter02(_accounts[2]);
        mainPair = IPancakeFactory(mainRouter.factory()).createPair(
            address(this),
            mainRouter.WETH()
        );
       
        isMarketingFeeNativeToken = _isMarketingFeeNativeToken;
        sellLiquidityFee = _fees[0];
        buyLiquidityFee = _fees[1];
        transferLiquidityFee = _fees[2];
        sellMarketingFee = _fees[3];
        buyMarketingFee = _fees[4];
        transferMarketingFee = _fees[5];
        sellRewardFee = _fees[6];
        buyRewardFee = _fees[7];
        transferRewardFee = _fees[8];
        maxTransactionAmount = _amountLimits[0] * (10**_decimals);
        maxWalletAmount = _amountLimits[1] * (10**_decimals);
        minAmountToTakeFee = _totalSupply * (10**_decimals)/10000;
       
        excludeFromReward(address(0xdead));
        excludeFromReward(address(this));
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[marketingWallet] = true;
        isExcludedFromFee[_msgSender()] = true;
        isExcludedFromFee[address(0xdead)] = true;
        isExcludedMaxTransactionAmount[_msgSender()] = true;
        isExcludedMaxTransactionAmount[address(this)] = true;
        isExcludedMaxTransactionAmount[address(0xdead)] = true;
        isExcludedMaxTransactionAmount[marketingWallet] = true;
        _setAutomatedMarketMakerPair(mainPair, true);
        emit Transfer(address(0), msg.sender, _tTotal);
        
    }

    constructor(string memory __name,
        string memory __symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        address[3] memory _accounts,
        bool _isMarketingFeeNativeToken,
        uint16[9] memory _fees,
        uint256[3] memory _amountLimits){
        initialize(__name,__symbol,__decimals,_totalSupply,_accounts,_isMarketingFeeNativeToken,_fees,_amountLimits);
    }
   

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tMarketing
        ) = _getValues(tAmount);     
        uint256 currentRate=_getRate();  
        _rOwned[sender] = _rOwned[sender]-rAmount;
        _rOwned[recipient] = _rOwned[recipient]+(rTransferAmount);
        if(tLiquidity>0 || tMarketing>0){
            _takeLiquidity(tLiquidity, tMarketing, currentRate, sender);
        }        
        if(tFee>0){
            _reflectFee(rFee, tFee);
            emit Reflect(tFee);
        }
        emit Transfer(sender, recipient, tTransferAmount);
        
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tMarketing
        ) = _getValues(tAmount);     
        uint256 currentRate=_getRate();      
        _rOwned[sender] = _rOwned[sender]-rAmount;
        _tOwned[recipient] = _tOwned[recipient]+tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient]+(rTransferAmount);
        if(tLiquidity>0 || tMarketing>0){
            _takeLiquidity(tLiquidity, tMarketing, currentRate, sender);
        }   
        if(tFee>0){
            _reflectFee(rFee, tFee);
            emit Reflect(tFee);
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tMarketing
        ) = _getValues(tAmount);     
        uint256 currentRate=_getRate();     
        _rOwned[sender] = _rOwned[sender]-rAmount;
        _tOwned[sender] = _tOwned[sender]-tAmount;
        _rOwned[recipient] = _rOwned[recipient]+(rTransferAmount);
        if(tLiquidity>0 || tMarketing>0){
            _takeLiquidity(tLiquidity, tMarketing, currentRate, sender);
        } 
        if(tFee>0){
            _reflectFee(rFee, tFee);
            emit Reflect(tFee);
        }
        emit Transfer(sender, recipient, tTransferAmount);

    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tMarketing
        ) = _getValues(tAmount);     
        uint256 currentRate=_getRate();     
        _rOwned[sender] = _rOwned[sender]-rAmount;
        _tOwned[sender] = _tOwned[sender]-tAmount;
        _tOwned[recipient] = _tOwned[recipient]+tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient]+(rTransferAmount);
        if(tLiquidity>0 || tMarketing>0){
            _takeLiquidity(tLiquidity, tMarketing, currentRate, sender);
        } 
        if(tFee>0){
            _reflectFee(rFee, tFee);
            emit Reflect(tFee);
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal-(rFee);
        _tFeeTotal = _tFeeTotal+(tFee);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tMarketing
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tMarketing,
            _getRate()
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity,
            tMarketing            
        );
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateRewardFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tMarketing = calculateMarketingFee(tAmount);
        uint256 tTransferAmount = tAmount-(tFee)-(tLiquidity)-(
            tMarketing
        );
        return (tTransferAmount, tFee, tLiquidity, tMarketing);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 tMarketing,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount*currentRate;
        uint256 rFee = tFee*currentRate;
        uint256 rLiquidity = tLiquidity*currentRate;
        uint256 rMarketing = tMarketing*currentRate;
        uint256 rTransferAmount = rAmount-rFee-rLiquidity-rMarketing;
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply-(_rOwned[_excluded[i]]);
            tSupply = tSupply-(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal/(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function removeAllFee() private {
        if (_rewardFee == 0 && _liquidityFee == 0 && _marketingFee == 0) return;

        _previousRewardFee = _rewardFee;
        _previousLiquidityFee = _liquidityFee;
        _previousMarketingFee = _marketingFee;

        _marketingFee = 0;
        _rewardFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _rewardFee = _previousRewardFee;
        _liquidityFee = _previousLiquidityFee;
        _marketingFee = _previousMarketingFee;
    }

    function calculateRewardFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount*(_rewardFee)/(10**3);
    }

    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount*(_liquidityFee)/(10**3);
    }

    function calculateMarketingFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount*(_marketingFee)/(10**3);
    }

    function _takeLiquidity(uint256 tLiquidity, uint256 tMarketing, uint256 currentRate, address sender) private {
        _liquidityFeeTokens = _liquidityFeeTokens+(tLiquidity);
        _marketingFeeTokens = _marketingFeeTokens+tMarketing;
        uint256 tTmp=tLiquidity+tMarketing;
        uint256 rTmp = tTmp*currentRate;
        _rOwned[address(this)] = _rOwned[address(this)]+rTmp;
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)]+tTmp;
        emit Transfer(sender, address(this), tTmp);        
    }
   
    /////////////////////////////////////////////////////////////////////////////////
    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()]-amount
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender]+(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender]-(
                subtractedValue
            )
        );
        return true;
    }

    function isExcludedFromReward(address account)
        external
        view
        returns (bool)
    {
        return _isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount/(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        require(
            _excluded.length + 1 <= 50,
            "Cannot exclude more than 50 accounts.  Include a previously excluded address."
        );
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) public onlyOwner {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {                
                uint256 prev_reflection=_rOwned[account];
                _rOwned[account] = _tOwned[account]*_getRate();
                _rTotal = _rTotal + _rOwned[account]-prev_reflection;
                _excluded[i] = _excluded[_excluded.length - 1];
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function updateLiquidityFee(
        uint16 _sellLiquidityFee,
        uint16 _buyLiquidityFee,
        uint16 _transferLiquidityFee
    ) external onlyOwner {
        require(
            _sellLiquidityFee+(sellMarketingFee)+(sellRewardFee) <= 300,
            "sell fee <= 30%"
        );
        require(
            _buyLiquidityFee+(buyMarketingFee)+(buyRewardFee) <= 300,
            "buy fee <= 30%"
        );
        require(
            _transferLiquidityFee+(transferMarketingFee)+(
                transferRewardFee
            ) <= 300,
            "transfer fee <= 30%"
        );
        sellLiquidityFee = _sellLiquidityFee;
        buyLiquidityFee = _buyLiquidityFee;
        transferLiquidityFee = _transferLiquidityFee;
        emit UpdateLiquidityFee(
            sellLiquidityFee,
            buyLiquidityFee,
            transferLiquidityFee
        );
    }

    function updateMarketingFee(
        uint16 _sellMarketingFee,
        uint16 _buyMarketingFee,
        uint16 _transferMarketingFee
    ) external onlyOwner {
        require(
            _sellMarketingFee+(sellLiquidityFee)+(sellRewardFee) <= 300,
            "sell fee <= 30%"
        );
        require(
            _buyMarketingFee+(buyLiquidityFee)+(buyRewardFee) <= 300,
            "buy fee <= 30%"
        );
        require(
            _transferMarketingFee+(transferLiquidityFee)+(
                transferRewardFee
            ) <= 300,
            "transfer fee <= 30%"
        );
        sellMarketingFee = _sellMarketingFee;
        buyMarketingFee = _buyMarketingFee;
        transferMarketingFee = _transferMarketingFee;
        emit UpdateMarketingFee(
            sellMarketingFee,
            buyMarketingFee,
            transferMarketingFee
        );
    }

    function updateRewardFee(
        uint16 _sellRewardFee,
        uint16 _buyRewardFee,
        uint16 _transferRewardFee
    ) external onlyOwner {
        require(
            _sellRewardFee+(sellLiquidityFee)+(sellMarketingFee) <= 300,
            "sell fee <= 30%"
        );
        require(
            _buyRewardFee+(buyLiquidityFee)+(buyMarketingFee) <= 300,
            "buy fee <= 30%"
        );
        require(
            _transferRewardFee+(transferLiquidityFee)+(
                transferMarketingFee
            ) <= 300,
            "transfer fee <= 30%"
        );
        sellRewardFee = _sellRewardFee;
        buyRewardFee = _buyRewardFee;
        transferRewardFee = _transferRewardFee;
        emit UpdateRewardFee(sellRewardFee, buyRewardFee, transferRewardFee);
    }

    function updateLPWallet(address _lpWallet) external onlyOwner {
        lpWallet = _lpWallet;
        emit UpdateLPWallet(lpWallet);
    }

    function updateMarketingWallet(
        address _marketingWallet,
        bool _isMarketingFeeNativeToken
    ) external onlyOwner {
        require(_marketingWallet != address(0), "marketing wallet can't be 0");
        marketingWallet = _marketingWallet;
        isMarketingFeeNativeToken = _isMarketingFeeNativeToken;
        isExcludedFromFee[_marketingWallet] = true;
        isExcludedMaxTransactionAmount[_marketingWallet] = true;
        emit UpdateMarketingWallet(marketingWallet, _isMarketingFeeNativeToken);
    }

    function updateMaxTransactionAmount(uint256 _maxTransactionAmount)
        external
        onlyOwner
    {
        require(
            _maxTransactionAmount * (10**_decimals) <= _tTotal,
            "max transaction amount <= total supply"
        );
        maxTransactionAmount = _maxTransactionAmount * (10**_decimals);
        emit UpdateMaxTransactionAmount(maxTransactionAmount);
    }

    function updateMaxWalletAmount(uint256 _maxWalletAmount)
        external
        onlyOwner
    {
        require(_maxWalletAmount * (10**_decimals) <= _tTotal, "max wallet amount <= total supply");
        maxWalletAmount = _maxWalletAmount * (10**_decimals);
        emit UpdateMaxWalletAmount(maxWalletAmount);
    }

    function updateMinAmountToTakeFee(uint256 _minAmountToTakeFee)
        external
        onlyOwner
    {
        require(_minAmountToTakeFee > 0, ">0");
        minAmountToTakeFee = _minAmountToTakeFee * (10**_decimals);
        emit UpdateMinAmountToTakeFee(minAmountToTakeFee);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        excludeFromMaxTransaction(pair, value);
        if (value) excludeFromReward(pair);
        else includeInReward(pair);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        isExcludedMaxTransactionAmount[updAds] = isEx;
        emit ExcludedMaxTransactionAmount(updAds, isEx);
    }

    function excludeFromFee(address account, bool isEx) external onlyOwner {
        isExcludedFromFee[account] = isEx;
        emit ExcludedFromFee(account, isEx);
    }
    function addBots(address[] memory _bots)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _bots.length; i++) {
            bots[_bots[i]] = true;
        }
        emit LogAddBots(_bots);
    }

    function removeBots(address[] memory _notbots)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _notbots.length; i++) {
            bots[_notbots[i]] = false;
        }
        emit LogRemoveBots(_notbots);
    }
    function enableTrading() external onlyOwner {
        require(!tradingActive, "already enabled");
        tradingActive = true;
        swapAndLiquifyEnabled = true;
        transferDelayEnabled=true;
        gasPriceLimitActivated=true;
        limitsInTrade=true;
        emit TradingActivated();
    }
    function setSwapAndLiquifyEnabled(bool _enabled)
        public
        onlyOwner
    {
        swapAndLiquifyEnabled = _enabled;
    }
    function setTransferDelayEnabled(bool _enabled)
        public
        onlyOwner
    {
        transferDelayEnabled = _enabled;
    }
    function setLimitsInTrade(bool _enabled)
        public
        onlyOwner
    {
        limitsInTrade = _enabled;
    }
    function setGasPriceLimitActivated(bool _enabled)
        public
        onlyOwner
    {
        gasPriceLimitActivated = _enabled;
    }
    function updateGasPriceLimit(uint256 gas) external onlyOwner {
        _gasPriceLimit = gas * 1 gwei;
        require(10000000<_gasPriceLimit,"gasPricelimit > 10000000");
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");     
        require(amount>0, "ERC20: No amount to transfer");     
        require(!bots[from] && !bots[to]);   
        if (!tradingActive) {
            require(
                isExcludedFromFee[from] || isExcludedFromFee[to],
                "Trading is not active yet."
            );
        }
        if (to != address(0) && to != address(0xDead) && !inSwapAndLiquify) {
            // only use to prevent sniper buys in the first blocks.
            if (gasPriceLimitActivated && automatedMarketMakerPairs[from]) {
                require(
                    tx.gasprice <= _gasPriceLimit,
                    "Gas price exceeds limit."
                );
            }
            if (transferDelayEnabled){
                require(
                    _holderLastTransferTimestamp[tx.origin] < block.number,
                    "_transfer:: Transfer Delay enabled.  Only one transfer per block allowed."
                );
                _holderLastTransferTimestamp[tx.origin] = block.number;
            }    
            
            if(limitsInTrade){
                //when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Buy transfer amount exceeds the maxTransactionAmount."
                    );
                    require(
                        amount + balanceOf(to) <= maxWalletAmount,
                        "Cannot exceed max wallet"
                    );
                }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Sell transfer amount exceeds the maxTransactionAmount."
                    );
                }
            }            
        }
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >=
            minAmountToTakeFee;

        // Take Fee
        if (
            !inSwapAndLiquify &&
            swapAndLiquifyEnabled &&
            overMinimumTokenBalance &&
            balanceOf(mainPair) > 0 &&
            automatedMarketMakerPairs[to]
        ) {
            takeFee();
        }
        removeAllFee();

        // If any account belongs to isExcludedFromFee account then remove the fee
        if (
            !inSwapAndLiquify &&
            !isExcludedFromFee[from] &&
            !isExcludedFromFee[to]
        ) {
            // Buy
            if (automatedMarketMakerPairs[from]) {
                _rewardFee = buyRewardFee;
                _liquidityFee = buyLiquidityFee;
                _marketingFee = buyMarketingFee;
            }
            // Sell
            else if (automatedMarketMakerPairs[to]) {
                _rewardFee = sellRewardFee;
                _liquidityFee = sellLiquidityFee;
                _marketingFee = sellMarketingFee;
            } else {
                _rewardFee = transferRewardFee;
                _liquidityFee = transferLiquidityFee;
                _marketingFee = transferMarketingFee;
            }
        }
        _tokenTransfer(from, to, amount);
        restoreAllFee();
    }

    function takeFee() private lockTheSwap {
        uint256 contractBalance = balanceOf(address(this));
        bool success;
        uint256 totalTokensTaken = _liquidityFeeTokens+(_marketingFeeTokens);
        if (totalTokensTaken == 0 || contractBalance < totalTokensTaken) {
            return;
        }

        // Halve the amount of liquidity tokens
        uint256 tokensForLiquidity = _liquidityFeeTokens / 2;
        uint256 initialBNBBalance = address(this).balance;
        uint256 bnbForLiquidity;
        if (isMarketingFeeNativeToken) {
            swapTokensForBNB(tokensForLiquidity+_marketingFeeTokens);
            uint256 bnbBalance = address(this).balance-(initialBNBBalance);
            uint256 bnbForMarketing = bnbBalance*_marketingFeeTokens/(
                tokensForLiquidity+_marketingFeeTokens
            );
            bnbForLiquidity = bnbBalance - bnbForMarketing;
            (success, ) = address(marketingWallet).call{value: bnbForMarketing}(
                ""
            );
            emit MarketingFeeTaken(0, bnbForMarketing);
        } else {
            swapTokensForBNB(tokensForLiquidity);
            bnbForLiquidity = address(this).balance-(initialBNBBalance);
            _transfer(address(this), marketingWallet, _marketingFeeTokens);
            emit MarketingFeeTaken(_marketingFeeTokens, 0);
        }

        if (tokensForLiquidity > 0 && bnbForLiquidity > 0) {
            addLiquidity(tokensForLiquidity, bnbForLiquidity);
            emit SwapAndLiquify(tokensForLiquidity, bnbForLiquidity);
        }

        _liquidityFeeTokens = 0;
        _marketingFeeTokens = 0;
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = mainRouter.WETH();
        _approve(address(this), address(mainRouter), tokenAmount);
        mainRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(mainRouter), tokenAmount);
        mainRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            lpWallet,
            block.timestamp
        );
    }
    receive() external payable {}
}