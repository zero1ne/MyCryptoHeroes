pragma solidity >=0.4.21 <0.6.0;
import "../Roles.sol";
import "../../ownership/Ownable.sol";

contract OperatorRole is Ownable {
    using Roles for Roles.Role;

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    Roles.Role private operators;

    constructor() public {
        operators.add(msg.sender);
    }

    modifier onlyOperator() {
        require(isOperator(msg.sender));
        _;
    }

    function isOperator(address account) public view returns (bool) {
        return operators.has(account);
    }

    function addOperator(address account) public onlyOwner() {
        operators.add(account);
        emit OperatorAdded(account);
    }

    function removeOperator(address account) public onlyOwner() {
        operators.remove(account);
        emit OperatorRemoved(account);
    }

}
