/**
 *Submitted for verification at Etherscan.io on 2019-02-04
*/

pragma solidity ^0.5.2;

import "./lib/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./lib/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "./lib/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./lib/openzeppelin-solidity/contracts/cryptography/ECDSA.sol";

contract MCHDailyActionV2 is Ownable, Pausable {
    using SafeMath for uint256;

    uint256 public term;
    address public validater;
    mapping(address => mapping(address => uint256)) public counter;
    mapping(address => uint256) public latestActionTime;

    event Action(
        address indexed user,
        address indexed referrer,
        uint256 at
    );

    constructor() public {
        term = 86400 - 600;
    }

    function withdrawEther() external onlyOwner() {
        msg.sender.transfer(address(this).balance);
    }

    function setValidater(address _varidater) external onlyOwner() {
        validater = _varidater;
    }

    function updateTerm(uint256 _term) external onlyOwner() {
        term = _term;
    }

    function requestDailyActionReward(bytes calldata _signature, address _referrer) external whenNotPaused() {
        require(!isInTerm(msg.sender), "this sender got daily reward within term");
        uint256 count = getCount(msg.sender);
        require(validateSig(_signature, count), "invalid signature");
        emit Action(
            msg.sender,
            _referrer,
            block.timestamp
        );
        setCount(msg.sender, count + 1);
        latestActionTime[msg.sender] = block.timestamp;
    }

    function isInTerm(address _sender) public view returns (bool) {
        if (latestActionTime[_sender] == 0) {
            return false;
        } else if (block.timestamp >= latestActionTime[_sender].add(term)) {
            return false;
        }
        return true;
    }

    function getCount(address _sender) public view returns (uint256) {
        if (counter[validater][_sender] == 0) {
            return 1;
        }
        return counter[validater][_sender];
    }

    function setCount(address _sender, uint256 _count) private {
        counter[validater][_sender] = _count;
    }

    function validateSig(bytes memory _signature, uint256 _count) private view returns (bool) {
        require(validater != address(0));
        uint256 hash = uint256(msg.sender) * _count;
        address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(bytes32(hash)), _signature);
        return (signer == validater);
    }

    /* function getAddress(bytes32 hash, bytes memory signature) public pure returns (address) { */
    /*     return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), signature); */
    /* } */

}
