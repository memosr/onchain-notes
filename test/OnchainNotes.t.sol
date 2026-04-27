// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {OnchainNotes} from "../src/OnchainNotes.sol";

contract OnchainNotesTest is Test {
    // Mirror events from OnchainNotes so expectEmit works
    event NoteCreated(uint256 indexed noteId, address indexed owner, string title);
    event NoteUpdated(uint256 indexed noteId, address indexed owner, string title);
    event NoteDeleted(uint256 indexed noteId, address indexed owner);

    OnchainNotes public notes;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        notes = new OnchainNotes();
    }

    // -------------------------------------------------------------------------
    // createNote / getMyNotes
    // -------------------------------------------------------------------------

    function test_CreateNoteAndRetrieve() public {
        vm.prank(alice);
        uint256 id = notes.createNote("Hello", "World content");

        vm.prank(alice);
        OnchainNotes.Note[] memory myNotes = notes.getMyNotes();

        assertEq(myNotes.length, 1);
        assertEq(myNotes[0].id, id);
        assertEq(myNotes[0].owner, alice);
        assertEq(myNotes[0].title, "Hello");
        assertEq(myNotes[0].content, "World content");
        assertGt(myNotes[0].createdAt, 0);
        assertEq(myNotes[0].createdAt, myNotes[0].updatedAt);
    }

    function test_CreateNoteEmitsEvent() public {
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit NoteCreated(1, alice, "My Note");
        notes.createNote("My Note", "Some content");
    }

    // -------------------------------------------------------------------------
    // updateNote
    // -------------------------------------------------------------------------

    function test_OnlyOwnerCanUpdate() public {
        vm.prank(alice);
        uint256 id = notes.createNote("Alice Note", "content");

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(OnchainNotes.NotOwner.selector, id, bob));
        notes.updateNote(id, "Hijacked", "bad");
    }

    function test_UpdateChangesFieldsAndTimestamp() public {
        vm.warp(1000);
        vm.prank(alice);
        uint256 id = notes.createNote("Original", "old content");

        vm.warp(2000);
        vm.prank(alice);
        notes.updateNote(id, "Updated", "new content");

        vm.prank(alice);
        OnchainNotes.Note[] memory myNotes = notes.getMyNotes();
        assertEq(myNotes[0].title, "Updated");
        assertEq(myNotes[0].content, "new content");
        assertEq(myNotes[0].createdAt, 1000);
        assertEq(myNotes[0].updatedAt, 2000);
    }

    function test_UpdateEmitsEvent() public {
        vm.prank(alice);
        uint256 id = notes.createNote("Title", "content");

        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit NoteUpdated(id, alice, "New Title");
        notes.updateNote(id, "New Title", "new content");
    }

    // -------------------------------------------------------------------------
    // deleteNote
    // -------------------------------------------------------------------------

    function test_OnlyOwnerCanDelete() public {
        vm.prank(alice);
        uint256 id = notes.createNote("Alice Note", "content");

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(OnchainNotes.NotOwner.selector, id, bob));
        notes.deleteNote(id);
    }

    function test_DeletedNoteNotInGetMyNotes() public {
        vm.prank(alice);
        notes.createNote("Note 1", "content 1");
        vm.prank(alice);
        uint256 id2 = notes.createNote("Note 2", "content 2");
        vm.prank(alice);
        notes.createNote("Note 3", "content 3");

        vm.prank(alice);
        notes.deleteNote(id2);

        vm.prank(alice);
        OnchainNotes.Note[] memory myNotes = notes.getMyNotes();
        assertEq(myNotes.length, 2);
        assertEq(myNotes[0].title, "Note 1");
        assertEq(myNotes[1].title, "Note 3");
    }

    function test_DeleteEmitsEvent() public {
        vm.prank(alice);
        uint256 id = notes.createNote("Title", "content");

        vm.prank(alice);
        vm.expectEmit(true, true, false, false);
        emit NoteDeleted(id, alice);
        notes.deleteNote(id);
    }

    function test_CannotUpdateDeletedNote() public {
        vm.prank(alice);
        uint256 id = notes.createNote("Title", "content");
        vm.prank(alice);
        notes.deleteNote(id);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(OnchainNotes.NoteAlreadyDeleted.selector, id));
        notes.updateNote(id, "New", "new content");
    }

    function test_CannotDeleteTwice() public {
        vm.prank(alice);
        uint256 id = notes.createNote("Title", "content");
        vm.prank(alice);
        notes.deleteNote(id);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(OnchainNotes.NoteAlreadyDeleted.selector, id));
        notes.deleteNote(id);
    }

    // -------------------------------------------------------------------------
    // Title / content validation
    // -------------------------------------------------------------------------

    function test_RevertEmptyTitle() public {
        vm.prank(alice);
        vm.expectRevert(OnchainNotes.EmptyTitle.selector);
        notes.createNote("", "content");
    }

    function test_RevertTitleTooLong() public {
        string memory longTitle = _repeat("a", 101);
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(OnchainNotes.TitleTooLong.selector, 101, notes.MAX_TITLE_LENGTH())
        );
        notes.createNote(longTitle, "content");
    }

    function test_AcceptsMaxLengthTitle() public {
        string memory maxTitle = _repeat("a", 100);
        vm.prank(alice);
        notes.createNote(maxTitle, "content");
    }

    function test_RevertContentTooLong() public {
        string memory longContent = _repeat("a", 2001);
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                OnchainNotes.ContentTooLong.selector, 2001, notes.MAX_CONTENT_LENGTH()
            )
        );
        notes.createNote("Title", longContent);
    }

    function test_AcceptsEmptyContent() public {
        vm.prank(alice);
        notes.createNote("Title", "");
    }

    function test_AcceptsMaxLengthContent() public {
        string memory maxContent = _repeat("a", 2000);
        vm.prank(alice);
        notes.createNote("Title", maxContent);
    }

    // -------------------------------------------------------------------------
    // Multiple users have separate notes
    // -------------------------------------------------------------------------

    function test_UsersHaveSeparateNotes() public {
        vm.prank(alice);
        notes.createNote("Alice Note", "alice content");

        vm.prank(bob);
        notes.createNote("Bob Note", "bob content");

        vm.prank(alice);
        OnchainNotes.Note[] memory aliceNotes = notes.getMyNotes();
        vm.prank(bob);
        OnchainNotes.Note[] memory bobNotes = notes.getMyNotes();

        assertEq(aliceNotes.length, 1);
        assertEq(aliceNotes[0].title, "Alice Note");

        assertEq(bobNotes.length, 1);
        assertEq(bobNotes[0].title, "Bob Note");
    }

    function test_GetNoteCountReflectsActiveNotes() public {
        vm.prank(alice);
        notes.createNote("Note 1", "c1");
        vm.prank(alice);
        uint256 id2 = notes.createNote("Note 2", "c2");
        vm.prank(alice);
        notes.createNote("Note 3", "c3");

        assertEq(notes.getNoteCount(alice), 3);

        vm.prank(alice);
        notes.deleteNote(id2);

        assertEq(notes.getNoteCount(alice), 2);
        assertEq(notes.getNoteCount(bob), 0);
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    function _repeat(string memory char, uint256 times) internal pure returns (string memory) {
        bytes memory result = new bytes(times);
        bytes memory charBytes = bytes(char);
        for (uint256 i; i < times; ++i) {
            result[i] = charBytes[0];
        }
        return string(result);
    }
}
