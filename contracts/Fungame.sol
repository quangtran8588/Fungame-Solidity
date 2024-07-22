// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPoints.sol";

error OperatorRequire();
error AlreadySet();
error TooEarly();
error InvalidOption();
error GameUnavailable();
error LockoutPeriod();
error AlreadyGuessed();
error FreeGuessLimitReached();
error AlreadyClaimed();
error OnlyWinner();
error AddressZero();

contract Fungame is Ownable {
    enum Option {
        UNUSED,
        UP,
        DOWN
    }

    struct Game {
        uint256 startPrice;
        uint256 endPrice;
    }

    struct Setting {
        uint64 freeGuessPerDay; /// Number of free guesses per User (per day)
        uint64 fixedReward; /// fixed amount of reward per game
        uint64 windowTime; /// Time period per game (in seconds)
        uint64 lockoutTime; /// Time period which guessing submission is not allowed (in seconds)
    }

    struct GuessInfo {
        uint256 extra; ///  Raising extra points per guess
        Option option; ///  Guess option (UP or DOWN)
        bool isFreeGuess; ///  free guessing
        bool isClaimed;
    }

    ///  Address of Points contract
    IPoints public Points;

    ///  Game's starting time (unix timestamp)
    uint256 public immutable START_TIME;

    ///  Current game id
    uint256 public currentGame;

    ///  Fun Game contract settings
    Setting public settings;

    ///  Store a list of Authorized Operators
    mapping(address => bool) public operators;

    ///  Stores a list of Games (gameId => Game)
    mapping(uint256 => Game) public games;

    ///  User's guess per game (address => gameId => up/down)
    mapping(address => mapping(uint256 => GuessInfo)) public guesses;

    ///  Number of guessed per day (address => day => numOfGuesses)
    mapping(address => mapping(uint256 => uint256)) public numOfGuesses;

    /**
        - @dev Event emitted after Operator successfully update a game's result
        - Related function: callResult()
    */
    event Result(
        address indexed operator,
        uint256 indexed gameId,
        uint256 endPrice
    );

    /**
        - @dev Event emitted after Players successfully place their guess on one game
        - Related function: guess()
    */
    event Guess(
        address indexed sender,
        uint256 indexed gameId,
        uint256 amount,
        Option option
    );

    /**
        - @dev Event emitted after Players successfully make a claim
        - Related function: claim()
    */
    event Claimed(
        address indexed sender,
        uint256 indexed gameId,
        uint256 reward
    );

    ///  Restricted function's caller: allow Operator only
    modifier onlyOperator() {
        if (!operators[_msgSender()]) revert OperatorRequire();
        _;
    }

    constructor(
        address initOwner,
        uint256 startTime,
        IPoints pointsContract,
        Setting memory initSettings
    ) Ownable(initOwner) {
        Points = pointsContract;
        START_TIME = startTime;
        settings = initSettings;
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
        @notice Update Points contract
        @dev
        - Requirements:
            - Caller must be Operator
            - The new address should be non-zero (0x0)
        - Params:
            - pointsContract      The new address of Points contract
    */
    function setPointsContract(address pointsContract) external onlyOperator {
        if (pointsContract == address(0)) revert AddressZero();

        Points = IPoints(pointsContract);
    }

    /** 
        @notice Update new FunGame settings: `windowTime`, `lockoutTime`, and `fixedReward`
        @dev
        - Requirement:
            - Caller must be Operator
        - Params:
            - newSettings     Setting struct
                - freeGuessPerDay      New value of free guess allowance
                - windowTime           New value of window time
                - lockoutTime          New value of lockout time
                - fixedReward          New value of fixed reward
    */
    function setFunGame(Setting calldata newSettings) external onlyOperator {
        settings = newSettings;
    }

    /** 
        @notice Update a result of `gameId`
        @dev
        - Requirement:
            - Caller must have OPERATOR_ROLE
        - Params:
            - value           The value of `endPrice`
    */
    function callResult(uint256 value) external onlyOperator {
        uint256 gameId = currentGame;
        //  Not allow to override the game result
        //  thus, checking whether `gameId` already set the `endPrice`
        if (games[gameId].endPrice != 0) revert AlreadySet();

        //  - If `gameId != 0`
        //  Operator is only allowed to set `endPrice` after the end of a game
        if (
            gameId != 0 &&
            block.timestamp < START_TIME + gameId * settings.windowTime
        ) revert TooEarly();

        //  Update a final result of a current game
        //  Move on to the next game id, and set next game's `startPrice`
        games[gameId].endPrice = value;
        currentGame++;
        games[gameId + 1].startPrice = value;

        emit Result(msg.sender, gameId, value);
    }

    /** 
        @notice Players place their guess for one `gameId`
        @dev
        - Requirements:
            - Caller can be ANY
            - Players can place their guess at a `currentGame` or next two games.
            - During lockout time, Players are not able to place their guess.
            - Players can place their guess one time per game.
        - Params:
            - gameId            The unique game number
            - value             Extra points raising in the guess
            - option            Guessing option (UP = 1, DOWN = 2)
    */
    function guess(uint256 gameId, uint256 value, Option option) external {
        ///  Validate guessing request:
        ///  - Players are allowed to place their guess on the `currentGame` or the next two ones
        ///  - If `currentGame`: players only place their guess before `lockoutTime`
        ///  - Only two guessing options: UP or DOWN
        uint256 currentGameId = currentGame;
        Setting memory currentSettings = settings;
        address sender = msg.sender;
        uint256 currentTime = block.timestamp;
        if (currentTime < START_TIME) revert TooEarly();
        if (gameId != currentGameId && gameId > currentGameId + 2)
            revert GameUnavailable();
        if (
            gameId == currentGameId &&
            currentTime >
            START_TIME +
                gameId *
                currentSettings.windowTime -
                currentSettings.lockoutTime
        ) revert LockoutPeriod();
        if (Option.UP != option && Option.DOWN != option)
            revert InvalidOption();
        if (guesses[sender][gameId].option != Option.UNUSED)
            revert AlreadyGuessed();

        /// Players are given a number of `freeGuessPerDay`
        /// After using a number of `freeGuessPerDay`, Players are still be able to guess
        /// by specifying a `value` (raising extra points)
        /// Note: During free guess, Players are allowed to raise extra points
        /// If won, they would receive reward as `fixedReward` + 2 * `extraPoints`
        uint256 day = (currentTime - START_TIME) / 1 days;
        uint256 numOfGuessed = numOfGuesses[sender][day];
        if (value == 0 && numOfGuessed >= currentSettings.freeGuessPerDay)
            revert FreeGuessLimitReached();
        numOfGuesses[sender][day] = numOfGuessed + 1;

        if (value != 0) Points.decrease(sender, value);

        //  update storage state
        guesses[sender][gameId] = GuessInfo({
            extra: value,
            option: option,
            isFreeGuess: numOfGuessed + 1 <= currentSettings.freeGuessPerDay,
            isClaimed: false
        });

        emit Guess(sender, gameId, value, option);
    }

    /** 
        @notice Claim to receive winning reward points
        @dev
        - Requirement:
            - Caller can be ANY
            - Must be a winner for that `gameId`
            - Claim one time only
        - Params:
            - gameId            The unique game number
    */
    function claim(uint256 gameId) external {
        //  Players can claim when:
        //  - Game already finalized (endPrice != 0)
        //  - Not yet claimed
        address sender = msg.sender;
        GuessInfo memory info = guesses[sender][gameId];
        uint256 endPrice = games[gameId].endPrice;
        uint256 startPrice = games[gameId].startPrice;
        if (endPrice == 0) revert TooEarly();
        if (info.isClaimed) revert AlreadyClaimed();

        //  checking whether `msg.sender` is a winner
        Option result;
        if (endPrice > startPrice) result = Option.UP;
        else if (endPrice < startPrice) result = Option.DOWN;
        if (info.option != result) revert OnlyWinner();

        //  update storage state
        guesses[sender][gameId].isClaimed = true;

        uint256 reward;
        uint256 fixedReward = settings.fixedReward;
        if (info.isFreeGuess) {
            if (info.extra != 0) reward = fixedReward + 2 * info.extra;
            else reward = fixedReward;
        } else reward = 2 * info.extra;

        //  transfer points to winner
        Points.increase(sender, reward);

        emit Claimed(sender, gameId, reward);
    }

    /** 
        @notice Check winning status of the `account` for the `gameId`
        @dev
        - Requirements:
            - Caller can be ANY
            - `gameId` must be non-zero
            - Game must already be finalized by Operator
        - Params:
            - account           Account's address that needs to check winning status
            - gameId            The unique game number
    */
    function checkWinning(
        address account,
        uint256 gameId
    ) external view returns (bool) {
        if (gameId == 0 || games[gameId].endPrice == 0) return false;

        uint256 startPrice = games[gameId].startPrice;
        uint256 endPrice = games[gameId].endPrice;
        Option guessOption = guesses[account][gameId].option;

        if (
            (endPrice > startPrice && guessOption == Option.UP) ||
            (endPrice < startPrice && guessOption == Option.DOWN)
        ) return true;

        return false;
    }
}
