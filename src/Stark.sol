// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {ERC721, Strings} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/IStarknetCore.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Stark is ERC721, Ownable {
    IStarknetCore constant starknetCore = IStarknetCore(0xde29d060D45901Fb19ED6C6e959EB22d8626708e);
    uint256 public l2Contract;
    uint256 public CLAIM_SELECTOR;
    uint256 public BRIDGE_SELECTOR;
    string public baseURI_;
    using Strings for uint256;

    constructor() ERC721("stark mfer", "SMFER") {
        baseURI_ = "ipfs://QmXvHkdDtaTaQZUKCPvAjyf9kyxZkuui84gSXj2NnTgn9k/";
        l2Contract = 810323602942697366567242979374629199112987288697621663029353217068645726829;
        BRIDGE_SELECTOR = 228332440751124852185837610095173653227759861791712944151737767244387345483;
    }

    function setClaimSelector(uint256 _claimSelector) external onlyOwner {
        CLAIM_SELECTOR = _claimSelector;
    }

    function setBridgeSelector(uint256 _bridgeSelector) external onlyOwner {
        BRIDGE_SELECTOR = _bridgeSelector;
    }

    function setL2Contract(uint256 _l2) external onlyOwner {
        l2Contract = _l2;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI_ = _uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI_;
    }

    function bridgeFromL2(uint256 l2User, address recipient, uint256 tokenId) external {
        uint256[] memory payload = new uint256[](3);
        payload[0] = l2User;
        payload[1] = uint256(uint160(recipient));
        payload[2] = tokenId;
        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        starknetCore.consumeMessageFromL2(l2Contract, payload);
        _safeMint(address(uint160(msg.sender)), tokenId);
        // Send the message to the StarkNet core contract.
        starknetCore.sendMessageToL2(
            l2Contract,
            CLAIM_SELECTOR,
            payload
        );
    }

    function bridgeToL2(uint256 l2User, uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "not owner/approved");
        _burn(tokenId);

        uint256[] memory payload = new uint256[](2);
        payload[0] = l2User;
        payload[1] = tokenId;

        starknetCore.sendMessageToL2(l2Contract, BRIDGE_SELECTOR, payload);
    }

    function mintToL2(uint256 l2User, uint256 tokenId) external onlyOwner {
        uint256[] memory payload = new uint256[](2);
        payload[0] = l2User;
        payload[1] = tokenId;

        starknetCore.sendMessageToL2(l2Contract, BRIDGE_SELECTOR, payload);
    }
}
