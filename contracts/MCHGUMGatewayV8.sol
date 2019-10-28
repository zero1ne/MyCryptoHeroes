/*
 ** Submitted for verification at Etherscan.io on 2019-06-19
*/

/* solhint-disable indent*/
// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : dave@akomba.com
// released under Apache 2.0 licence
// input  /Users/rmanzoku/src/github.com/doublejumptokyo/mch-land-contract/contracts/MCHGUMGatewayV8.sol
// flattened :  Wednesday, 19-Jun-19 06:54:11 UTC

pragma solidity ^0.5.0;

import "./lib/openzeppelin-solidity/contracts/cryptography/ECDSA.sol";
import "./lib/contract-library/contracts/DJTBase.sol";
import "./LandSectorAsset.sol";
import "./MCHLandPool.sol";


contract MCHGUMGatewayV8 is DJTBase {

    struct Campaign {
        uint256 since;
        uint256 until;
        uint8 purchaseType;
    }

    Campaign public campaign;

    mapping(uint256 => bool) public payableOptions;
    address public validater;

    LandSectorAsset public landSectorAsset;
    MCHLandPool public landPool;
    uint256 public landPercentage;

    event Sold(
        address indexed user,
        address indexed referrer,
        uint8 purchaseType,
        uint256 grossValue,
        uint256 referralValue,
        uint256 landValue,
        uint256 netValue,
        uint16 indexed landType
    );

    event CampaignUpdated(
        uint256 since,
        uint256 until,
        uint8 purchaseType
    );

    event LandPercentageUpdated(
        uint256 landPercentage
    );

    constructor(
        address _validater,
        address _landSectorAssetAddress,
        address _landPoolAddress
    ) public payable {
        validater = _validater;
        landSectorAsset = LandSectorAsset(_landSectorAssetAddress);
        landPool = MCHLandPool(_landPoolAddress);

        campaign = Campaign(0, 0, 0);
        landPercentage = 30;

        payableOptions[0.05 ether] = true;
        payableOptions[0.1 ether] = true;
        payableOptions[0.5 ether] = true;
        payableOptions[1 ether] = true;
        payableOptions[5 ether] = true;
        payableOptions[10 ether] = true;
    }

    function setValidater(address _varidater) external onlyOwner() {
        validater = _varidater;
    }

    function setPayableOption(uint256 _option, bool desired) external onlyOwner() {
        payableOptions[_option] = desired;
    }

    function setCampaign(uint256 _since, uint256 _until, uint8 _purchaseType) external onlyOwner() {
        campaign = Campaign(_since, _until, _purchaseType);
        emit CampaignUpdated(_since, _until, _purchaseType);
    }

    function setLandSectorAssetAddress(address _landSectorAssetAddress) external onlyOwner() {
        landSectorAsset = LandSectorAsset(_landSectorAssetAddress);
    }

    function setLandPoolAddress(address payable _landPoolAddress) external onlyOwner() {
        landPool = MCHLandPool(_landPoolAddress);
    }

    function updateLandPercentage(uint256 _newLandPercentage) external onlyOwner() {
        landPercentage = _newLandPercentage;
        emit LandPercentageUpdated(
            landPercentage
        );
    }

    function buyGUM(
        address payable _referrer,
        uint256 _referralPercentage,
        uint16 _landType,
        bytes calldata _signature
    ) external payable whenNotPaused() {

        require(_referralPercentage + landPercentage <= 100, "Invalid percentages");
        require(payableOptions[msg.value], "Invalid msg.value");
        require(validateSig(encodeData(msg.sender, _referrer, _referralPercentage, _landType), _signature), "Invalid signature");

        uint256 referralValue = _referrerBack(_referrer, _referralPercentage);
        uint256 landValue = _landPoolBack(_landType);
        uint256 netValue = msg.value.sub(referralValue).sub(landValue);

        emit Sold(
            msg.sender,
            _referrer,
            getPurchaseType(block.number),
            msg.value,
            referralValue,
            landValue,
            netValue,
            _landType
        );
    }

    function getPurchaseType(uint256 _block) public view returns (uint8) {
        // Define purchaseType
        // enum PurchaseType {
        //   PURCHASE_NORMAL = 0;
        //   PURCHASE_ETH_BACK = 1;
        // }
        if(campaign.until < _block) {
            return 0;
        }
        if(campaign.since > _block) {
            return 0;
        }
        return campaign.purchaseType;
    }

    function _landPoolBack(uint16 _landType) internal returns (uint256) {
        if(_landType == 0) {
            return 0;
        }
        require(landSectorAsset.getTotalVolume(_landType) != 0, "Invalid _landType");

        uint256 landValue;
        landValue = msg.value.mul(landPercentage).div(100);
        landPool.addEthToLandPool.value(landValue)(_landType, msg.sender);
        return landValue;
    }

    function _referrerBack(address payable _referrer, uint256 _referralPercentage) internal returns (uint256) {
        if(_referrer == address(0x0) || _referrer == msg.sender) {
            return 0;
        }

        uint256 referralValue;
        referralValue = msg.value.mul(_referralPercentage).div(100);
        _referrer.transfer(referralValue);
        return referralValue;
    }

    function encodeData(address _sender, address _referrer, uint256 _referralPercentage, uint16 _landType) public pure returns (bytes32) {
        return keccak256(abi.encode(
                _sender,
                _referrer,
                _referralPercentage,
                _landType
            )
        );
    }

    function validateSig(bytes32 _message, bytes memory _signature) public view returns (bool) {
        require(validater != address(0), "validater must be setted");
        address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(_message), _signature);
        return (signer == validater);
    }

    function kill() external onlyOwner() {
        selfdestruct(msg.sender);
    }
}
/* solhint-enable indent*/
