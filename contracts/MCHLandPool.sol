/* solhint-disable indent*/
pragma solidity ^0.5.4;
import "./LandSectorAsset.sol";
import "./lib/openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";
import "./lib/openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract MCHLandPool is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;


    LandSectorAsset public landSectorAsset;

    mapping(uint16 => uint256) private landTypeToTotalAmount;
    mapping(uint256 => uint256) private landSectorToWithdrawnAmount;
    mapping(address => bool) private allowedAddresses;

    event EthAddedToPool(
        uint16 indexed landType,
        address txSender,
        address indexed purchaseBy,
        uint256 value,
        uint256 at
    );

    event WithdrawEther(
        uint256 indexed landSector,
        address indexed lord,
        uint256 value,
        uint256 at
    );

    event AllowedAddressSet(
        address allowedAddress,
        bool allowedStatus
    );

    constructor(address _landSectorAssetAddress) public {
        landSectorAsset = LandSectorAsset(_landSectorAssetAddress);
    }

    function setLandSectorAssetAddress(address _landSectorAssetAddress) external onlyOwner() {
        landSectorAsset = LandSectorAsset(_landSectorAssetAddress);
    }

    function setAllowedAddress(address _address, bool desired) external onlyOwner() {
        allowedAddresses[_address] = desired;
        emit AllowedAddressSet(
            _address,
            desired
        );
    }

    function addEthToLandPool(uint16 _landType, address _purchaseBy) external payable whenNotPaused() nonReentrant() {
        require(landSectorAsset.getTotalVolume(_landType) > 0);
        require(allowedAddresses[msg.sender]);
        landTypeToTotalAmount[_landType] += msg.value;

        emit EthAddedToPool(
            _landType,
            msg.sender,
            _purchaseBy,
            msg.value,
            block.timestamp
        );
    }

    function withdrawMyAllRewards() external whenNotPaused() nonReentrant() {
        require(getWithdrawableBalance(msg.sender) > 0);

        uint256 withdrawValue;
        uint256 balance = landSectorAsset.balanceOf(msg.sender);

        for (uint256 i=balance; i > 0; i--) {
            uint256 landSector = landSectorAsset.tokenOfOwnerByIndex(msg.sender, i-1);
            uint256 tmpAmount = getLandSectorWithdrawableBalance(landSector);
            withdrawValue += tmpAmount;
            landSectorToWithdrawnAmount[landSector] += tmpAmount;

            emit WithdrawEther(
                landSector,
                msg.sender,
                tmpAmount,
                block.timestamp
            );
        }
        msg.sender.transfer(withdrawValue);
    }

    function withdrawMyReward(uint256 _landSector) external whenNotPaused() nonReentrant() {
        require(landSectorAsset.ownerOf(_landSector) == msg.sender);
        uint256 withdrawableAmount = getLandSectorWithdrawableBalance(_landSector);
        require(withdrawableAmount > 0);

        landSectorToWithdrawnAmount[_landSector] += withdrawableAmount;
        msg.sender.transfer(withdrawableAmount);

        emit WithdrawEther(
            _landSector,
            msg.sender,
            withdrawableAmount,
            block.timestamp
        );
    }

    function getAllowedAddress(address _address) public view returns (bool) {
        return allowedAddresses[_address];
    }

    function getTotalEthBackAmountPerLandType(uint16 _landType) public view returns (uint256) {
        return landTypeToTotalAmount[_landType];
    }

    function getLandSectorWithdrawnAmount(uint256 _landSector) public view returns (uint256) {
        return landSectorToWithdrawnAmount[_landSector];
    }

    function getLandSectorWithdrawableBalance(uint256 _landSector) public view returns (uint256) {
        require(landSectorAsset.isValidLandSector(_landSector));
        uint16 _landType = landSectorAsset.getLandType(_landSector);
        (uint256 shareRate, uint256 decimal) = landSectorAsset.getShareRateWithDecimal(_landSector);
        uint256 maxAmount = landTypeToTotalAmount[_landType]
        .mul(shareRate)
        .div(decimal);
        return maxAmount.sub(landSectorToWithdrawnAmount[_landSector]);
    }

    function getWithdrawableBalance(address _lordAddress) public view returns (uint256) {
        uint256 balance = landSectorAsset.balanceOf(_lordAddress);
        uint256 withdrawableAmount;

        for (uint256 i=balance; i > 0; i--) {
            uint256 landSector = landSectorAsset.tokenOfOwnerByIndex(_lordAddress, i-1);
            withdrawableAmount += getLandSectorWithdrawableBalance(landSector);
        }

        return withdrawableAmount;
    }
}
/* solhint-enable indent*/
