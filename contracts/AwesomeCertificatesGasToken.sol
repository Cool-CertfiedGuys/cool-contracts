pragma solidity 0.5.11;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";
import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";



contract AwesomeCertificatesGasToken  is ERC20, ERC20Detailed, ERC20Mintable, ERC20Burnable {
    constructor
    (
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint _initialSupply
    )
    ERC20()
    ERC20Mintable()
    ERC20Burnable()
    ERC20Detailed(_name, _symbol, _decimals)
    public {
        _mint(msg.sender, _initialSupply * (10 ** uint256(decimals())));
    }
}