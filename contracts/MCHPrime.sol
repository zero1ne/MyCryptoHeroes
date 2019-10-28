/**
 *Submitted for verification at Etherscan.io on 2019-02-04
*/

pragma solidity ^0.5.2;

import "./lib/openzeppelin-solidity/contracts/cryptography/ECDSA.sol";
import "./lib/openzeppelin-solidity/contracts/access/roles/OperatorRole.sol";
import "./lib/contract-library/contracts/DJTBase.sol";

contract MCHPrime is OperatorRole, DJTBase {


    uint128 public primeFee;
    uint256 public primeTerm;
    uint256 public allowedUpdateBuffer;
    mapping(address => uint256) public addressToExpiredAt;

    address public validater;

    event PrimeFeeUpdated(
        uint128 PrimeFeeUpdated
    );

    event PrimeTermAdded(
        address user,
        uint256 expiredAt,
        uint256 at
    );

    event PrimeTermUpdated(
        uint256 primeTerm
    );

    event AllowedUpdateBufferUpdated(
        uint256 allowedUpdateBuffer
    );

    event ExpiredAtUpdated(
        address user,
        uint256 expiredAt,
        uint256 at
    );

    constructor() public {
        primeFee = 0.1 ether;
        primeTerm = 30 days;
        allowedUpdateBuffer = 5 days;
    }

    function setValidater(address _varidater) external onlyOwner() {
        validater = _varidater;
    }

    function updatePrimeFee(uint128 _newPrimeFee) external onlyOwner() {
        primeFee = _newPrimeFee;
        emit PrimeFeeUpdated(
            primeFee
        );
    }

    function updatePrimeTerm(uint256 _newPrimeTerm) external onlyOwner() {
        primeTerm = _newPrimeTerm;
        emit PrimeTermUpdated(
            primeTerm
        );
    }

    function updateAllowedUpdateBuffer(uint256 _newAllowedUpdateBuffer) external onlyOwner() {
        allowedUpdateBuffer = _newAllowedUpdateBuffer;
        emit AllowedUpdateBufferUpdated(
            allowedUpdateBuffer
        );
    }

    function updateExpiredAt(address _user, uint256 _expiredAt) external onlyOperator() {
        addressToExpiredAt[_user] = _expiredAt;
        emit ExpiredAtUpdated(
            _user,
            _expiredAt,
            block.timestamp
        );
    }

    function buyPrimeRights(bytes calldata _signature) external whenNotPaused() payable {
        require(msg.value == primeFee, "not enough eth");
        require(canUpdateNow(msg.sender), "unable to update");
        require(validateSig(_signature, bytes32(uint256(msg.sender))), "invalid signature");

        uint256 _now = block.timestamp;
        uint256 expiredAt = addressToExpiredAt[msg.sender];
        if (expiredAt <= _now) {
            addressToExpiredAt[msg.sender] = _now.add(primeTerm);
        } else if(expiredAt <= _now.add(allowedUpdateBuffer)) {
            addressToExpiredAt[msg.sender] = expiredAt.add(primeTerm);
        }

        emit PrimeTermAdded(
            msg.sender,
            addressToExpiredAt[msg.sender],
            _now
        );
    }

    function canUpdateNow(address _user) public view returns (bool) {
        uint256 _now = block.timestamp;
        uint256 expiredAt = addressToExpiredAt[_user];
        // expired user or new user
        if (expiredAt <= _now) {
            return true;
        }
        // user who are able to extend their PrimeTerm
        if (expiredAt <= _now.add(allowedUpdateBuffer)) {
            return true;
        }
        return false;
    }

    function validateSig(bytes memory _signature, bytes32 _message) private view returns (bool) {
        require(validater != address(0));
        address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(_message), _signature);
        return (signer == validater);
    }

}
