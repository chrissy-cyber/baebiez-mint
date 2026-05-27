// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * ██████╗  █████╗ ███████╗██████╗ ██╗███████╗███████╗
 * ██╔══██╗██╔══██╗██╔════╝██╔══██╗██║██╔════╝╚══███╔╝
 * ██████╔╝███████║█████╗  ██████╔╝██║█████╗    ███╔╝ 
 * ██╔══██╗██╔══██║██╔══╝  ██╔══██╗██║██╔══╝   ███╔╝  
 * ██████╔╝██║  ██║███████╗██████╔╝██║███████╗███████╗
 * ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═════╝ ╚═╝╚══════╝╚══════╝
 * 
 * BAEBIEZ NFT Collection
 * Total Supply: 4,444
 * Chain: ApeChain
 * 
 * Mint Phases:
 * 1. GTD  - 31 APE | Max 20 per wallet | Allowlist required
 * 2. FCFS - 31 APE | Max 20 per wallet | Allowlist required
 * 3. Public - 99 APE | Max 50 per wallet | Open to all
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BAEBIEZ is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;

    // ═══════════════════════════════════════════════════
    //  COLLECTION CONFIG
    // ═══════════════════════════════════════════════════
    uint256 public constant MAX_SUPPLY        = 4444;
    uint256 public constant START_TOKEN_ID    = 920;   // Next token to mint
    uint256 public constant PRIOR_MINTED      = 919;   // Tokens 1-919 minted on the previous launchpad
    uint256 public currentTokenId             = 920;   // Tracks current mint position

    // ═══════════════════════════════════════════════════
    //  MINT PHASES
    // ═══════════════════════════════════════════════════
    enum Phase { CLOSED, GTD, FCFS, PUBLIC }
    Phase public currentPhase = Phase.CLOSED;

    // GTD Phase
    uint256 public gtdPrice = 31 ether;
    uint256 public constant GTD_MAX_PER_TX    = 20;
    uint256 public constant GTD_MAX_PER_WALLET = 20;
    bytes32 public gtdMerkleRoot;

    // FCFS Phase
    uint256 public fcfsPrice = 31 ether;
    uint256 public constant FCFS_MAX_PER_TX   = 20;
    uint256 public constant FCFS_MAX_PER_WALLET = 20;
    bytes32 public fcfsMerkleRoot;

    // Public Phase
    uint256 public publicPrice = 99 ether;
    uint256 public constant PUBLIC_MAX_PER_TX = 50;
    uint256 public constant PUBLIC_MAX_PER_WALLET = 50;

    // ═══════════════════════════════════════════════════
    //  METADATA
    // ═══════════════════════════════════════════════════
    string private _baseTokenURI = "ipfs://QmYFh999Pqzm2njTgrGNAAvJsRkKQ8JUqt6GnCys1jM1zZ/";
    bool public revealed = true;

    // ═══════════════════════════════════════════════════
    //  FUNDS RECIPIENT
    // ═══════════════════════════════════════════════════
    address public constant FUNDS_RECIPIENT = 0x89c9fC9a481f2B8F68887712FF477C6Bc15Ff518;

    // ═══════════════════════════════════════════════════
    //  TRACKING
    // ═══════════════════════════════════════════════════
    mapping(address => uint256) public gtdMinted;
    mapping(address => uint256) public fcfsMinted;
    mapping(address => uint256) public publicMinted;

    // ═══════════════════════════════════════════════════
    //  EVENTS
    // ═══════════════════════════════════════════════════
    event PhaseChanged(Phase newPhase);
    event Minted(address indexed minter, uint256 quantity, uint256 totalCost, Phase phase);
    event BaseURIUpdated(string newBaseURI);
    event FundsWithdrawn(address recipient, uint256 amount);

    // ═══════════════════════════════════════════════════
    //  CONSTRUCTOR
    // ═══════════════════════════════════════════════════
    constructor() ERC721("BAEBIEZ", "BAEBIEZ") Ownable(msg.sender) {}

    // ═══════════════════════════════════════════════════
    //  MODIFIERS
    // ═══════════════════════════════════════════════════
    modifier mintCompliance(uint256 quantity) {
        require(quantity > 0, "Must mint at least 1");
        require(currentTokenId + quantity - 1 <= MAX_SUPPLY, "Exceeds max supply");
        _;
    }

    // ═══════════════════════════════════════════════════
    //  GTD MINT
    // ═══════════════════════════════════════════════════
    function gtdMint(uint256 quantity, bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        mintCompliance(quantity)
    {
        require(currentPhase == Phase.GTD, "GTD phase not active");
        require(quantity <= GTD_MAX_PER_TX, "Exceeds max per transaction");
        require(gtdMinted[msg.sender] + quantity <= GTD_MAX_PER_WALLET, "Exceeds GTD wallet limit");
        require(msg.value >= gtdPrice * quantity, "Insufficient payment");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, gtdMerkleRoot, leaf), "Not on GTD allowlist");

        gtdMinted[msg.sender] += quantity;
        _mintBatch(msg.sender, quantity);

        emit Minted(msg.sender, quantity, msg.value, Phase.GTD);
    }

    // ═══════════════════════════════════════════════════
    //  FCFS MINT
    // ═══════════════════════════════════════════════════
    function fcfsMint(uint256 quantity, bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        mintCompliance(quantity)
    {
        require(currentPhase == Phase.FCFS, "FCFS phase not active");
        require(quantity <= FCFS_MAX_PER_TX, "Exceeds max per transaction");
        require(fcfsMinted[msg.sender] + quantity <= FCFS_MAX_PER_WALLET, "Exceeds FCFS wallet limit");
        require(msg.value >= fcfsPrice * quantity, "Insufficient payment");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, fcfsMerkleRoot, leaf), "Not on FCFS allowlist");

        fcfsMinted[msg.sender] += quantity;
        _mintBatch(msg.sender, quantity);

        emit Minted(msg.sender, quantity, msg.value, Phase.FCFS);
    }

    // ═══════════════════════════════════════════════════
    //  PUBLIC MINT
    // ═══════════════════════════════════════════════════
    function publicMint(uint256 quantity)
        external
        payable
        nonReentrant
        mintCompliance(quantity)
    {
        require(currentPhase == Phase.PUBLIC, "Public phase not active");
        require(quantity <= PUBLIC_MAX_PER_TX, "Exceeds max per transaction");
        require(publicMinted[msg.sender] + quantity <= PUBLIC_MAX_PER_WALLET, "Exceeds public wallet limit");
        require(msg.value >= publicPrice * quantity, "Insufficient payment");

        publicMinted[msg.sender] += quantity;
        _mintBatch(msg.sender, quantity);

        emit Minted(msg.sender, quantity, msg.value, Phase.PUBLIC);
    }

    // ═══════════════════════════════════════════════════
    //  INTERNAL MINT
    // ═══════════════════════════════════════════════════
    function _mintBatch(address to, uint256 quantity) internal {
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(to, currentTokenId);
            currentTokenId++;
        }
    }

    // ═══════════════════════════════════════════════════
    //  OWNER MINT (for giveaways/team)
    // ═══════════════════════════════════════════════════
    function ownerMint(address to, uint256 quantity)
        external
        onlyOwner
        mintCompliance(quantity)
    {
        _mintBatch(to, quantity);
    }

    function bulkAirdrop(
        address[] calldata recipients,
        uint256[] calldata quantities
    ) external onlyOwner nonReentrant {
        require(
            recipients.length == quantities.length,
            "Recipients and quantities arrays must match"
        );
        require(recipients.length > 0, "No recipients provided");

        uint256 totalQuantity = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            require(quantities[i] > 0, "Quantity must be greater than 0");
            totalQuantity += quantities[i];
        }

        require(
            currentTokenId + totalQuantity - 1 <= MAX_SUPPLY,
            "Airdrop exceeds max supply"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            _mintBatch(recipients[i], quantities[i]);
        }

        emit Minted(msg.sender, totalQuantity, 0, currentPhase);
    }

    // ═══════════════════════════════════════════════════
    //  PHASE MANAGEMENT
    // ═══════════════════════════════════════════════════
    function setPhase(Phase _phase) external onlyOwner {
        currentPhase = _phase;
        emit PhaseChanged(_phase);
    }

    function setGTDPrice(uint256 _price) external onlyOwner {
        gtdPrice = _price;
    }

    function setFCFSPrice(uint256 _price) external onlyOwner {
        fcfsPrice = _price;
    }

    function setPublicPrice(uint256 _price) external onlyOwner {
        publicPrice = _price;
    }

    function setGTDMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        gtdMerkleRoot = _merkleRoot;
    }

    function setFCFSMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        fcfsMerkleRoot = _merkleRoot;
    }

    // ═══════════════════════════════════════════════════
    //  METADATA
    // ═══════════════════════════════════════════════════
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    function baseURI() external view returns (string memory) {
        return _baseTokenURI;
    }

    // ═══════════════════════════════════════════════════
    //  WITHDRAW
    // ═══════════════════════════════════════════════════
    function withdraw() external nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = payable(FUNDS_RECIPIENT).call{value: balance}("");
        require(success, "Withdrawal failed");
        
        emit FundsWithdrawn(FUNDS_RECIPIENT, balance);
    }

    // ═══════════════════════════════════════════════════
    //  VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════
    function totalMinted() external view returns (uint256) {
        return currentTokenId - 1;
    }

    function mintedOnThisContract() external view returns (uint256) {
        return currentTokenId - START_TOKEN_ID;
    }

    function totalRemaining() external view returns (uint256) {
        return MAX_SUPPLY - currentTokenId + 1;
    }

    function remainingSupply() external view returns (uint256) {
        return MAX_SUPPLY - currentTokenId + 1;
    }

    function getCurrentPhase() external view returns (string memory) {
        if (currentPhase == Phase.CLOSED)  return "CLOSED";
        if (currentPhase == Phase.GTD)     return "GTD";
        if (currentPhase == Phase.FCFS)    return "FCFS";
        if (currentPhase == Phase.PUBLIC)  return "PUBLIC";
        return "UNKNOWN";
    }

    // ═══════════════════════════════════════════════════
    //  RECEIVE ETH
    // ═══════════════════════════════════════════════════
    receive() external payable {}
}
