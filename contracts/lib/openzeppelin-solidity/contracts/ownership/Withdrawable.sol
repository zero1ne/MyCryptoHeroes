pragma solidity ^0.5.2;

import "./Ownable.sol";
import "../token/ERC20/IERC20.sol";

contract Withdrawable is Ownable {
    function withdrawEther() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function withdrawToken(IERC20 _token) external onlyOwner {
        require(_token.transfer(msg.sender, _token.balanceOf(address(this))));
    }
}
