pragma solidity ^0.5.2;

import "../../openzeppelin-solidity/contracts/ownership/Withdrawable.sol";
import "../../openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../../openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "../../openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";

contract DJTBase is Withdrawable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
}
