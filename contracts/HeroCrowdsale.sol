/**
 *Submitted for verification at Etherscan.io on 2018-11-29
*/

pragma solidity >=0.4.21 <0.6.0;

import "./lib/openzeppelin-solidity/contracts/access/roles/ReferrerRole.sol";
import "./lib/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "./lib/openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";
import "./lib/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./HeroAsset.sol";

contract HeroCrowdsale is ReferrerRole, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    struct HeroSale {
        uint128 highestPrice;
        uint128 previousPrice;
        uint128 priceIncreaseTo;
        uint64  since;
        uint64  until;
        uint64  previousSaleAt;
        uint16  lowestPriceRate;
        uint16  decreaseRate;
        uint16  supplyLimit;
        uint16  suppliedCounts;
        uint8   currency;
        bool    exists;
    }

    mapping(uint16 => HeroSale) public heroTypeToHeroSales;
    mapping(uint16 => uint256[]) public heroTypeIds;
    mapping(uint16 => mapping(address => bool)) public hasAirDropHero;

    HeroAsset public heroAsset;
    uint16 constant internal SUPPLY_LIMIT_MAX = 10000;
    uint256 internal ethBackRate;

    event AddSalesEvent(
        uint16 indexed heroType,
        uint128 startPrice,
        uint256 lowestPrice,
        uint256 becomeLowestAt
    );

    event SoldHeroEvent(
        uint16 indexed heroType,
        uint256 soldPrice,
        uint64  soldAt,
        uint256 priceIncreaseTo,
        uint256 lowestPrice,
        uint256 becomeLowestAt,
        address purchasedBy,
        address indexed referrer,
        uint8   currency
    );

    constructor() public {
        ethBackRate = 20;
    }

    function setHeroAssetAddress(address _heroAssetAddress) external onlyOwner() {
        heroAsset = HeroAsset(_heroAssetAddress);
    }

    function changeEthBackRate(uint256 _newEthBackRate) external onlyOwner() {
        ethBackRate = _newEthBackRate;
    }

    function withdrawEther() external onlyOwner() {
        owner().transfer(address(this).balance);
    }

    function addSales(
        uint16 _heroType,
        uint128 _startPrice,
        uint16 _lowestPriceRate,
        uint16 _decreaseRate,
        uint64 _since,
        uint64 _until,
        uint16 _supplyLimit,
        uint8  _currency
    ) external onlyOwner() {
        require(!heroTypeToHeroSales[_heroType].exists, "this heroType is already added sales");
        require(0 <= _lowestPriceRate && _lowestPriceRate <= 100, "lowestPriceRate should be between 0 and 100");
        require(1 <= _decreaseRate && _decreaseRate <= 100, "decreaseRate should be should be between 1 and 100");
        require(_until > _since, "until should be later than since");

        HeroSale memory _herosale = HeroSale({
            highestPrice: _startPrice,
            previousPrice: _startPrice,
            priceIncreaseTo: _startPrice,
            since:_since,
            until:_until,
            previousSaleAt: _since,
            lowestPriceRate: _lowestPriceRate,
            decreaseRate: _decreaseRate,
            supplyLimit:_supplyLimit,
            suppliedCounts: 0,
            currency: _currency,
            exists: true
            });

        heroTypeToHeroSales[_heroType] = _herosale;
        heroAsset.setSupplyLimit(_heroType, _supplyLimit);

        uint256 _lowestPrice = uint256(_startPrice).mul(_lowestPriceRate).div(100);
        uint256 _becomeLowestAt = uint256(86400).mul(uint256(100).sub(_lowestPriceRate)).div(_decreaseRate).add(_since);

        emit AddSalesEvent(
            _heroType,
            _startPrice,
            _lowestPrice,
            _becomeLowestAt
        );
    }

    function purchase(uint16 _heroType, address _referrer) external whenNotPaused() nonReentrant() payable {
        // solium-disable-next-line security/no-block-members
        return purchaseImpl(_heroType, uint64(block.timestamp), _referrer);
    }

    function airDrop(uint16 _heroType, address _referrer) external whenNotPaused() {
        HeroSale storage heroSales = heroTypeToHeroSales[_heroType];
        require(airDropHero(_heroType), "currency is not 2 (airdrop)");
        require(!hasAirDropHero[_heroType][msg.sender]);
        uint64 _at = uint64(block.timestamp);
        require(isOnSale(_heroType, _at), "out of sales period");

        createHero(_heroType, msg.sender);
        hasAirDropHero[_heroType][msg.sender] = true;
        heroSales.suppliedCounts++;
        heroSales.previousSaleAt = _at;
        address referrer;
        if (_referrer == msg.sender){
            referrer = address(0x0);
        } else {
            referrer = _referrer;
        }

        emit SoldHeroEvent(
            _heroType,
            1,
            _at,
            1,
            1,
            1,
            msg.sender,
            referrer,
            2
        );
    }

    function computeCurrentPrice(uint16 _heroType) external view returns (uint8, uint256){
        // solium-disable-next-line security/no-block-members
        return computeCurrentPriceImpl(_heroType, uint64(block.timestamp));
    }

    function canBePurchasedByETH(uint16 _heroType) internal view returns (bool){
        return (heroTypeToHeroSales[_heroType].currency == 0);
    }

    function airDropHero(uint16 _heroType) internal view returns (bool){
        return (heroTypeToHeroSales[_heroType].currency == 2);
    }

    function isOnSale(uint16 _heroType, uint64 _now) internal view returns (bool){
        HeroSale storage heroSales = heroTypeToHeroSales[_heroType];
        require(heroSales.exists, "not exist sales of this heroType");

        if (heroSales.since <= _now && _now <= heroSales.until) {
            return true;
        } else {
            return false;
        }
    }

    function computeCurrentPriceImpl(uint16 _heroType, uint64 _at) internal view returns (uint8, uint256) {
        HeroSale storage heroSales = heroTypeToHeroSales[_heroType];
        require(heroSales.exists, "not exist sales of this heroType");
        require(heroSales.previousSaleAt <= _at, "current timestamp should not be faster than previousSaleAt");

        uint256 _lowestPrice = uint256(heroSales.highestPrice).mul(heroSales.lowestPriceRate).div(100);
        uint256 _secondsPassed = uint256(_at).sub(heroSales.previousSaleAt);
        uint256 _decreasedPrice = uint256(heroSales.priceIncreaseTo).mul(_secondsPassed).mul(heroSales.decreaseRate).div(100).div(86400);
        uint256 currentPrice;

        if (uint256(heroSales.priceIncreaseTo).sub(_lowestPrice) > _decreasedPrice){
            currentPrice = uint256(heroSales.priceIncreaseTo).sub(_decreasedPrice);
        } else {
            currentPrice = _lowestPrice;
        }

        return (1, currentPrice);
    }

    function purchaseImpl(uint16 _heroType, uint64 _at, address _referrer)
    internal
    {
        HeroSale storage heroSales = heroTypeToHeroSales[_heroType];
        require(canBePurchasedByETH(_heroType), "currency is not 0 (eth)");
        require(isOnSale(_heroType, _at), "out of sales period");
        (, uint256 _price) = computeCurrentPriceImpl(_heroType, _at);
        require(msg.value >= _price, "value is less than the price");

        createHero(_heroType, msg.sender);
        if (msg.value > _price){
            msg.sender.transfer(msg.value.sub(_price));
        }
        address referrer;
        if (_referrer == msg.sender){
            referrer = address(0x0);
        } else {
            referrer = _referrer;
        }
        if ((referrer != address(0x0)) && isReferrer(referrer)) {
            referrer.transfer(_price.mul(ethBackRate).div(100));
        }
        heroSales.previousPrice = uint128(_price);
        heroSales.suppliedCounts++;
        heroSales.previousSaleAt = _at;
        if (heroSales.previousPrice > heroSales.highestPrice){
            heroSales.highestPrice = heroSales.previousPrice;
        }
        uint256 _priceIncreaseTo;
        uint256 _lowestPrice;
        uint256 _becomeLowestAt;
        if (heroSales.supplyLimit > heroSales.suppliedCounts){
            _priceIncreaseTo = SafeMath.add(_price, _price.div((uint256(heroSales.supplyLimit).sub(heroSales.suppliedCounts))));
            heroSales.priceIncreaseTo = uint128(_priceIncreaseTo);
            _lowestPrice = uint256(heroSales.lowestPriceRate).mul(heroSales.highestPrice).div(100);
            _becomeLowestAt = uint256(86400).mul(100).mul((_priceIncreaseTo.sub(_lowestPrice))).div(_priceIncreaseTo).div(heroSales.decreaseRate).add(_at);
        } else {
            _priceIncreaseTo = heroSales.previousPrice;
            heroSales.priceIncreaseTo = uint128(_priceIncreaseTo);
            _lowestPrice = heroSales.previousPrice;
            _becomeLowestAt = _at;
        }
        emit SoldHeroEvent(
            _heroType,
            _price,
            _at,
            _priceIncreaseTo,
            _lowestPrice,
            _becomeLowestAt,
            msg.sender,
            referrer,
            0
        );
    }

    function createHero(uint16 _heroType, address _owner) internal {
        require(heroTypeToHeroSales[_heroType].exists, "not exist sales of this heroType");
        require(heroTypeIds[_heroType].length < heroTypeToHeroSales[_heroType].supplyLimit, "Heroes cant be created more than supplyLimit");

        uint256 _heroId = uint256(_heroType).mul(SUPPLY_LIMIT_MAX).add(heroTypeIds[_heroType].length).add(1);
        heroTypeIds[_heroType].push(_heroId);
        heroAsset.mintHeroAsset(_owner, _heroId);
    }
}
