/**
 *Submitted for verification at Etherscan.io on 2018-11-29
*/

pragma solidity >=0.4.21 <0.6.0;

import "./lib/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./lib/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "./HeroAsset.sol";

contract HeroGateway is Ownable, Pausable {

    HeroAsset public heroAsset;

    event DepositEvent(
        address indexed locker,
        uint256 tokenId,
        uint256 at
    );

    event WithdrawEvent(
        address indexed assetOwner,
        uint256 tokenId,
        uint256 at,
        bytes32 indexed eventHash
    );

    uint public constant limit = 10;

    mapping (uint256 => address) public transientAssetOwner;

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    )
    public
    returns(bytes4) {
        return 0x150b7a02;
    }

    /* for Service */

    function setHeroAssetAddress(address _heroAssetAddress) external onlyOwner {
        heroAsset = HeroAsset(_heroAssetAddress);
    }

    function setTransientAssetOwner(address _transientAssetOwner, uint256 _tokenId) public onlyOwner {
        transientAssetOwner[_tokenId] = _transientAssetOwner;
    }

    function mintHero(address _transientAssetOwner, uint256 _tokenId) external onlyOwner {
        heroAsset.mintHeroAsset(address(this), _tokenId);
        setTransientAssetOwner(_transientAssetOwner, _tokenId);
    }

    function withdrawHeroToAssetOwnerByAdmin(address _assetOwner, uint256 _tokenId, bytes32 _eventHash) external onlyOwner {
        _transferHeroAsset(address(this), _assetOwner, _tokenId);
        transientAssetOwner[_tokenId] = address(0);
        emit WithdrawEvent(_assetOwner, _tokenId, block.timestamp, _eventHash);
    }

    /* for User */

    function depositHeroToGateway(uint256 _tokenId) public whenNotPaused() {
        _transferHeroAsset(msg.sender, address(this), _tokenId);
        transientAssetOwner[_tokenId] = msg.sender;
        emit DepositEvent(msg.sender, _tokenId, block.timestamp);
    }

    function depositHeroesToGateway(uint256[limit] calldata _tokenIds) external whenNotPaused() {
        for (uint256 i=0; i<limit; i++) {
            if (_tokenIds[i] != 0) {
                depositHeroToGateway(_tokenIds[i]);
            }
        }
    }

    function depositAllHeroesToGateway() external whenNotPaused() {
        uint256 balance = heroAsset.balanceOf(msg.sender);
        for (uint256 i=balance; i>0; i--) {
            uint256 tokenId = heroAsset.tokenOfOwnerByIndex(msg.sender, i-1);
            depositHeroToGateway(tokenId);
        }
    }

    /* Private */

    function _transferHeroAsset(address _from, address _to, uint256 _tokenId) private {
        heroAsset.safeTransferFrom(
            _from,
            _to,
            _tokenId
        );
    }
}
