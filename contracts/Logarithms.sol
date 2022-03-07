// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract KaijuKongz is Context, AccessControlEnumerable, ERC721, ERC721Enumerable, Ownable {

  uint256 constant public maxTotalSupply = 3333;
  uint256 constant public legendarySupply = 9;
  uint256 constant public teamSupply = 30;

  uint256 public pricePerToken = 0.065 ether;
  uint256 public tokensMinted = 40;
  uint256 public tokensBurned = 0;
  bool public legendaryTokensMinted = false;
  bool public teamTokensMinted = false;
  bool public tradeActive = false;

  enum SaleState{ CLOSED, PRIVATE, PUBLIC }
  SaleState public saleState = SaleState.CLOSED;

  bytes32 private merkleRootGroup1;
  bytes32 private merkleRootGroup2;

  mapping(address => uint256) presaleMinted;
  string _baseTokenURI;
  uint256 deployedTime;

  constructor() ERC721("Logarithms", "Log") {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    deployedTime = block.timestamp;
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) public override {
    require(tradeActive, "Trade is not active");
    super.safeTransferFrom(_from, _to, _tokenId, data);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override {
    require(tradeActive, "Trade is not active");
    super.safeTransferFrom(_from, _to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) public override {
    require(tradeActive, "Trade is not active");
    super.transferFrom(_from, _to, _tokenId);
  }

  function setTradeState(bool tradeState) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Cannot set trade state");
    tradeActive = tradeState;
  }

  function setPrice(uint256 newPrice) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Cannot set price");
    pricePerToken = newPrice;
  }

  function mintLegendaries() public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Cannot mint team tokens");
    require(!legendaryTokensMinted, "Team tokens have already been minted");
    for (uint256 i = 0; i < legendarySupply; i++) {
      _mint(owner(), i + 1);
    }
    legendaryTokensMinted = true;  
  }

  function mintTeamTokens() public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Cannot mint team tokens");
    require(!teamTokensMinted, "Team tokens have already been minted");
    for (uint256 i = 0; i < teamSupply; i++) {
      _mint(owner(), i + 10);
    }
    teamTokensMinted = true;
  }

  function setSaleState(SaleState newState) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Cannot alter sale state");
    saleState = newState;
  }

  function setMerkleRoot(bytes32 newRootGroup1, bytes32 newRootGroup2) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Cannot set merkle root");
    merkleRootGroup1 = newRootGroup1;
    merkleRootGroup2 = newRootGroup2;
  }

  function withdraw() public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Cannot withdraw");
    payable(owner()).call{value: address(this).balance}("");
  }

  function presale(uint256 amount, bytes32[] calldata proof) public payable {
    require (saleState == SaleState.PRIVATE, "Sale state should be private");
    require(totalSupply() < maxTotalSupply, "Max supply reached");
    bool isValidGroup1 = MerkleProof.verify(proof, merkleRootGroup1, keccak256(abi.encodePacked(msg.sender)));
    bool isValidGroup2 = MerkleProof.verify(proof, merkleRootGroup2, keccak256(abi.encodePacked(msg.sender)));
    require(isValidGroup1 || isValidGroup2, "You are not in the valid whitelist");

    uint256 amountAllowed = isValidGroup1 ? 1 : 2;
    require(amount + presaleMinted[msg.sender] <= amountAllowed, "Your amount value is not valid");
    require(presaleMinted[msg.sender] < amountAllowed, "You've already minted all");
    uint256 amountToPay = amount * pricePerToken;
    require(amountToPay <= msg.value, "Provided not enough Ether for purchase");
    for (uint256 i = 0; i < amount; i++) {
        _mint(_msgSender(), tokensMinted);
        tokensMinted += 1;
        presaleMinted[msg.sender] ++;
    }
  }

  function publicsale(uint256 amount) public payable {
    require (saleState == SaleState.PUBLIC, "Sale should be public");
    require(totalSupply() < maxTotalSupply, "Max supply reached");

    uint256 amountToPay = amount * pricePerToken;
    require(amountToPay <= msg.value, "Provided not enough Ether for purchase");
    for (uint256 i = 0; i < amount; i++) {
        _mint(_msgSender(), tokensMinted);
        tokensMinted += 1;
    }
  }

  function burnMany(uint256[] calldata tokenIds) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller cannot burn");
    uint256 now = block.timestamp;
    require(now - deployedTime <= 6 * 24 * 3600, "Burn is available only for 6 days");
    for (uint256 i; i < tokenIds.length; i++) {
      _burn(tokenIds[i]);
    }
    tokensBurned += tokenIds.length;
  }

  function _baseURI() internal view virtual override returns (string memory) {
     return _baseTokenURI;
   }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function testMint(uint256 tokenId) public onlyOwner {
        _mint(msg.sender, tokenId);
    }
  /** * @dev See {IERC165-supportsInterface}.  */
    function supportsInterface(bytes4 interfaceId) public view virtual
  override(ERC721, ERC721Enumerable, AccessControlEnumerable) returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer( address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

}