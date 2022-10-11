const {ethers} = require("hardhat")
const {expect} = require("chai")

describe("ABI-Optimized-Dex" , ()=> {
    let dex, interpreter, token0, token1
    let signer
    beforeEach(async ()=>{
        const Token0 = await ethers.getContractFactory("a")
        const Token1 = await ethers.getContractFactory("b")
        token0 = await Token0.deploy()
        token1 = await Token1.deploy()

        const Dex = await ethers.getContractFactory("Dex")
        const Interpreter = await ethers.getContractFactory("callDataInterpreter")
        interpreter = await Interpreter.deploy()
        dex = await Dex.deploy(interpreter.address, token0.address, token1.address)

        // allowances
        await (await token0.approve(dex.address,500)).wait()
        await (await token1.approve(dex.address,500)).wait()

        signer = await ethers.getSigner()
    })

    it("Should be able to deposit liquidity in the dex", async ()=>{
        const addLiquidityTx = {
            to:interpreter.address,
            data:"0x02" + "0100" + "0100"
        }
        try{
            await (await signer.sendTransaction(addLiquidityTx)).wait()
        }catch(e){
            console.log("CALL FAILED!")
        }
        expect (await token0.balanceOf(interpreter.address)).to.be.greaterThan(0)
    })
})
