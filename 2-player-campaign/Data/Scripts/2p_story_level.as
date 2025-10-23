// 2p_story_level.as - Multiplayer-aware level script for 2-player campaign
// Scaffolding based on versusmode.as sync patterns

#include "music_load.as"

// Multiplayer state handles
enum SyncStates {
    SYNC_OBJECTIVES = 0,
    SYNC_DIALOGUE = 1
}
int sync_objectives_state = -1;
int sync_dialogue_state = -1;

void Init(string level_name) {
    RegisterMPCallBacks();
    // Add any level-specific initialization here
}

void RegisterMPCallBacks() {
    sync_objectives_state = Online_RegisterState("2pStoryObjectives");
    Online_RegisterStateCallback(sync_objectives_state, "void OnObjectivesSync(array<uint8>& data)");
    sync_dialogue_state = Online_RegisterState("2pStoryDialogue");
    Online_RegisterStateCallback(sync_dialogue_state, "void OnDialogueSync(array<uint8>& data)");
}

void OnObjectivesSync(array<uint8>& data) {
    // TODO: Unpack and apply synced objectives state
}

void OnDialogueSync(array<uint8>& data) {
    // TODO: Unpack and apply synced dialogue state
}

void SyncObjectives(array<uint8>& data) {
    if(Online_IsHosting()) {
        Online_AddSyncState(sync_objectives_state, data);
        Online_SendState(sync_objectives_state, data);
    }
}

void SyncDialogue(array<uint8>& data) {
    if(Online_IsHosting()) {
        Online_AddSyncState(sync_dialogue_state, data);
        Online_SendState(sync_dialogue_state, data);
    }
}


void Update() {
    // Multiplayer-safe update: run logic for both host and joiner
    if(Online_IsActive()) {
        // In multiplayer, process input and movement for all local players
        int num_chars = GetNumCharacters();
        for(int i=0; i<num_chars; ++i) {
            MovementObject@ char = ReadCharacter(i);
            if(char.controlled) {
                // Let the engine handle input/movement for this player
                // (No-op: engine already does this, but you can add per-player logic here if needed)
            }
        }
    } else {
        // Singleplayer: default behavior
        // (No-op: engine handles everything)
    }
}

void ReceiveMessage(string msg) {
    // TODO: Handle cross-script messages, possibly sync important events
}

void DrawGUI() {
    // TODO: Draw multiplayer-aware HUD if needed
}

// Add more multiplayer-aware logic as needed
