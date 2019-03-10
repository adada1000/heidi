// Test the token
//
// Regular ERC20 with a double linked list of addresses that
// have a balance against them. Addresses are added at the head
// of the list and removed if balance goes to zero.
//

var ListERC20 = artifacts.require("./ListERC20.sol");

contract("ListERC20", function(accounts) {

  var HEAD = '0x0000000000000000000000000000000000000000';
  var TAIL = '0x0000000000000000000000000000000000000000';
  var NEXT = true;
  var PREV = false;

  async function iterateLinkedList(app) {
    var address = await app.list(HEAD,NEXT);
    while (address!==TAIL) {
        var balance = await app.balanceOf(address);
        console.log( "Address: " + address + " Balance: " + balance );
        address = await app.list(head,NEXT);
    }
  }

  async function getListEntry(app,n) {
    var address = await app.list(HEAD,NEXT);
    var m=1;
    while (address!==ZERO) {
        if (m===n) {
            return address;
        }
        address = await app.list(address,NEXT);
        m++;
    }
    return "NOT FOUND";
  }

  async function countList(app) {
    var n=0;
    var address = await app.list(HEAD,NEXT);
    while (address!==ZERO) {
        n++;
        address = await app.list(address,NEXT);
    }
    return n;
  }

  const creator = accounts[0];
  const account1 = accounts[1];
  const account2 = accounts[2];

  it("Initial state", async function() {

    var c = await ListERC20.deployed();

    // one entry, the account that created the token

    var listLength = countList(app);
    assert.equal(listLength, 1);     

    var entry = getListEntry(1);
    assert.equal(entry, creator );

  });


} )
