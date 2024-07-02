// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Campaign is Ownable, Pausable, ReentrancyGuard {
    address payable public beneficiary;
    uint256 public deadline;
    bool public fundraisingActive;
    mapping(address => uint256) public donations;
    mapping(address => bool) public signatories;
    uint256 public signatoryCount;
    uint256 public signatoryThreshold;

    event DonationReceived(address indexed donor, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);
    event SignatoryAdded(address indexed signatory);
    event SignatoryRemoved(address indexed signatory);
    event Signed(address indexed signatory);
    event FundraisingReopened(uint256 newDeadline);

    modifier onlySignatory() {
        require(signatories[msg.sender], "Not a signatory");
        _;
    }

    constructor(
        address payable _beneficiary,
        uint256 _duration,
        uint256 _signatoryThreshold,
        address initialOwner
    ) Ownable(initialOwner) {
        require(_beneficiary != address(0), "Invalid beneficiary address");
        require(_duration > 0, "Duration should be greater than zero");
        require(_signatoryThreshold > 0, "Threshold should be greater than zero");

        beneficiary = _beneficiary;
        deadline = block.timestamp + _duration;
        fundraisingActive = true;
        signatoryThreshold = _signatoryThreshold;
    }

    function donate() external payable whenNotPaused nonReentrant {
        require(fundraisingActive, "Fundraising has ended");
        require(block.timestamp <= deadline, "Fundraising deadline passed");
        require(msg.value > 0, "Donation amount should be greater than zero");

        donations[msg.sender] += msg.value;
        emit DonationReceived(msg.sender, msg.value);
    }

    function withdraw() external onlySignatory nonReentrant {
        require(block.timestamp > deadline, "Fundraising not yet ended");
        require(address(this).balance > 0, "No funds to withdraw");
        require(signatoryCount >= signatoryThreshold, "Not enough signatories");

        uint256 amount = address(this).balance;
        beneficiary.transfer(amount);
        emit Withdrawal(beneficiary, amount);
    }

    function addSignatory(address _signatory) external onlyOwner {
        require(_signatory != address(0), "Invalid signatory address");
        require(!signatories[_signatory], "Already a signatory");

        signatories[_signatory] = true;
        signatoryCount++;
        emit SignatoryAdded(_signatory);
    }

    function removeSignatory(address _signatory) external onlyOwner {
        require(signatories[_signatory], "Not a signatory");

        signatories[_signatory] = false;
        signatoryCount--;
        emit SignatoryRemoved(_signatory);
    }

    function sign() external onlySignatory {
        emit Signed(msg.sender);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function extendDeadline(uint256 _duration) external onlyOwner {
        deadline += _duration;
    }

    function reopenFundraising(uint256 _newDuration) external onlyOwner {
        require(!fundraisingActive, "Fundraising is already active");
        deadline = block.timestamp + _newDuration;
        fundraisingActive = true;
        emit FundraisingReopened(deadline);
    }

    function closeFundraising() external onlyOwner {
        fundraisingActive = false;
    }
}
