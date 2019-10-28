/**
 *Submitted for verification at Etherscan.io on 2018-12-25
*/

pragma solidity >=0.4.21 <0.6.0;

import "../lib/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../lib/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "../lib/openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";
import "../lib/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract MCHEMONTGateway is Ownable, Pausable, ReentrancyGuard {

    ERC20 public EMONT;

    event EMONTEXCHANGE(
        address indexed user,
        address indexed referrer,
        uint256 value,
        uint256 at
    );

    function setEMONTAddress(ERC20 _EMONTAddress) external onlyOwner() {
        EMONT = _EMONTAddress;
    }

    function withdrawEther() external onlyOwner() {
        owner().transfer(address(this).balance);
    }

    function withdrawEMONT() external onlyOwner() {
        uint256 EMONTBalance = EMONT.balanceOf(address(this));
        EMONT.approve(address(this), EMONTBalance);
        EMONT.transferFrom(address(this), msg.sender, EMONTBalance);
    }

    function exchangeEMONTtoGUM(uint256 amount, address _referrer) external whenNotPaused() nonReentrant() {
        require(amount == 2500000000 || amount == 10000000000 || amount == 50000000000);

        address referrer;
        if (_referrer == msg.sender) {
            referrer = address(0x0);
        } else {
            referrer = _referrer;
        }

        EMONT.transferFrom(msg.sender, address(this), amount);

        emit EMONTEXCHANGE(
            msg.sender,
            referrer,
            amount,
            block.timestamp
        );
    }

    function getEMONTBalance() external view returns (uint256) {
        return EMONT.balanceOf(address(this));
    }

}
