// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./libraries/Perlin.sol";

contract CryptoLegendsNFT is ERC721Enumerable {
    constructor() ERC721("CryptoLegendsNFT", "CLT") {}

    struct World {
        bool play;
        mapping(uint256 => Monster) defeatedMonsters;
    }

    struct Monster {
        uint256 x;
        uint256 y;
        uint256 attackPower;
        uint256 defensePower;
        uint256 dropRate;
    }

    uint256 lastTokenId = 0;

    uint256 worldScale = 25;
    uint256 worldWidth = 25;

    mapping(address => World) public addressToWorld;
    mapping(address => mapping(uint256 => mapping(uint256 => Tile)))
        public addressToWorldMap;

    //99x99
    //x:0-98
    //y:0-98
    //center:49,49

    struct Coords {
        uint256 x;
        uint256 y;
    }

    enum TileType {
        UNKNOWN,
        WATER,
        SAND,
        TREE,
        STUMP,
        CHEST,
        FARM,
        WINDMILL,
        GRASS,
        SNOW,
        STONE,
        ICE
    }

    enum TemperatureType {
        COLD,
        NORMAL,
        HOT
    }

    enum AltitudeType {
        SEA,
        BEACH,
        LAND,
        MOUNTAIN,
        MOUNTAINTOP
    }

    struct Tile {
        Coords coords;
        uint256[2] perlin;
        uint256 raritySeed;
        TileType tileType;
        TemperatureType temperatureType;
        AltitudeType altitudeType;
    }

    function start() public {
        require(
            addressToWorld[msg.sender].play == true,
            "You have already started the game"
        );
        addressToWorld[msg.sender].play = true;
        lastTokenId++;

        _mint(msg.sender, lastTokenId);
    }

    function getWorldSeed() public view returns (uint256) {
        bytes32 _hashSeed = _hashSender();

        return uint256(_hashSeed);
    }

    function isStarted() public view returns (bool) {
        return addressToWorld[msg.sender].play;
    }

    function _hashSender() private view returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender));
    }

    function _coordsToTile(Coords memory coords, uint256 _seed)
        private
        view
        returns (Tile memory)
    {
        uint256 perlin1 = Perlin.computePerlin(
            uint32(coords.x),
            uint32(coords.y),
            uint32(_seed),
            uint32(worldScale)
        );
        uint256 perlin2 = Perlin.computePerlin(
            uint32(coords.x),
            uint32(coords.y),
            uint32(_seed + 1),
            uint32(worldScale)
        );
        uint256 raritySeed = getRaritySeed(coords);

        uint256 height = perlin1;
        uint256 temperature = perlin2;
        temperature = uint256(
            int256(temperature) + (int256(coords.x) - 50) / 2
        );

        AltitudeType altitudeType = AltitudeType.SEA;
        if (height > 40) {
            altitudeType = AltitudeType.MOUNTAINTOP;
        } else if (height > 37) {
            altitudeType = AltitudeType.MOUNTAIN;
        } else if (height > 32) {
            altitudeType = AltitudeType.LAND;
        } else if (height > 30) {
            altitudeType = AltitudeType.BEACH;
        }

        TemperatureType temperatureType = TemperatureType.COLD;
        if (temperature > 42) {
            temperatureType = TemperatureType.HOT;
        } else if (temperature > 22) {
            temperatureType = TemperatureType.NORMAL;
        }

        TileType tileType = TileType.UNKNOWN;
        if (temperatureType == TemperatureType.COLD) {
            if (altitudeType == AltitudeType.MOUNTAINTOP) {
                tileType = TileType.SNOW;
            } else if (altitudeType == AltitudeType.MOUNTAIN) {
                tileType = TileType.SNOW;
            } else if (altitudeType == AltitudeType.LAND) {
                tileType = TileType.SNOW;
            } else if (altitudeType == AltitudeType.BEACH) {
                tileType = TileType.SNOW;
            } else {
                tileType = TileType.WATER;
            }
        } else if (temperatureType == TemperatureType.NORMAL) {
            if (altitudeType == AltitudeType.MOUNTAINTOP) {
                tileType = TileType.SNOW;
            } else if (altitudeType == AltitudeType.MOUNTAIN) {
                tileType = TileType.STONE;
            } else if (altitudeType == AltitudeType.LAND) {
                tileType = TileType.GRASS;
            } else if (altitudeType == AltitudeType.BEACH) {
                tileType = TileType.SAND;
            } else {
                tileType = TileType.WATER;
            }
        } else {
            if (altitudeType == AltitudeType.MOUNTAINTOP) {
                tileType = TileType.STONE;
            } else if (altitudeType == AltitudeType.MOUNTAIN) {
                tileType = TileType.SAND;
            } else if (altitudeType == AltitudeType.LAND) {
                tileType = TileType.SAND;
            } else if (altitudeType == AltitudeType.BEACH) {
                tileType = TileType.SAND;
            } else {
                tileType = TileType.WATER;
            }
        }

        return
            Tile({
                coords: coords,
                perlin: [perlin1, perlin2],
                raritySeed: raritySeed,
                tileType: tileType,
                temperatureType: temperatureType,
                altitudeType: altitudeType
            });
    }

    function getOwnCoordsToTile(uint256 _x, uint256 _y)
        public
        view
        returns (Tile memory)
    {
        // Tile memory cacheWorldMap = addressToWorldMap[msg.sender][_x][_y];
        // if (cacheWorldMap.tileType != TileType.UNKNOWN) {
        //     return cacheWorldMap;
        // } else {
        //     uint256 _seed = getWorldSeed();
        //     Tile memory tile = _coordsToTile(Coords(_x, _y), _seed);
        //     addressToWorldMap[msg.sender][_x][_y] = tile;
        //     return tile;
        // }
        uint256 _seed = getWorldSeed();
        return _coordsToTile(Coords(_x, _y), _seed);
    }

    function getRaritySeed(Coords memory coords)
        private
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(coords.x, coords.y))) % 8;
    }
}
