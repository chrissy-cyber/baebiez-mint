const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BAEBIEZ", function () {
  async function deployFixture() {
    const [owner, minter] = await ethers.getSigners();
    const BaeBiez = await ethers.getContractFactory("BAEBIEZ");
    const baebiez = await BaeBiez.deploy();
    await baebiez.waitForDeployment();
    return { baebiez, owner, minter };
  }

  function allowlistRoot(address) {
    return ethers.solidityPackedKeccak256(["address"], [address]);
  }

  it("accounts for the 919 tokens minted before this contract", async function () {
    const { baebiez } = await deployFixture();

    expect(await baebiez.PRIOR_MINTED()).to.equal(919);
    expect(await baebiez.totalMinted()).to.equal(919);
    expect(await baebiez.mintedOnThisContract()).to.equal(0);
    expect(await baebiez.totalRemaining()).to.equal(3525);
  });

  it("starts new contract minting at token 920", async function () {
    const { baebiez, minter } = await deployFixture();

    await baebiez.setPhase(3);
    await baebiez.connect(minter).publicMint(1, { value: ethers.parseEther("99") });

    expect(await baebiez.ownerOf(920)).to.equal(minter.address);
    expect(await baebiez.totalMinted()).to.equal(920);
    expect(await baebiez.mintedOnThisContract()).to.equal(1);
    expect(await baebiez.totalRemaining()).to.equal(3524);
  });

  it("airdrops multiple quantities and reports collection supply correctly", async function () {
    const { baebiez, owner, minter } = await deployFixture();

    await baebiez.bulkAirdrop([owner.address, minter.address], [2, 3]);

    expect(await baebiez.ownerOf(920)).to.equal(owner.address);
    expect(await baebiez.ownerOf(921)).to.equal(owner.address);
    expect(await baebiez.ownerOf(922)).to.equal(minter.address);
    expect(await baebiez.ownerOf(924)).to.equal(minter.address);
    expect(await baebiez.totalMinted()).to.equal(924);
    expect(await baebiez.mintedOnThisContract()).to.equal(5);
  });

  it("enforces the GTD 20 mint wallet limit", async function () {
    const { baebiez, minter } = await deployFixture();

    await baebiez.setGTDMerkleRoot(allowlistRoot(minter.address));
    await baebiez.setPhase(1);
    await baebiez.connect(minter).gtdMint(20, [], { value: ethers.parseEther("620") });

    await expect(
      baebiez.connect(minter).gtdMint(1, [], { value: ethers.parseEther("31") })
    ).to.be.revertedWith("Exceeds GTD wallet limit");
  });

  it("enforces the FCFS 20 mint wallet limit", async function () {
    const { baebiez, minter } = await deployFixture();

    await baebiez.setFCFSMerkleRoot(allowlistRoot(minter.address));
    await baebiez.setPhase(2);
    await baebiez.connect(minter).fcfsMint(20, [], { value: ethers.parseEther("620") });

    await expect(
      baebiez.connect(minter).fcfsMint(1, [], { value: ethers.parseEther("31") })
    ).to.be.revertedWith("Exceeds FCFS wallet limit");
  });

  it("enforces the public 50 mint wallet limit", async function () {
    const { baebiez, minter } = await deployFixture();

    await baebiez.setPhase(3);
    await baebiez.connect(minter).publicMint(50, { value: ethers.parseEther("4950") });

    await expect(
      baebiez.connect(minter).publicMint(1, { value: ethers.parseEther("99") })
    ).to.be.revertedWith("Exceeds public wallet limit");
  });
});
