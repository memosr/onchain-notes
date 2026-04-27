// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract OnchainNotes {
    // -------------------------------------------------------------------------
    // Types
    // -------------------------------------------------------------------------

    struct Note {
        uint256 id;
        address owner;
        string title;
        string content;
        uint256 createdAt;
        uint256 updatedAt;
    }

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    uint256 private _nextId = 1;

    // noteId => Note
    mapping(uint256 => Note) private _notes;

    // noteId => deleted flag
    mapping(uint256 => bool) private _deleted;

    // owner => list of noteIds they created
    mapping(address => uint256[]) private _userNoteIds;

    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    error NotOwner(uint256 noteId, address caller);
    error NoteAlreadyDeleted(uint256 noteId);
    error TitleTooLong(uint256 length, uint256 max);
    error ContentTooLong(uint256 length, uint256 max);
    error EmptyTitle();

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    event NoteCreated(uint256 indexed noteId, address indexed owner, string title);
    event NoteUpdated(uint256 indexed noteId, address indexed owner, string title);
    event NoteDeleted(uint256 indexed noteId, address indexed owner);

    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------

    uint256 public constant MAX_TITLE_LENGTH = 100;
    uint256 public constant MAX_CONTENT_LENGTH = 2000;

    // -------------------------------------------------------------------------
    // Write functions
    // -------------------------------------------------------------------------

    function createNote(string calldata title, string calldata content)
        external
        returns (uint256 noteId)
    {
        _validateTitle(title);
        _validateContent(content);

        noteId = _nextId++;
        _notes[noteId] = Note({
            id: noteId,
            owner: msg.sender,
            title: title,
            content: content,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });
        _userNoteIds[msg.sender].push(noteId);

        emit NoteCreated(noteId, msg.sender, title);
    }

    function updateNote(uint256 noteId, string calldata title, string calldata content) external {
        _requireOwner(noteId);
        _requireNotDeleted(noteId);
        _validateTitle(title);
        _validateContent(content);

        Note storage note = _notes[noteId];
        note.title = title;
        note.content = content;
        note.updatedAt = block.timestamp;

        emit NoteUpdated(noteId, msg.sender, title);
    }

    function deleteNote(uint256 noteId) external {
        _requireOwner(noteId);
        _requireNotDeleted(noteId);

        _deleted[noteId] = true;

        emit NoteDeleted(noteId, msg.sender);
    }

    // -------------------------------------------------------------------------
    // Read functions
    // -------------------------------------------------------------------------

    function getMyNotes() external view returns (Note[] memory) {
        return _getActiveNotes(msg.sender);
    }

    function getNoteCount(address user) external view returns (uint256 count) {
        uint256[] storage ids = _userNoteIds[user];
        for (uint256 i; i < ids.length; ++i) {
            if (!_deleted[ids[i]]) ++count;
        }
    }

    // -------------------------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------------------------

    function _getActiveNotes(address user) internal view returns (Note[] memory) {
        uint256[] storage ids = _userNoteIds[user];
        uint256 activeCount;
        for (uint256 i; i < ids.length; ++i) {
            if (!_deleted[ids[i]]) ++activeCount;
        }

        Note[] memory result = new Note[](activeCount);
        uint256 idx;
        for (uint256 i; i < ids.length; ++i) {
            if (!_deleted[ids[i]]) {
                result[idx++] = _notes[ids[i]];
            }
        }
        return result;
    }

    function _requireOwner(uint256 noteId) internal view {
        if (_notes[noteId].owner != msg.sender) revert NotOwner(noteId, msg.sender);
    }

    function _requireNotDeleted(uint256 noteId) internal view {
        if (_deleted[noteId]) revert NoteAlreadyDeleted(noteId);
    }

    function _validateTitle(string calldata title) internal pure {
        uint256 len = bytes(title).length;
        if (len == 0) revert EmptyTitle();
        if (len > MAX_TITLE_LENGTH) revert TitleTooLong(len, MAX_TITLE_LENGTH);
    }

    function _validateContent(string calldata content) internal pure {
        uint256 len = bytes(content).length;
        if (len > MAX_CONTENT_LENGTH) revert ContentTooLong(len, MAX_CONTENT_LENGTH);
    }
}
