// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {Base64} from "./libraries/Base64.sol";
import {IVeArtProxy} from "./interfaces/IVeArtProxy.sol";

contract VeArtProxy is IVeArtProxy {
    function toString(uint value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /* solhint-disable */
    function _tokenURI(uint _tokenId, uint _balanceOf, uint _locked_end, uint _value) external pure returns (string memory output) {
        output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>rect { fill: #1B1E36; } .base { fill: #B388FF; font-family: "JetBrains Mono", monospace; font-size: 16px; font-weight: bold; }</style><rect width="100%" height="100%" /><rect x="0" y="200" width="350" height="150" fill="#0D47A1" /><rect x="0" y="220" width="350" height="30" fill="#1B1E36" /><rect x="30" y="220" width="30" height="10" fill="white" /><rect x="60" y="210" width="30" height="20" fill="white" /><rect x="90" y="225" width="30" height="5" fill="white" /><rect x="120" y="215" width="30" height="15" fill="white" />';
        output = string(abi.encodePacked(output, '<text x="10" y="50" class="base">Token ID: ', toString(_tokenId), '</text>'));
        output = string(abi.encodePacked(output, '<text x="10" y="80" class="base">Balance of: ', toString(_balanceOf), '</text>'));
        output = string(abi.encodePacked(output, '<text x="10" y="110" class="base">Locked until: ', toString(_locked_end), '</text>'));
        output = string(abi.encodePacked(output, '<text x="10" y="140" class="base">Value: ', toString(_value), '</text></svg>'));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "lock #', toString(_tokenId), '", "description": "Glacier locks, can be used to boost gauge yields, vote on token emission, and receive bribes", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
    }
}

