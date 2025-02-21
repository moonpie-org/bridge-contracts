// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IWRWA {
    function deposit() external payable;
    function withdraw(uint wad) external;
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}
