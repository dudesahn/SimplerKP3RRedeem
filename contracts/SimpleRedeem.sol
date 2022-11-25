// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IKeeper {
    function redeem(uint256 id) external;

    function claim(uint256 amount) external returns (uint256);

    function options(uint256)
        external
        view
        returns (
            uint256 amount,
            uint256 strike,
            uint256 expiry,
            bool exercised
        );
}

contract SimpleRedeem {
    using SafeERC20 for IERC20;

    IERC20 public constant usdc =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public constant kp3r =
        IERC20(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44);
    address public constant rkp3r = 0xEdB67Ee1B171c4eC66E6c10EC43EDBbA20FaE8e9;

    /// @notice yTrades multisig, only used for sweeps
    address public constant gov = 0x7d2aB9CA511EBD6F03971Fb417d3492aA82513f0;

    constructor() {
        usdc.approve(rkp3r, 2**256 - 1);
    }

    /// @notice Automates conversion of rKP3R+USDC -> KP3R.
    /// @dev Make sure to have enough USDC to cover the strike.
    /// @param _amount The amount of rKP3R to convert.
    function redeem(uint256 _amount) external {
        // transfer rKP3R to the selling contract
        IERC20(rkp3r).safeTransferFrom(msg.sender, address(this), _amount);

        // claim our oKP3R NFT
        uint256 nftId = IKeeper(rkp3r).claim(_amount);

        // check our amount and strike (usdc needed)
        (uint256 kprAmount, uint256 usdcNeeded, , ) =
            IKeeper(rkp3r).options(nftId);

        // transfer in needed USDC
        usdc.safeTransferFrom(msg.sender, address(this), usdcNeeded);

        // redeem our NFT for KP3R
        IKeeper(rkp3r).redeem(nftId);

        // send KP3R back to the original sender
        kp3r.safeTransfer(msg.sender, kprAmount);
    }

    /// @notice Sweeps any loose tokens to gov.
    /// @param _token The address of the token to sweep.
    function sweep(address _token) external {
        IERC20 tokenToSend = IERC20(_token);
        uint256 amountToSend = tokenToSend.balanceOf(address(this));
        tokenToSend.safeTransfer(gov, amountToSend);
    }

    /// @notice Necessary function so we can handle the oKP3R contract.
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return SimpleRedeem.onERC721Received.selector;
    }
}
