const AwesomeCertificates = artifacts.require("AwesomeCertificates");
const AwesomeCertificatesGasToken = artifacts.require(
  "AwesomeCertificatesGasToken"
);

const { utils } = require("ethers");

contract("Awesome Certificates", accounts => {
  const [firstAccount] = accounts;

  let gasTokenContractAddress;

  it("should deploy a gas token", async () => {
    const awesomeGasToken = await AwesomeCertificatesGasToken.new(
      "awesome gas token",
      "AGT",
      5,
      1000
    );
    gasTokenContractAddress = awesomeGasToken.address;
    assert.equal(utils.isHexString(awesomeGasToken.address), true);
  });

  it("should create a contract instance", async () => {
    const awesomeCertificates = await AwesomeCertificates.new(
      gasTokenContractAddress
    );
    assert.equal(await awesomeCertificates.owner.call(), firstAccount);
  });
});
