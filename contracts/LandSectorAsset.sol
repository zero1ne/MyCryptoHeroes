/**
 *Submitted for verification at Etherscan.io on 2019-02-28
*/

pragma solidity ^0.5.0;

import "./lib/openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import "./lib/openzeppelin-solidity/contracts/token/ERC721/ERC721Mintable.sol";
import "./lib/openzeppelin-solidity/contracts/token/ERC721/ERC721Pausable.sol";

contract LandSectorAsset is ERC721Full, ERC721Mintable, ERC721Pausable {


    uint256 public constant SHARE_RATE_DECIMAL = 10**18;

    uint16 public constant LEGENDARY_RARITY = 5;
    uint16 public constant EPIC_RARITY = 4;
    uint16 public constant RARE_RARITY = 3;
    uint16 public constant UNCOMMON_RARITY = 2;
    uint16 public constant COMMON_RARITY = 1;

    uint16 public constant NO_LAND = 0;

    string public tokenURIPrefix = "https://www.mycryptoheroes.net/metadata/land/";

    mapping(uint16 => uint256) private landTypeToTotalVolume;
    mapping(uint16 => uint256) private landTypeToSectorSupplyLimit;
    mapping(uint16 => mapping(uint16 => uint256)) private landTypeAndRarityToSectorSupply;
    mapping(uint16 => uint256[]) private landTypeToLandSectorList;
    mapping(uint16 => uint256) private landTypeToLandSectorIndex;
    mapping(uint16 => mapping(uint16 => uint256)) private landTypeAndRarityToLandSectorCount;
    mapping(uint16 => uint256) private rarityToSectorVolume;

    mapping(uint256 => bool) private allowed;

    event MintEvent(
        address indexed assetOwner,
        uint256 tokenId,
        uint256 at,
        bytes32 indexed eventHash
    );

    constructor() public ERC721Full("MyCryptoHeroes:Land", "MCHL") {
        rarityToSectorVolume[5] = 100;
        rarityToSectorVolume[4] = 20;
        rarityToSectorVolume[3] = 5;
        rarityToSectorVolume[2] = 2;
        rarityToSectorVolume[1] = 1;
        landTypeToTotalVolume[NO_LAND] = 0;
    }

    function setSupplyAndSector(
        uint16 _landType,
        uint256 _totalVolume,
        uint256 _sectorSupplyLimit,
        uint256 legendarySupply,
        uint256 epicSupply,
        uint256 rareSupply,
        uint256 uncommonSupply,
        uint256 commonSupply
    ) external onlyMinter {
        require(_landType != 0, "landType 0 is noland");
        require(_totalVolume != 0, "totalVolume must not be 0");
        require(getMintedSectorCount(_landType) == 0, "This LandType already exists");
        require(
            legendarySupply.mul(rarityToSectorVolume[LEGENDARY_RARITY])
            .add(epicSupply.mul(rarityToSectorVolume[EPIC_RARITY]))
            .add(rareSupply.mul(rarityToSectorVolume[RARE_RARITY]))
            .add(uncommonSupply.mul(rarityToSectorVolume[UNCOMMON_RARITY]))
            .add(commonSupply.mul(rarityToSectorVolume[COMMON_RARITY]))
            == _totalVolume
        );
        require(
            legendarySupply
            .add(epicSupply)
            .add(rareSupply)
            .add(uncommonSupply)
            .add(commonSupply)
            == _sectorSupplyLimit
        );
        landTypeToTotalVolume[_landType] = _totalVolume;
        landTypeToSectorSupplyLimit[_landType] = _sectorSupplyLimit;
        landTypeAndRarityToSectorSupply[_landType][LEGENDARY_RARITY] = legendarySupply;
        landTypeAndRarityToSectorSupply[_landType][EPIC_RARITY] = epicSupply;
        landTypeAndRarityToSectorSupply[_landType][RARE_RARITY] = rareSupply;
        landTypeAndRarityToSectorSupply[_landType][UNCOMMON_RARITY] = uncommonSupply;
        landTypeAndRarityToSectorSupply[_landType][COMMON_RARITY] = commonSupply;
    }

    function approve(address _to, uint256 _tokenId) public {
        require(allowed[_tokenId]);
        super.approve(_to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(allowed[_tokenId]);
        super.transferFrom(_from, _to, _tokenId);
    }

    function unLockToken(uint256 _tokenId) public onlyMinter {
        allowed[_tokenId] = true;
    }

    function setTokenURIPrefix(string calldata _tokenURIPrefix) external onlyMinter {
        tokenURIPrefix = _tokenURIPrefix;
    }

    function isAlreadyMinted(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function isValidLandSector(uint256 _tokenId) public view returns (bool) {
        uint16 rarity = getRarity(_tokenId);
        if (!(rarityToSectorVolume[rarity] > 0)) {
            return false;
        }
        uint16 landType = getLandType(_tokenId);
        if (!(landTypeToTotalVolume[landType] > 0)) {
            return false;
        }
        uint256 serial = _tokenId % 10000;
        if (serial == 0) {
            return false;
        }
        if (serial > landTypeAndRarityToSectorSupply[landType][rarity]) {
            return false;
        }
        return true;
    }

    function canTransfer(uint256 _tokenId) public view returns (bool) {
        return allowed[_tokenId];
    }

    function getTotalVolume(uint16 _landType) public view returns (uint256) {
        return landTypeToTotalVolume[_landType];
    }

    function getSectorSupplyLimit(uint16 _landType) public view returns (uint256) {
        return landTypeToSectorSupplyLimit[_landType];
    }

    function getLandType(uint256 _landSector) public view returns (uint16) {
        uint16 _landType = uint16((_landSector.div(10000)) % 1000);
        return _landType;
    }

    function getRarity(uint256 _landSector) public view returns (uint16) {
        return uint16(_landSector.div(10**7));
    }

    function getMintedSectorCount(uint16 _landType) public view returns (uint256) {
        return landTypeToLandSectorIndex[_landType];
    }

    function getMintedSectorCountByRarity(uint16 _landType, uint16 _rarity) public view returns (uint256) {
        return landTypeAndRarityToLandSectorCount[_landType][_rarity];
    }

    function getSectorSupplyByRarity(uint16 _landType, uint16 _rarity) public view returns (uint256) {
        return landTypeAndRarityToSectorSupply[_landType][_rarity];
    }

    function getMintedSectorList(uint16 _landType) public view returns (uint256[] memory) {
        return landTypeToLandSectorList[_landType];
    }

    function getSectorVolumeByRarity(uint16 _rarity) public view returns (uint256) {
        return rarityToSectorVolume[_rarity];
    }

    function getShareRateWithDecimal(uint256 _landSector) public view returns (uint256, uint256) {
        return (
        getSectorVolumeByRarity(getRarity(_landSector))
        .mul(SHARE_RATE_DECIMAL)
        .div(getTotalVolume(getLandType(_landSector))),
        SHARE_RATE_DECIMAL
        );
    }

    function mintLandSector(address _owner, uint256 _landSector, bytes32 _eventHash) public onlyMinter {
        require(!isAlreadyMinted(_landSector));
        require(isValidLandSector(_landSector));
        uint16 _landType = getLandType(_landSector);
        require(landTypeToLandSectorIndex[_landType] < landTypeToSectorSupplyLimit[_landType]);
        uint16 rarity = getRarity(_landSector);
        require(landTypeAndRarityToLandSectorCount[_landType][rarity] < landTypeAndRarityToSectorSupply[_landType][rarity], "supply over");
        _mint(_owner, _landSector);
        landTypeToLandSectorList[_landType].push(_landSector);
        landTypeToLandSectorIndex[_landType]++;
        landTypeAndRarityToLandSectorCount[_landType][rarity]++;

        emit MintEvent(
            _owner,
            _landSector,
            block.timestamp,
            _eventHash
        );
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        bytes32 tokenIdBytes;
        if (_tokenId == 0) {
            tokenIdBytes = "0";
        } else {
            uint256 value = _tokenId;
            while (value > 0) {
                tokenIdBytes = bytes32(uint256(tokenIdBytes) / (2 ** 8));
                tokenIdBytes |= bytes32(((value % 10) + 48) * 2 ** (8 * 31));
                value /= 10;
            }
        }

        bytes memory prefixBytes = bytes(tokenURIPrefix);
        bytes memory tokenURIBytes = new bytes(prefixBytes.length + tokenIdBytes.length);

        uint8 i;
        uint8 index = 0;

        for (i = 0; i < prefixBytes.length; i++) {
            tokenURIBytes[index] = prefixBytes[i];
            index++;
        }

        for (i = 0; i < tokenIdBytes.length; i++) {
            tokenURIBytes[index] = tokenIdBytes[i];
            index++;
        }

        return string(tokenURIBytes);
    }
}
/* solhint-enable indent*/
