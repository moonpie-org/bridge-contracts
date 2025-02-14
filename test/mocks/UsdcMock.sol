pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract UsdcMock is ERC20("USDC", "USDC") {
    function mint(address _receiver, uint256 _amount) public {
        _mint(_receiver, _amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}
