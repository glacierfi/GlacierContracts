// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./libraries/MerkleProof.sol";
import "./interfaces/IGlacier.sol";
import "./interfaces/IVotingEscrow.sol";

/// @title MerkleClaim
/// @notice Claims EQUAL for members of a merkle tree
/// @author Modified from Merkle Airdrop Starter (https://github.com/Anish-Agnihotri/merkle-airdrop-starter/blob/master/contracts/src/MerkleClaimERC20.sol)
contract MerkleClaim is OwnableUpgradeable {
    /// @notice max lock period 26 weeeks
    uint256 public constant LOCK = 86400 * 7 * 26;
    uint256 public constant MAX_AMOUNT = 500_000 * 10 ** 18;

    uint256 public duration;
    uint256 public startTime;
    /// ============ Immutable storage ============
    IVotingEscrow public ve;
    /// @notice EQUAL token to claim
    IGlacier public equal;
    /// @notice ERC20-claimee inclusion root
    bytes32 public merkleRoot;

    /// @notice Mapping from boost level to veEQUAL token amount
    mapping(uint => uint) public boostAmount;

    /// ============ Mutable storage ============

    /// @notice Mapping of addresses who have claimed tokens
    mapping(address => bool) public hasClaimed;

    /// ============ Constructor ============

    /// @notice Initialize new MerkleClaim contract
    /// @param _ve address
    /// @param _merkleRoot of claimees
    /// @param _duration duration for airdrop
    function initialize(
        address _ve, bytes32 _merkleRoot, uint256 _duration
    ) public initializer {
        __Ownable_init();
        ve = IVotingEscrow(_ve);
        equal = IGlacier(IVotingEscrow(_ve).token());
        merkleRoot = _merkleRoot;
        duration = _duration;

        boostAmount[1] = 150;
        boostAmount[2] = 220;
        boostAmount[3] = 300;
    }

    /* ============ Events ============ */

    /// @notice Emitted after a successful token claim
    /// @param to recipient of claim
    /// @param amount of veTokens claimed
    /// @param tokenId veToken NFT Id
    event Claim(address indexed to, uint256 amount, uint256 tokenId);

    /// @notice Emitted after a successful withdrawal of remaining tokens
    /// @param recipient recipient of remaining tokens
    /// @param amount of remaining tokens
    event Withdrawal(address indexed recipient, uint256 amount);

    /* ============ Functions ============ */

    /// @notice set start time for airdrop
    /// @param _startTime start time (in seconds)
    function setStartTime(uint256 _startTime) external onlyOwner {
        require(_startTime > block.timestamp, "Invalid start time");
        startTime = _startTime;
    }

    /// @notice set duration for airdrop
    /// @param _duration duration (in days)
    function setDuration(uint256 _duration) external onlyOwner {
        require(_duration > 0, "Invalid duration days");
        duration = _duration;
    }

    /// @notice set merkle root
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
    
    /// @notice Allows claiming tokens if address is part of merkle tree
    /// @param _to address of claimee
    /// @param _boostLevel depending on number 1-3 is how many veEQUAL the receive 
    /// @param _proof merkle proof to prove address and amount are in tree
    function claim(
        address _to,
        uint256 _boostLevel,
        bytes32[] calldata _proof
    ) external {
        uint256 endTime = startTime + duration * 86400;
        // check valid timestamp
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Airdrop is not started yet or already finished");
        
        // Throw if address has already claimed tokens
        require(!hasClaimed[_to], "ALREADY_CLAIMED");

        // Verify merkle proof, or revert if not in tree
        bytes32 leaf = keccak256(abi.encodePacked(_to, _boostLevel));
        bool isValidLeaf = MerkleProof.verify(_proof, merkleRoot, leaf);
        require(isValidLeaf, "NOT_IN_MERKLE");

        uint256 claimAmount = boostAmount[_boostLevel] * 10 ** 18;
        require(equal.balanceOf(address(this)) >= claimAmount, "All tokens were already claimed");

        // Set address to claimed
        hasClaimed[_to] = true;
        equal.approve(address(ve), claimAmount);
        // Claim veEQUALs for address
        uint256 tokenId = ve.create_lock_for(claimAmount, LOCK, _to);
        // Emit claim event
        emit Claim(_to, claimAmount, tokenId);
    }

    /// @notice withdraw remaining tokens if airdrop is finished
    function withdrawEQUAL(address _recipient) external onlyOwner {
        require(block.timestamp > startTime + duration * 86400, "Airdrop is not finished yet");
        uint256 remaining = equal.balanceOf(address(this));
        require(remaining > 0, "No remaining tokens");
        equal.transfer(_recipient, remaining);
        // Emit withdrawal event
        emit Withdrawal(_recipient, remaining);
    }

    function setClaimStatus(address[] memory _accounts, bool[] memory _statuses) external onlyOwner {
        for (uint256 i = 0; i < _accounts.length; i++) {
            hasClaimed[_accounts[i]] = _statuses[i];
        }
    }
}
