// SPDX-License-Identifier: None
pragma solidity =0.8.20;

/**
   @title IPoints contract
   @dev Provide interfaces that allow interaction to Points contract
*/
interface IPoints {
    /** 
        @notice Increase current `points` of the `account`
        @dev
        - Requirements:
            - Caller must be Operator
        - Params:
            - account         Account's address that needs to be updated
            - amount          Amount of points to be increased
    */
    function increase(address account, uint256 amount) external;

    /** 
        @notice Decrease current `points` of the `account`
        @dev
        - Requirements:
            - Caller must be Operator
        - Params:
            - account         Account's address that needs to be updated
            - amount          Amount of points to be decreased
    */
    function decrease(address account, uint256 amount) external;
}
