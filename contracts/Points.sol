/// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

error OperatorRequire();
error InvalidSender();
error OnCooldown();

contract Points is Ownable {
    ///  Cooldown time between two claims
    uint256 public cdTime;

    ///  Fixed amount of points per claim
    uint256 public fixedAmount;

    /// store the Users' current recorded points (address => points)
    mapping(address => uint256) public points;

    ///  store the Users' last claiming time (address => unix timestamp)
    mapping(address => uint256) public lastClaims;

    ///  store a list of authorized Operators
    mapping(address => bool) public operators;

    /**
        - @dev Event emitted after `msg.sender` successfully claim `points`
        - Related function: claim()
    */
    event Claimed(address indexed sender, uint256 amount);

    /**
        - @dev Event emitted when `account` is updated its `points` by Operator
        - Related functions: increase() and decrease()
    */
    event Updated(address indexed account, uint256 amount, bool isIncreased);

    /// Restricted function's caller: allow Operator only
    modifier onlyOperator() {
        if (!operators[_msgSender()]) revert OperatorRequire();
        _;
    }

    constructor(
        address initOwner,
        uint256 cooldown,
        uint256 amount
    ) Ownable(initOwner) {
        cdTime = cooldown;
        fixedAmount = amount;
    }

    /** 
        @notice Set/Remove the authorized Operator
        @dev
        - Requirement:
            - Caller must be OWNER
        - Params:
            - account         Operator's address that will be updated
            - status          Set = true, Remove = false
    */
    function setOperator(address account, bool status) external onlyOwner {
        operators[account] = status;
    }

    /** 
        @notice Update new claim settings: `cdTime` and `amount`
        @dev
        - Requirement:
            - Caller must be Operator
        - Params:
            - cdTime          Cooldown time between two claims
            - amount          Points amount per claim
    */
    function setClaimSetting(
        uint256 cooldown,
        uint256 amount
    ) external onlyOperator {
        cdTime = cooldown;
        fixedAmount = amount;
    }

    /** 
        @notice Claim `points`
        @dev
        - Requirements:
            - Caller can be ANY
            - Must wait for cooldown between two claims
        Note: Function can be disabled by setting `cdTime` is large enough (e.g. type(uint128).max)
    */
    function claim() external {
        address sender = _msgSender();
        uint256 currentTime = block.timestamp;
        uint256 claimingAmt = fixedAmount;
        if (lastClaims[sender] + cdTime > currentTime) revert OnCooldown();

        //  update `lastClaim` time, then update points of `msg.sender`
        lastClaims[sender] = currentTime;
        points[sender] += claimingAmt;

        emit Claimed(sender, claimingAmt);
    }

    /** 
        @notice Increase current `points` of the `account`
        @dev
        - Requirements:
            - Caller must be Operator
        - Params:
            - account         Account's address that needs to be updated
            - amount          Amount of points to be increased
    */
    function increase(address account, uint256 amount) external onlyOperator {
        points[account] += amount;

        emit Updated(account, amount, true);
    }

    /** 
        @notice Decrease current `points` of the `account`
        @dev
        - Requirements:
            - Caller must be Operator
        - Params:
            - account         Account's address that needs to be updated
            - amount          Amount of points to be decreased
    */
    function decrease(address account, uint256 amount) external onlyOperator {
        points[account] -= amount;

        emit Updated(account, amount, false);
    }
}
