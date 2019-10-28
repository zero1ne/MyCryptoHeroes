pragma solidity >=0.4.21 <0.6.0;
import "../Roles.sol";
import "./OperatorRole.sol";

contract ReferrerRole is OperatorRole {
    using Roles for Roles.Role;

    event ReferrerAdded(address indexed account);
    event ReferrerRemoved(address indexed account);

    Roles.Role private referrers;

    constructor() public {
        referrers.add(msg.sender);
    }

    modifier onlyReferrer() {
        require(isReferrer(msg.sender));
        _;
    }

    function isReferrer(address account) public view returns (bool) {
        return referrers.has(account);
    }

    function addReferrer(address account) public onlyOwner() {
        referrers.add(account);
        emit ReferrerAdded(account);
    }

    function removeReferrer(address account) public onlyOwner() {
        referrers.remove(account);
        emit ReferrerRemoved(account);
    }

}
