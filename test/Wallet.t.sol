// test/Wallet.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/Wallet.sol";

contract WalletTest is Test {
    Wallet wallet;

    // Predefined owners
    address A = address(0xA);
    address B = address(0xB);
    address C = address(0xC);
    address payable recipient = payable(address(0x1234));

    // ✅ Declare owners array at contract level
    address[] internal owners;

    function setUp() public {
        // initialize owners array once
        owners.push(A);
        owners.push(B);
        owners.push(C);

        wallet = new Wallet(owners, 2);

        // fund the wallet with 1 ether
        vm.deal(address(this), 1 ether);
        (bool ok,) = address(wallet).call{value: 1 ether}("");
        require(ok, "fund fail");
    }

    function testSubmitConfirmExecute() public {
        vm.prank(A);
        uint txId = wallet.submit(recipient, 0.2 ether, "");

        vm.prank(A);
        wallet.confirm(txId);

        vm.prank(B);
        wallet.confirm(txId);

        uint balBefore = recipient.balance;
        vm.prank(A);
        wallet.execute(txId);

        assertEq(recipient.balance, balBefore + 0.2 ether);
    }

    function testRevert_NotOwnerSubmit() public {
        vm.expectRevert(bytes("NOT_OWNER"));
        wallet.submit(recipient, 0, "");
    }

    function testRevokeFlow() public {
        vm.startPrank(A);
        uint txId = wallet.submit(recipient, 0.1 ether, "");
        wallet.confirm(txId);
        vm.stopPrank();

        vm.prank(A);
        wallet.revoke(txId);

        vm.prank(B);
        wallet.confirm(txId);

        vm.expectRevert(bytes("NOT_ENOUGH_CONFIRMS"));
        vm.prank(B);
        wallet.execute(txId);
    }
}
