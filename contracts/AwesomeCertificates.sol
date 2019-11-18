pragma solidity 0.5.11;

import "../node_modules/@openzeppelin/contracts-ethereum-package/contracts/GSN/GSNRecipient.sol";
import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract AwesomeCertificates is GSNRecipient {
    address owner;
    IERC20 public awesomeCertificatesGasTokenContractInstance;

    // Issuer => certficate entropy / family => owner => quantity
    mapping(address => mapping(bytes32 => mapping(address => uint))) public certificates;

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

    // Constructor

    constructor(address _awesomeCertificatesGasTokenContractAddress) public {
        owner = _msgSender();
        awesomeCertificatesGasTokenContractInstance = IERC20(_awesomeCertificatesGasTokenContractAddress);
    }

    // Modifiers

    modifier doesCertificateFamilyExist(address _issuer ,bytes32 _familyEntropy) {
        require(
            certificates[_issuer][_familyEntropy][address(0)] > 0,
            "Certificates family with the given entropy already exist"
            );
        _;
    }

    modifier isOwner() {
        require(_msgSender() == owner, "This method can be called only by the contract owner");
        _;
    }

    modifier isQuantitySufficientToTransfer(
        address _certificateIssuer,
        bytes32 _family,
        address _sender,
        uint _transferedQuantity
    ) {
        require(
            certificates[_certificateIssuer][_family][_sender] >= _transferedQuantity,
            "You can't transfer more certificates than you have"
        );
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
    doesCertificateFamilyExist(_certificateIssuer, _family)
    isQuantitySufficientToTransfer(_certificateIssuer, _family, _from, _quantity)
    {
        certificates[_certificateIssuer][_family][_from] -= _quantity;
        certificates[_certificateIssuer][_family][_to] += _quantity;
        emit CertficateTransfer(_certificateIssuer, _family, _from, _to, _quantity);
    }

    // Issuers methods

    function registerCertificatesFamily(bytes32 _familyEntropy) public
    doesCertificateFamilyExist(_msgSender(), _familyEntropy)
    {
        certificates[_msgSender()][_familyEntropy][address(0)]++;
        emit NewCertficateFamilyRegistered(_msgSender(), _familyEntropy);
    }

    function assignCertificate(bytes32 _family, address _to, uint _quantity) public
    doesCertificateFamilyExist(_msgSender(), _family)
    {
        certificates[_msgSender()][_family][_to] += _quantity;
        emit CertificateIssued(_msgSender(), _family, _to, _quantity);
    }

    // Certficates owners methods

    function allowSpending(
        address _certificateIssuer,
        bytes32 _family,
        uint _quantity,
        address _whom
    ) public
    doesCertificateFamilyExist(_certificateIssuer, _family)
    isQuantitySufficientToTransfer(_certificateIssuer, _family, _msgSender(), _quantity)
    {

    }

    function transfer(address _certificateIssuer, bytes32 _family, address _to, uint _quantity) public
    doesCertificateFamilyExist(_certificateIssuer, _family)
    isQuantitySufficientToTransfer(_certificateIssuer, _family, _msgSender(), _quantity)
    {
        _transfer(_certificateIssuer, _family, _msgSender(), _to, _quantity);
    }

}