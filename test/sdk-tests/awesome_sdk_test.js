const expect = require("chai").expect;
const AwesomeCertificatesSdk = require("../../dist/index")
  .AwesomeCertificatesSdk;

describe("Awesome Sdk test", async () => {
  it("should initialize an sdk instance", async () => {
    const awesomeCertificatesSdk = new AwesomeCertificatesSdk();
  });
});
