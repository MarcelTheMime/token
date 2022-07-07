
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("SimpleToken", "SPL") {
        _mint(msg.sender, initialSupply);
    }
}