pragma solidity 0.5.11;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";
import './AwesomeCertificateERC20Bridge.sol';


contract AwesomeCertificates {

    // Events

    event NewCertficateFamilyRegistered(
        address indexed _by,
        bytes32 _entropy
    );

    event CertificateIssued(
        address indexed _by,
        bytes32 _family,
        address indexed _to,
        uint _quantity
    );

    event CertficateTransfer(
        address _issuer,
        bytes32 _family,
        address indexed _sender,
        address indexed _recipient,
        uint _quantity
    );

    event CertificateFamilyBridgedToErc20(
        address indexed _issuer,
        bytes32 indexed _family,
        address _bridgeContractAddress
    );

    event CertfiticatesBurned(
        address indexed _issuer,
        bytes32 indexed _family,
        uint _quantity,
        address _whos,
        address _burner
    );

    // Structs

    struct CertificateFamily {
        address erc20BridgeAddress;
        mapping(address => uint) balances;

        mapping(address => bool) tokensStaked;

        uint holdersCount;
        mapping(uint => address) holders;
        mapping(address => uint) holderId;
    }

    // Variables

    address public owner;
    IERC20 public awesomeCertificatesGasTokenContractInstance;

    // Issuer => certficate entropy / family => owner => quantity
    mapping(address => mapping(bytes32 => CertificateFamily)) public certificates;

    // Constructor

    constructor(address _awesomeCertificatesGasTokenContractAddress) public {
        owner = msg.sender;
        awesomeCertificatesGasTokenContractInstance = IERC20(_awesomeCertificatesGasTokenContractAddress);
    }

    // Modifiers

    modifier doesCertificateFamilyExist(address _issuer, bytes32 _familyEntropy) {
        require(
            certificates[_issuer][_familyEntropy].balances[address(0)] > 0,
            "Certificates family with the given entropy do not exist"
            );
        _;
    }

     modifier doesNotCertificateFamilyExist(address _issuer, bytes32 _familyEntropy) {
        require(
            certificates[_issuer][_familyEntropy].balances[address(0)] == 0,
            "Certificates family with the given entropy already exist"
            );
        _;
    }

    modifier isOwner() {
        require(msg.sender == owner, "This method can be called only by the contract owner");
        _;
    }

    modifier isQuantitySufficientToTransfer(
        address _certificateIssuer,
        bytes32 _family,
        address _sender,
        uint _transferedQuantity
    ) {
        require(
            certificates[_certificateIssuer][_family].balances[_sender] >= _transferedQuantity,
            "You can't transfer more certificates than you have"
        );
        _;
    }

    modifier isNotCertificateFamilyErc20Bridged(address _certficateIssuer, bytes32 _family) {
        require(certificates[_certficateIssuer][_family].erc20BridgeAddress == address(0), "Certifictate is already bridged");
        _;
    }

    modifier transferRecipientNotZeroAddress(address _recipient) {
        require(_recipient != address(0), "Certificates cannot be transfered to the 0x0 address");
        _;
    }
    // State changing methods

    // Internals
    function _transfer(
        address _certificateIssuer,
        bytes32 _family,
        address _from,
        address _to,
        uint _quantity
    ) internal
    isQuantitySufficientToTransfer(_certificateIssuer, _family, _from, _quantity)
    {
        require(_to != address(0), "Certificates cannot be transfered to the 0x0 address");

        require(
            certificates[_certificateIssuer][_family].balances[address(0)] > 0,
            "Certificates family with the given entropy do not exist"
        );

        if(certificates[_certificateIssuer][_family].balances[_from] == _quantity) {
            uint _holderId = certificates[_certificateIssuer][_family].holderId[_from];
            uint _holdersCount = certificates[_certificateIssuer][_family].holdersCount;
            certificates[_certificateIssuer][_family].holders[_holderId] = certificates[_certificateIssuer][_family].holders[_holdersCount - 1];
            delete certificates[_certificateIssuer][_family].holders[_holdersCount];
        }

        if(certificates[_certificateIssuer][_family].balances[_to] == 0) {
           certificates[_certificateIssuer][_family].holderId[_to] = certificates[_certificateIssuer][_family].holdersCount;
           certificates[_certificateIssuer][_family].holders[certificates[_certificateIssuer][_family].holdersCount] = _to;
           certificates[_certificateIssuer][_family].holdersCount++;
        }

        certificates[_certificateIssuer][_family].balances[_from] -= _quantity;
        certificates[_certificateIssuer][_family].balances[_to] += _quantity;
        emit CertficateTransfer(_certificateIssuer, _family, _from, _to, _quantity);
    }

    function _burn(
        address _certificateIssuer,
        bytes32 _family,
        address _whos,
        uint _quantity
    ) internal
    doesCertificateFamilyExist(_certificateIssuer, _family)
    isQuantitySufficientToTransfer(_certificateIssuer, _family, _whos, _quantity)
    {
        if(certificates[_certificateIssuer][_family].balances[_whos] == _quantity) {
            uint _holderId = certificates[_certificateIssuer][_family].holderId[_whos];
            uint _holdersCount = certificates[_certificateIssuer][_family].holdersCount;
            certificates[_certificateIssuer][_family].holders[_holderId] = certificates[_certificateIssuer][_family].holders[_holdersCount - 1];
            delete certificates[_certificateIssuer][_family].holders[_holdersCount];
        }
        certificates[_certificateIssuer][_family].balances[_whos] -= _quantity;
        emit CertfiticatesBurned(_certificateIssuer, _family, _quantity, _whos, msg.sender);
    }

    // Issuers methods

    function registerCertificateFamily(bytes32 _familyEntropy) public
    doesNotCertificateFamilyExist(msg.sender, _familyEntropy)
    {
        certificates[msg.sender][_familyEntropy].balances[address(0)]++;
        emit NewCertficateFamilyRegistered(msg.sender, _familyEntropy);
    }

    function assignCertificate(bytes32 _family, address _to, uint _quantity) public
    doesCertificateFamilyExist(msg.sender, _family)
    {
        if(certificates[msg.sender][_family].balances[_to] == 0) {
           certificates[msg.sender][_family].holderId[_to] = certificates[msg.sender][_family].holdersCount;
           certificates[msg.sender][_family].holders[certificates[msg.sender][_family].holdersCount] = _to;
           certificates[msg.sender][_family].holdersCount++;
        }
        certificates[msg.sender][_family].balances[_to] += _quantity;
        emit CertificateIssued(msg.sender, _family, _to, _quantity);
    }

    function bridgeCertficateFamily(
        bytes32 _family,
        string memory _bridgeTokenName,
        string memory _bridgeTokenSymbol
    ) public
    doesCertificateFamilyExist(msg.sender, _family)
    isNotCertificateFamilyErc20Bridged(msg.sender, _family)
    {
        AwesomeCertificateERC20Bridge _bridge = new AwesomeCertificateERC20Bridge(_bridgeTokenName, _bridgeTokenSymbol);
        address _bridgeAddress = address(_bridge);
        certificates[msg.sender][_family].erc20BridgeAddress = _bridgeAddress;
        emit CertificateFamilyBridgedToErc20(msg.sender, _family, _bridgeAddress);
    }

    function stakeErc20Bridge(address _certificateIssuer, bytes32 _family) public
    doesCertificateFamilyExist(msg.sender, _family)
    {
        require(isCertificateFamilyErc20Bridged(_certificateIssuer, _family), "Only bridged certificates can be staked");
        require(!certificates[_certificateIssuer][_family].tokensStaked[msg.sender], "You already staked your tokens");
        ERC20Mintable bridgeInstance = ERC20Mintable(certificates[_certificateIssuer][_family].erc20BridgeAddress);
        bridgeInstance.mint(msg.sender, certificates[_certificateIssuer][_family].balances[msg.sender]);
        certificates[_certificateIssuer][_family].tokensStaked[msg.sender] = true;
    }

    // TODO close bridge ???

    // Certficates owners methods

    function transfer(address _certificateIssuer, bytes32 _family, address _to, uint _quantity) public {
        _transfer(_certificateIssuer, _family, msg.sender, _to, _quantity);
    }

    function burnAsOwner(address _certificateIssuer, bytes32 _family, uint _quantity) public {
        _burn(_certificateIssuer, _family, msg.sender, _quantity);
    }

    function burnAsCertificateIssuer(
        bytes32 _family,
        uint _quantity,
        address _whos
    ) public {
        _burn(msg.sender, _family, _whos, _quantity);
    }

    // Getters

    function getCertificatesBalance(
        address _certificateIssuer,
        bytes32 _family,
        address _whosBalance
    ) public doesCertificateFamilyExist(_certificateIssuer, _family) view returns(uint) {
        return certificates[_certificateIssuer][_family].balances[_whosBalance];
    }

    function getCertificatesHoldersCount(
        address _certificateIssuer,
        bytes32 _family
    ) public doesCertificateFamilyExist(_certificateIssuer, _family) view returns(uint) {
        return certificates[_certificateIssuer][_family].holdersCount;
    }

    function getHolderAddressID(
        address _certificateIssuer,
        bytes32 _family,
        address _holder
    ) public doesCertificateFamilyExist(_certificateIssuer, _family) view returns(uint) {
        return certificates[_certificateIssuer][_family].holderId[_holder];
    }

    function getHolderAddressByID(
        address _certificateIssuer,
        bytes32 _family,
        uint _holderId
    ) public doesCertificateFamilyExist(_certificateIssuer, _family) view returns(address) {
        return certificates[_certificateIssuer][_family].holders[_holderId];
    }

    function isCertificateFamilyErc20Bridged(
        address _certificateIssuer,
        bytes32 _family
    ) public doesCertificateFamilyExist(_certificateIssuer, _family) view returns(bool) {
        return !(certificates[_certificateIssuer][_family].erc20BridgeAddress == address(0));
    }

    function getCertificateFamilyErc20BridgeAddress(
        address _certificateIssuer,
        bytes32 _family
    ) public doesCertificateFamilyExist(_certificateIssuer, _family) view returns(address) {
        require(certificates[_certificateIssuer][_family].erc20BridgeAddress != address(0), "Certficate family is not bridged");
        return certificates[_certificateIssuer][_family].erc20BridgeAddress;
    }
}