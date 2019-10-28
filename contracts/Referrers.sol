pragma solidity ^0.5.2;

import "./lib/openzeppelin-solidity/contracts/access/roles/OperatorRole.sol";

contract Referrers is OperatorRole {
    using Roles for Roles.Role;

    event ReferrerAdded(address indexed account);
    event ReferrerRemoved(address indexed account);

    Roles.Role private referrers;

    uint32 internal index;
    uint16 public constant limit = 10;
    mapping(uint32 => address) internal indexToAddress;
    mapping(address => uint32) internal addressToIndex;

    modifier onlyReferrer() {
        require(isReferrer(msg.sender));
        _;
    }

    function getNumberOfAddresses() public view onlyOperator() returns (uint32) {
        return index;
    }

    function addressOfIndex(uint32 _index) onlyOperator() public view returns (address) {
        return indexToAddress[_index];
    }

    function isReferrer(address _account) public view returns (bool) {
        return referrers.has(_account);
    }

    function addReferrer(address _account) public onlyOperator() {
        referrers.add(_account);
        indexToAddress[index] = _account;
        addressToIndex[_account] = index;
        index++;
        emit ReferrerAdded(_account);
    }

    function addReferrers(address[limit] memory accounts) public onlyOperator() {
        for (uint16 i=0; i<limit; i++) {
            if (accounts[i] != address(0x0)) {
                addReferrer(accounts[i]);
            }
        }
    }

    function removeReferrer(address _account) public onlyOperator() {
        referrers.remove(_account);
        indexToAddress[addressToIndex[_account]] = address(0x0);
        emit ReferrerRemoved(_account);
    }
}
