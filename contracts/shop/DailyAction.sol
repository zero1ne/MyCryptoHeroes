pragma solidity >=0.4.21 <0.6.0;

import "../lib/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../lib/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "../lib/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract DailyAction is Ownable, Pausable {
    using SafeMath for uint256;

    mapping(address => uint256) public latestActionTime;
    uint256 public term;

    event Action(
        address indexed user,
        address indexed referrer,
        uint256 at
    );

    event UpdateTerm(
        uint256 term
    );

    constructor() public {
        term = 86400;
    }

    function withdrawEther() external onlyOwner() {
        owner().transfer(address(this).balance);
    }

    function updateTerm(uint256 num) external onlyOwner() {
        term = num;

        emit UpdateTerm(
            term
        );
    }

    function requestDailyActionReward(address referrer) external whenNotPaused() {
        require(!isInTerm(msg.sender), "this sender got daily reward within term");

        emit Action(
            msg.sender,
            referrer,
            block.timestamp
        );

        latestActionTime[msg.sender] = block.timestamp;
    }

    function isInTerm(address sender) public view returns (bool) {
        if (latestActionTime[sender] == 0) {
            return false;
        } else if (block.timestamp >= latestActionTime[sender].add(term)) {
            return false;
        }
        return true;
    }
}
