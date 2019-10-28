/**
 *Submitted for verification at Etherscan.io on 2018-12-10
*/

pragma solidity >=0.4.21 <0.6.0;

import "../lib/openzeppelin-solidity/contracts/access/roles/OperatorRole.sol";
import "../lib/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "./ExtensionAsset.sol";

contract ExtensionGateway is OperatorRole, Pausable {

    ExtensionAsset public extensionAsset;

    event DepositEvent(
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

    mapping (uint256 => address) public transientAssetOwner;

    function setExtensionAssetAddress(address _extensionAssetAddress) external onlyOwner {
        extensionAsset = ExtensionAsset(_extensionAssetAddress);
    }

    function withdrawExtensionWithMint(address _assetOwner, uint256 _tokenId, bytes32 _eventHash) external onlyOperator {
        if (extensionAsset.isAlreadyMinted(_tokenId)) {
            withdrawExtension(_assetOwner, _tokenId, _eventHash);
        } else {
            _mintExtension(_assetOwner, _tokenId, _eventHash);
        }
    }

    function depositExtensions(uint256[LIMIT] calldata _tokenIds) external whenNotPaused() {
        for (uint256 i=0; i < LIMIT; i++) {
            if (_tokenIds[i] != 0) {
                depositExtension(_tokenIds[i]);
            }
        }
    }

    function depositAllExtensions() external whenNotPaused() {
        uint256 balance = extensionAsset.balanceOf(msg.sender);
        for (uint256 i=balance; i > 0; i--) {
            uint256 tokenId = extensionAsset.tokenOfOwnerByIndex(msg.sender, i-1);
            depositExtension(tokenId);
        }
    }

    function setTransientAssetOwner(address _transientAssetOwner, uint256 _tokenId) public onlyOperator {
        transientAssetOwner[_tokenId] = _transientAssetOwner;
    }

    function withdrawExtension(address _assetOwner, uint256 _tokenId, bytes32 _eventHash) public onlyOperator {
        _transferExtensionAsset(address(this), _assetOwner, _tokenId);
        transientAssetOwner[_tokenId] = address(0x0);
        emit OutgoingEvent(_assetOwner, _tokenId, block.timestamp, _eventHash, 1);
    }

    function depositExtension(uint256 _tokenId) public whenNotPaused() {
        _transferExtensionAsset(msg.sender, address(this), _tokenId);
        transientAssetOwner[_tokenId] = msg.sender;
        emit DepositEvent(msg.sender, _tokenId, block.timestamp);
    }

    function mintExtension(address _transientAssetOwner, uint256 _tokenId, bytes32 _eventHash) public onlyOperator {
        _mintExtension(address(this), _tokenId, _eventHash);
        setTransientAssetOwner(_transientAssetOwner, _tokenId);
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

    function _transferExtensionAsset(address _from, address _to, uint256 _tokenId) private {
        extensionAsset.safeTransferFrom(
            _from,
            _to,
            _tokenId
        );
    }

    function _mintExtension(address _assetOwner, uint256 _tokenId, bytes32 _eventHash) private {
        extensionAsset.mintExtensionAsset(_assetOwner, _tokenId);
        emit OutgoingEvent(_assetOwner, _tokenId, block.timestamp, _eventHash, 0);
    }
}
