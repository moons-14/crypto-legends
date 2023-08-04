// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./libraries/PerlinNoise.sol";

contract CryptoLegendsNFT is ERC721Enumerable {
    constructor() ERC721("CryptoLegendsNFT", "CLT") {}

    struct LevelWorld {
        uint256 level;
        Monster[] defeatedMonsters;
    }

    struct World {
        uint256 level;
        uint256 releasableLevel;
        mapping(uint256 => LevelWorld) levelWorlds;
    }

    struct Monster {
        uint256 x;
        uint256 y;
        uint256 attackPower;
        uint256 defensePower;
        uint256 dropRate;
    }

    uint256 lastTokenId = 0;

    mapping(address => World) public addressToWorld;
    mapping(address => uint256) ownerWorldCount;

    enum Terrain {
        Lake,
        River,
        Plain,
        Mountain
    }

    // Mapping the hashed value to a terrain type
    function getTerrain(
        uint256 _seed,
        uint256 _x,
        uint256 _y
    ) public pure returns (Terrain) {
        require(_x <= 100 && _x >= 0);
        require(_y <= 100 && _x >= 0);
        int256 n3d = PerlinNoise.noise3d(
            int256((_x * 65536) / 100),
            int256((_y * 65536) / 100),
            int256(((_seed % 100) * 65536) / 100)
        );

        if (n3d < 16384) {
            return Terrain.Lake;
        } else if (n3d < 32768) {
            return Terrain.River;
        } else if (n3d < 49152) {
            return Terrain.Plain;
        } else {
            return Terrain.Mountain;
        }
    }

    function getMyTerrain(uint256 _x, uint256 _y) public view returns (Terrain) {
        uint256 _seed = getWorldSeed();
        return getTerrain(_seed, _x, _y);
    }


    function start() public {
        require(
            ownerWorldCount[msg.sender] == 0,
            "Multiple worlds cannot be created at this time!"
        );
        ownerWorldCount[msg.sender]++;
        lastTokenId++;

        addressToWorld[msg.sender].releasableLevel = 1;
        _releaseLevel(1);

        _mint(msg.sender, lastTokenId);
    }

    function _releaseLevel(uint256 _level) private {
        //ゲームを始めているか
        require(isStarted(), "Must have started the game");
        //解放可能なレベルがあるか
        require(
            addressToWorld[msg.sender].releasableLevel == _level,
            "Level must be releasable"
        );

        //レベルワールドを追加する
        addressToWorld[msg.sender].levelWorlds[_level].level = _level;

        //レベルを上げる
        addressToWorld[msg.sender].level = _level;
    }

    function getWorldSeed() public view returns (uint256) {
        bytes32 _hashSeed = _hashSender();

        return uint256(_hashSeed);
    }

    function isStarted() public view returns (bool) {
        return ownerWorldCount[msg.sender] == 1;
    }

    function _hashSender() private view returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender));
    }
}
