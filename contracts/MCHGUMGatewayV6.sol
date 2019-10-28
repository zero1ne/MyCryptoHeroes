/* solhint-disable indent*/

pragma solidity ^0.5.2;

import "./lib/openzeppelin-solidity/contracts/cryptography/ECDSA.sol";
import "./lib/contract-library/contracts/DJTBase.sol";
import "./MCHLandPool.sol";
import "./Referrers.sol";

contract MCHGUMGatewayV6 is DJTBase {

    LandSectorAsset public landSectorAsset;
    MCHLandPool public landPool;
    Referrers public referrers;
    address public validater;
    bool public isInGUMUpTerm;

    uint256 public landPercentage;
    uint256 internal referralPercentage;

    mapping(uint256 => bool) private payableOption;

    // Define purchaseType
    // enum PurchaseType {
    //   PURCHASE_NORMAL = 0;
    //   PURCHASE_ETH_BACK = 1;
    //   PURCHASE_GUM_UP = 1;
    // }
    uint8 public purchaseTypeNormal = 0;
    // uint8 public purchaseTypeETHBack = 1;
    uint8 public purchaseTypeGUMUP;
    // uint8 public purchaseTypeRegular = 3;

    event LandPercentageUpdated(
        uint256 landPercentage
    );

    event Sold(
        address indexed user,
        address indexed referrer,
        uint8 purchaseType,
        uint256 grossValue,
        uint256 referralValue,
        uint256 landValue,
        uint256 netValue,
        uint256 indexed landType,
        uint256 at
    );

    event GUMUpTermUpdated(
        bool isInGUMUpTerm
    );

    event PurchaseTypeGUMUPUpdated(
        uint8 purchaseTypeGUMUP
    );

    constructor(
        address _validater,
        address _referrersAddress
    ) public {
        validater = _validater;
        referrers = Referrers(_referrersAddress);
        landPercentage = 30;
        referralPercentage = 20;
        purchaseTypeGUMUP = 2;
        payableOption[0.05 ether] = true;
        payableOption[0.1 ether] = true;
        payableOption[0.5 ether] = true;
        payableOption[1 ether] = true;
        payableOption[5 ether] = true;
        payableOption[10 ether] = true;
    }

    function setLandSectorAssetAddress(address _landSectorAssetAddress) external onlyOwner() {
        landSectorAsset = LandSectorAsset(_landSectorAssetAddress);
    }

    function setLandPoolAddress(address payable _landPoolAddress) external onlyOwner() {
        landPool = MCHLandPool(_landPoolAddress);
    }

    function setValidater(address _varidater) external onlyOwner() {
        validater = _varidater;
    }

    function updateLandPercentage(uint256 _newLandPercentage) external onlyOwner() {
        landPercentage = _newLandPercentage;
        emit LandPercentageUpdated(
            landPercentage
        );
    }

    function setReferrersContractAddress(address _referrersAddress) external onlyOwner() {
        referrers = Referrers(_referrersAddress);
    }

    function setPurchaseTypeGUMUP(uint8 _newNum) external onlyOwner() {
        require(_newNum != 0 || _newNum != 1 || _newNum != 3);
        purchaseTypeGUMUP = _newNum;
        emit PurchaseTypeGUMUPUpdated(
            purchaseTypeGUMUP
        );
    }

    function setGUMUpTerm(bool _desired) external onlyOwner() {
        isInGUMUpTerm = _desired;
        emit GUMUpTermUpdated(
            isInGUMUpTerm
        );
    }

    function updateReferralPercentage(uint256 _newReferralPercentage) external onlyOwner() {
        referralPercentage = _newReferralPercentage;
    }

    function setPayableOption(uint256 _option, bool desired) external onlyOwner() {
        payableOption[_option] = desired;
    }

    function buyGUM(uint16 _landType, address payable _referrer, bytes calldata _signature) external payable whenNotPaused() nonReentrant() {
        require(payableOption[msg.value]);
        require(validateSig(_signature, _landType), "invalid signature");

        // Refarrer check
        address payable referrer;
        if (_referrer == msg.sender) {
            referrer = address(0x0);
        } else {
            referrer = _referrer;
        }

        uint256 netValue = msg.value;
        uint256 referralValue;
        uint256 landValue;
        if ((_referrer != address(0x0)) && referrers.isReferrer(_referrer)) {
            referralValue = msg.value.mul(referralPercentage).div(100);
            netValue = netValue.sub(referralValue);
            _referrer.transfer(referralValue);
        }

        if (landSectorAsset.getTotalVolume(_landType) != 0) {
            landValue = msg.value.mul(landPercentage).div(100);
            netValue = netValue.sub(landValue);
            landPool.addEthToLandPool.value(landValue)(_landType, msg.sender);
        }

        uint8 purchaseType;
        purchaseType = purchaseTypeNormal;
        if (isInGUMUpTerm) {
            purchaseType = purchaseTypeGUMUP;
        }

        emit Sold(
            msg.sender,
            referrer,
            purchaseType,
            msg.value,
            referralValue,
            landValue,
            netValue,
            _landType,
            block.timestamp
        );
    }

    function getPayableOption(uint256 _option) public view returns (bool) {
        return payableOption[_option];
    }

    function validateSig(bytes memory _signature, uint16 _landType) private view returns (bool) {
        require(validater != address(0));
        uint256 _message = uint256(msg.sender) + uint256(_landType);
        address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(bytes32(_message)), _signature);
        return (signer == validater);
    }
}
/* solhint-enable indent*/
