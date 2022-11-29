const ERC20 = artifacts.require("ERC20");

contract("ERC20 Testing Part -1 ", (accounts) => {
  let instance = null;
  before(async () => {
    instance = await ERC20.deployed();
  });

  it("Checking for Token Basic Info", async () => {
    const name = await instance.name();
    const info = await instance.asset();
    const Supply = await instance.totalSupply();
    const decimals = await instance.decimals();
    assert(name === "HDA Token");
    assert(info === "Reals Estate");
    assert(Supply.toNumber() === 400000);
    assert(decimals.toNumber() === 18);
  });

  it("Checking for issuerAddress", async () => {
    const issuerAddress = await instance.issuer();
    assert(issuerAddress === accounts[0]);
  });
  it("Checking for registrarAddress", async () => {
    const registrarAddress = await instance.registrar();
    assert(registrarAddress === accounts[1]);
  });

  let contractBalance;
  it("Checking Balance and Contract Balance", async () => {
    contractBalance = await instance.checkBalance();

    const balanceArray = await instance.checkBalanceforIsuuerorRegisterar(
      accounts[0] // issuer account
    );
    assert(contractBalance.toNumber() === balanceArray.toNumber());
  });

  let statusIspaused;
  it("Checking for Contract Paused Status", async () => {
    statusIspaused = await instance.isPaused();
    assert(statusIspaused === true);
  });

  // here accounts[2] are users
  let FinalStatus;
  it("Checking WhiteListing Accounts", async () => {
    const issuerAddress = await instance.issuer();
    // here issuer can't use their wallet to send money
    assert(issuerAddress != accounts[2]);
    // Checking for new account is WhiteListed default it should be false
    const intialStatus = await instance.isWhitelisted(accounts[2]);
    assert(intialStatus == false);
    const WhiteListingAccount = await instance.addToWhitelist(accounts[2]);
    const statusforWhiteListing = WhiteListingAccount.receipt.status;
    FinalStatus = await instance.isWhitelisted(accounts[2]);
    assert(FinalStatus === statusforWhiteListing);
  });

  it("Checking changing paused true to false ", async () => {
    const unpauseContract = await instance.unpauseContract();
    assert(unpauseContract.receipt.status === true);
    statusIspaused = await instance.isPaused();
    assert(statusIspaused === false);
  });

  const amount = 100;
  it("Check Transferring Token from Issuer ", async () => {
    const transferringToken = await instance.transferFromIssuer(
      accounts[2],
      amount
    );
    assert(transferringToken.receipt.status === true);
  });

  it("Checking Balance of Issuer ", async () => {
    const IssuerSupply = await instance.checkBalanceforIsuuerorRegisterar(
      accounts[0]
    );
    assert(IssuerSupply.toNumber() + amount == contractBalance.toNumber());
  });

  const extraTokenSupply = 100;
  let newTotalSupply;

  it("Checking Miniting Token", async () => {
    const BeforeMintSupply = await instance.totalSupply();
    const mintStatus = await instance.mint(extraTokenSupply);
    assert(mintStatus.receipt.status === true);

    newTotalSupply = await instance.totalSupply();
    assert(
      BeforeMintSupply.toNumber() + extraTokenSupply ===
        newTotalSupply.toNumber()
    );
  });

  it("Checking Burn Token", async () => {
    const burnStatus = await instance.burn(extraTokenSupply);
    assert(burnStatus.receipt.status === true);

    const afterBurnSupply = await instance.totalSupply();
    assert(
      afterBurnSupply.toNumber() ===
        newTotalSupply.toNumber() - extraTokenSupply
    );
  });

  //  Whitelisting account then added allowance and decrease allowance and check with
  //   _allowed array values the transfer to customer and transfer as token

  it("Checking Removing Accounts from WhiteList", async () => {
    await instance.addToWhitelist(accounts[3]);
    const statusForRemoval = await instance.removeFromWhitelist(accounts[3]);
    const isWhitelisted = await instance.isWhitelisted(accounts[3]);
    assert(!isWhitelisted === statusForRemoval.receipt.status);
  });
});

contract("ERC20 Testing PART - 2 ", (accounts) => {
  let instance = null;
  before(async () => {
    instance = await ERC20.deployed();
  });

  //  Checking intital Allowance should be zero

  it("Checking Intial Allowance", async () => {
    const allowanceIntital = await instance.allowanceOf(
      accounts[0],
      accounts[1]
    );
    assert(allowanceIntital.toNumber() === 0);
  });

  //  whitelisting account and sending some token checking for allowance updation
  let extraAllowance = 150;
  it("Checking Increase Allowance", async () => {
    const whitelistingStatus = await instance.addToWhitelist(accounts[1]);
    assert(whitelistingStatus);

    const addingAllowanceStatus = await instance.increaseAllowance(
      accounts[0],
      accounts[1],
      extraAllowance
    );
    assert(addingAllowanceStatus);

    const newAllowance = await instance.allowanceOf(accounts[0], accounts[1]);
    assert(newAllowance.toNumber() === extraAllowance);
  });

  let decreaseAllowanceAmount = 50;
  it("Checking Decrease Allowance", async () => {
    const status = await instance.decreaseAllowance(
      accounts[0],
      accounts[1],
      decreaseAllowanceAmount
    );
    assert(status);
    const Currentallowance = await instance.allowanceOf(
      accounts[0],
      accounts[1]
    );
    assert(Currentallowance.toNumber() === 100);
  });

  let customerAllowance;
  it("Checking customerAllowance", async () => {
    customerAllowance = await instance.customerAllowance(accounts[1]);
    assert(customerAllowance.toNumber() === 100);
  });

  const tokens = 10;
  it("Checking transferForCustomer", async () => {
    await instance.unpauseContract();
    //  Tranferring 10 token to accounts[1] address
    const transfer = await instance.transferForCustomer(accounts[1], tokens);
    //  checking for status of payment
    assert(transfer.receipt.status);

    //  then checking for customerAllowance
    const currentAllowance = await instance.customerAllowance(accounts[1]);
    assert(currentAllowance.toNumber() + tokens === 100);
  });

  //  here transferring 100 tokens to accounts 2
  const tokensfrom = 100;
  it("Checking transferTokenAsIssuer", async () => {
    //  whitelisting accounts
    const statusforWhiteListing = await instance.addToWhitelist(accounts[2]);
    assert(statusforWhiteListing);

    //  contract is already paused
    const isPaused = await instance.isPaused();
    assert(!isPaused);

    //  adding intital allowance to accounts 2 from issuer address
    const statusAllowance = await instance.increaseAllowance(
      accounts[0],
      accounts[2],
      tokensfrom
    );
    assert(statusAllowance.receipt.status);

    const statusTransfer = await instance.transferTokenAsIssuer(
      accounts[0],
      accounts[2],
      tokensfrom
    );

    assert(statusTransfer.receipt.status);
  });

  //  later checking balance of issuer and total supply

  it("Balance of issuer checking after transferring of tokens ", async () => {
    const CurrentBalance = await instance.checkBalanceforIsuuerorRegisterar(
      accounts[0]
    );
    const totalSupply = await instance.totalSupply();
    assert(
      CurrentBalance.toNumber() + tokens + tokensfrom === totalSupply.toNumber()
    );
  });
});
