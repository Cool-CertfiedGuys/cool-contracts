pragma solidity 0.5.11;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";
import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";



contract AwesomeCertificateERC20Bridge  is ERC20, ERC20Detailed, ERC20Mintable, ERC20Burnable {

    address owner;

    constructor
    (
        string memory _name,
        string memory _symbol
    )
    ERC20()
    ERC20Mintable()
    ERC20Burnable()
    ERC20Detailed(_name, _symbol, 0)
    public {
        owner = msg.sender;
        addMinter(msg.sender);
    }

    function burnAsIssuer(address _whom, uint _amount) external {
        require(msg.sender == owner, "Restricted method");
        _burn(_whom, _amount);
    }

    function close() external {
        require(msg.sender == owner, "Only the contract creator can close an ERC20 bridge");
        selfdestruct(msg.sender);
    }
}