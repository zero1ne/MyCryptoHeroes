/**
 *Submitted for verification at Etherscan.io on 2019-09-30
*/

// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : dave@akomba.com
// released under Apache 2.0 licence
// input  /Users/rmanzoku/src/github.com/doublejumptokyo/mch-dailyaction/contracts/MCHDailyActionV3.sol
// flattened :  Monday, 30-Sep-19 08:38:23 UTC

pragma solidity ^0.5.0;

import "./lib/openzeppelin-solidity/contracts/cryptography/ECDSA.sol";
import "./lib/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./lib/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

contract MCHDailyActionV3 is Ownable, Pausable {

    address public validator;
    mapping(address => int64) public lastActionDate;

    event Action(
        address indexed user,
        int64 at
    );

    constructor(address _varidator) public {
        validator = _varidator;
    }

    function setValidater(address _varidator) external onlyOwner() {
        validator = _varidator;
    }

    function requestDailyActionReward(bytes calldata _signature, int64 _time) external whenNotPaused() {
        require(validateSig(msg.sender, _time, _signature), "invalid signature");
        int64 day = _time / 86400;
        require(lastActionDate[msg.sender] < day);
        lastActionDate[msg.sender] = day;
        emit Action(
            msg.sender,
            _time
        );
    }

    function validateSig(address _from, int64 _time, bytes memory _signature) public view returns (bool) {
        require(validator != address(0));
        address signer = recover(ethSignedMessageHash(encodeData(_from, _time)), _signature);
        return (signer == validator);
    }

    function encodeData(address _from, int64 _time) public pure returns (bytes32) {
        return keccak256(abi.encode(
                _from,
                _time
            )
        );
    }

    function ethSignedMessageHash(bytes32 _data) public pure returns (bytes32) {
        return ECDSA.toEthSignedMessageHash(_data);
    }

    function recover(bytes32 _data, bytes memory _signature) public pure returns (address) {
        return ECDSA.recover(_data, _signature);
    }
}
