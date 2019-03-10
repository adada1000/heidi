// MS: Test the crowdsale system
//
// admin: 1. deploy CreateCrowdsale.sol CC (truffle migrate) 
//        2. deploy RewardTokenFactory RTF (truffle migrate)
//
// rights issuer: 1. calls CC.createCrowdsale -> deploys contracts: Crowdsale C, ListERC20 R (emitted in event)
//               
// rights investor: 1. approves DAI to Crowdsale contract
//                  2. calls C.buy
// 
// If Crowdsale suceeds:
//
// rights issuer: 1. C.checkGoalReached
//                2. C.safeWithdraw -> All DAI moved to issuer address             
// 
// If Crowdsale fails:
//
// rights investor: 1. C.checkGoalReached
//                  2. C.safeWithdaw -> Investors withdraw DAI  
//


const RTF = artifacts.require("RewardTokenFactory");
const CC = artifacts.require("CreateCrowdsale");
const DAI = artifacts.require("DSToken");

var rtf;
var cc;
var dai;


async function getFixedContracts() {
  console.log("getting fixed contracts...");
  rtf = await RTF.at('0xA60a855A34B679392f6B0316F00FC6A864968598');
  cc = await CC.at('0x8E552a8392BaD78d3A31bee915a942dBBAea03E2');
  dai = await DAI.at('0xD0fC300fAa2d474cae17B3A0045204dE093152Fb');
  console.log("got fixed contracts");
}

contract("Crowdsale system", function(accounts) {

  const admin = accounts[0];
  const issuer = accounts[1];
  const investor1 = accounts[2];
  const investor2 = accounts[3];

  var investor1_bal;
  var investor2_bal;

  const fundDaiAmt = web3.utils.toWei('5000');

  // investors require dai

  it("Fund investor 1", async function() {

       await getFixedContracts();
       console.log("moving on...");

       dai.mint( investor1, fundDaiAmt, {from:admin} )
        .then( () => {
          return dai.balanceOf.call( investor1 ); 
        })
        .then( balance => {
          investor1_bal = balance;
          console.log("Investor 1 funded, balance: "+investor1_bal);
        });

  }); //it

/*
  const totalTokens = web3.utils.toWei('1000');
  const saleTokens = web3.utils.toWei('200');
  const costOfEachToken = web3.utils.toWei('1.1');

  var durationInMinutes = 10; 
  var name = "Test Test Test Test Test Test Test Test Test Test.";
  var symbol = "TEST_SYMBOL";

  it("Issuer creates crowdsale", function() {

    let cc;
    let rtf;

    return CC.deployed()
      .then( instance => {
        cc = instance;
        return RTF.deployed()
      }).then( instance => {
          rtf = instance;
          return cc.createCrowdsale( totalTokens, saleTokens, costOfEachToken, durationInMinutes, rtf.address, name, symbol, dai.address )
      }).then( r => {
          console.log(r);
          var e = r.logs[ r.logs.length-1 ].event;
          console.log( e );
      });
 
    //var rtf = await RTF.deployed();

    //cc.createCrowdsale( totalTokens, saleTokens, costOfEachToken, durationInMinutes, rtf.address, name, symbol, dai.address ).then( r => {

      // last event has the crowdsale and rewardToken
      //var e = r.logs[ r.logs.length-1 ].event;
 
      //console.log( e );

    //});

    // one entry, the account that created the token

    //var entry = getListEntry(1);
    //assert.equal(entry, creator );

  });  //it
*/

} )
