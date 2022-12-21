// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./interfaces/ILendingAdapter.sol";
import "./interfaces/ILendingPool.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract AaveLendingAdapter is ILendingAdapter {
    ILendingPool public lendingPool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);

    IERC20 public tokenA; // collateral token
    IERC20 public tokenB; // debt token

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function addCollateral(uint256 amount) external {
        tokenA.transferFrom(msg.sender, address(this), amount);

        tokenA.approve(address(lendingPool), amount);
        lendingPool.deposit(address(tokenA), amount, address(this), 0);
    }

    function withdrawCollateral(uint256 amount) external {
        lendingPool.withdraw(address(tokenA), amount, address(this));
        tokenA.transfer(msg.sender, amount);
    }

    function borrow(uint256 amount, uint256 interestRateMode) external {
        lendingPool.borrow(address(tokenB), amount, interestRateMode, 0, address(this));
        tokenB.transfer(msg.sender, amount);
    }

    function repayBorrow(uint256 amount, uint256 rateMode) external {
        tokenB.transferFrom(msg.sender, address(this), amount);

        tokenB.approve(address(lendingPool), amount);
        lendingPool.repay(address(tokenB), amount, rateMode, address(this));
    }

    function liquidate(address borrower, uint256 repayAmount) external {
        tokenB.transferFrom(msg.sender, address(this), repayAmount);

        tokenB.approve(address(lendingPool), repayAmount);
        lendingPool.liquidationCall(address(tokenA), address(tokenB), borrower, repayAmount, false);

        tokenA.transfer(msg.sender, tokenA.balanceOf(address(this)));
    }
}
