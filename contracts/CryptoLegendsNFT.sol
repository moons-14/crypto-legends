// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract CryptoLegendsNFT is ERC721Enumerable {
    constructor() ERC721("CryptoLegendsNFT", "CLT") {}

    struct LevelWorld {
        uint256 level;
        Monster[] defeatedMonsters;
    }

    struct World {
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

    mapping(address => World) addressToWorld;
    mapping(address => uint256) ownerWorldCount;

    function start() public {
        require(
            ownerWorldCount[msg.sender] == 0,
            "Multiple worlds cannot be created at this time!"
        );
        ownerWorldCount[msg.sender]++;
        lastTokenId++;

        addressToWorld[msg.sender].levelWorlds[0] = LevelWorld(
            0,
            new Monster[](0)
        );

        _mint(msg.sender, lastTokenId);
    }

    function getWorldSeed() public view returns (uint256) {
        bytes32 _hashSeed = _hashSender();

        return uint256(_hashSeed);
    }

    function _hashSender() private view returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender));
    }
}
