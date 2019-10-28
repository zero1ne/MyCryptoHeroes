/**
 *Submitted for verification at Etherscan.io on 2018-12-10
*/

pragma solidity >=0.4.21 <0.6.0;

import "../lib/openzeppelin-solidity/contracts/access/roles/ReferrerRole.sol";
import "../lib/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../shop/DailyAction.sol";

contract GumGateway is ReferrerRole, Pausable, DailyAction {
    using SafeMath for uint256;

    uint256 internal ethBackRate;
    uint256 public minimumAmount;

    event Sold(
        address indexed user,
        address indexed referrer,
        uint256 value,
        uint256 at
    );

    constructor() public {
        minimumAmount = 10000000000000000;
    }

    function updateEthBackRate(uint256 _newEthBackRate) external onlyOwner() {
        ethBackRate = _newEthBackRate;
    }

    function updateMinimumAmount(uint256 _newMinimumAmount) external onlyOwner() {
        minimumAmount = _newMinimumAmount;
    }

    function getEthBackRate() external onlyOwner() view returns (uint256) {
        return ethBackRate;
    }

    function withdrawEther() external onlyOwner() {
        owner().transfer(address(this).balance);
    }

    function buy(address _referrer) external payable whenNotPaused() {
        require(msg.value >= minimumAmount, "msg.value should be more than minimum ether amount");

        address referrer;
        if (_referrer == msg.sender){
            referrer = address(0x0);
        } else {
            referrer = _referrer;
        }
        if ((referrer != address(0x0)) && isReferrer(referrer)) {
            referrer.transfer(msg.value.mul(ethBackRate).div(100));
        }
        emit Sold(
            msg.sender,
            referrer,
            msg.value,
            block.timestamp
        );
    }

}
