/**
 *Submitted for verification at Etherscan.io on 2019-03-01
*/

pragma solidity ^0.5.4;

import "./lib/openzeppelin-solidity/contracts/access/roles/OperatorRole.sol";
import "./lib/contract-library/contracts/DJTBase.sol";
import "./HeroAsset.sol";

contract HeroGatewayV2 is OperatorRole, DJTBase {

    HeroAsset public heroAsset;

    event InComingEvent(
        address indexed locker,
        uint256 tokenId,
        uint256 at
    );

    event OutgoingEvent(
        address indexed assetOwner,
        uint256 tokenId,
        uint256 at,
        bytes32 indexed eventHash,
        uint8 eventType
    );

    uint public constant LIMIT = 10;

    mapping(bytes32 => bool) private isPastEvent;

    function transferAllTokensOfGateway(address _newAddress) external onlyOwner {
        uint256 balance = heroAsset.balanceOf(address(this));

        for (uint256 i=balance; i > 0; i--) {
            uint256 tokenId = heroAsset.tokenOfOwnerByIndex(address(this), i-1);
            _transferHeroAsset(address(this), _newAddress, tokenId);
        }
    }

    function setPastEventHash(bytes32 _eventHash, bool _desired) external onlyOperator {
        isPastEvent[_eventHash] = _desired;
    }

    function setHeroAssetAddress(address _heroAssetAddress) external onlyOwner {
        heroAsset = HeroAsset(_heroAssetAddress);
    }

    function depositHero(uint256 _tokenId) public whenNotPaused() {
        _transferHeroAsset(msg.sender, address(this), _tokenId);
        emit InComingEvent(msg.sender, _tokenId, block.timestamp);
    }

    function withdrawHeroToAssetOwnerByAdmin(address _assetOwner, uint256 _tokenId, bytes32 _eventHash) external onlyOperator {
        require(!checkIsPastEvent(_eventHash));
        _withdrawHero(_assetOwner, _tokenId, _eventHash);
        isPastEvent[_eventHash] = true;
    }

    function mintHero(address _assetOwner, uint256 _tokenId, bytes32 _eventHash) external onlyOperator {
        require(!checkIsPastEvent(_eventHash));
        _mintHero(_assetOwner, _tokenId, _eventHash);
        isPastEvent[_eventHash] = true;
    }

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

    function checkIsPastEvent(bytes32 _eventHash) public view returns (bool) {
        return isPastEvent[_eventHash];
    }

    function _transferHeroAsset(address _from, address _to, uint256 _tokenId) private {
        heroAsset.safeTransferFrom(
            _from,
            _to,
            _tokenId
        );
    }

    function _withdrawHero(address _assetOwner, uint256 _tokenId, bytes32 _eventHash) private {
        _transferHeroAsset(address(this), _assetOwner, _tokenId);
        emit OutgoingEvent(_assetOwner, _tokenId, block.timestamp, _eventHash, 1);
    }

    function _mintHero(address _assetOwner, uint256 _tokenId, bytes32 _eventHash) private {
        heroAsset.mintHeroAsset(_assetOwner, _tokenId);
        emit OutgoingEvent(_assetOwner, _tokenId, block.timestamp, _eventHash, 0);
    }
}
