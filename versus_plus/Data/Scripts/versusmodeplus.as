#include "ui_effects.as"
#include "music_load.as"

MusicLoad ml("Data/Music/challengelevel.xml");

int controller_id = 0;
float time = 0.0f;
int score_left = 0;
int score_right = 0;
int update_score_state = -1;
float reset_timer = 2.0f;
float end_game_delay = 0.0f;
int alive_state = -1;
int sync_state = -1;
int num_alive_team_turner = 1;
int num_alive_team_guard = 1;
int last_remote_reset_flag = -1; // -1 indicates we have not yet received a sync packet

bool waiting_for_players = true; // Flips to false once we have players on both teams

void Init(string p_level_name) {
    versus_gui.Init();
    PlaySong("challengelevel_ambient-tense");
}

bool HasFocus(){
    return false;
}

void ReceiveMessage(string msg) {
    TokenIterator token_iter;
    token_iter.Init();
    if(!token_iter.FindNextToken(msg)){
        return;
    }
    string token = token_iter.GetToken(msg);
    if(token == "reset"){
        time = 0.0f;
        reset_timer = 2.0f;
    } else if(token == "manual_reset"){
        ClearVersusScores();
    }
}

void DrawGUI() {
    versus_gui.DrawGUI();
}

class VersusGUI_ScoreMark {
    bool mirrored;
    bool lit;
    float scale_mult;
};

class VersusGUI {
    float player_one_win_alpha;
    float player_two_win_alpha;
    float blackout_amount;
    float score_change_time;
    array<VersusGUI_ScoreMark> right_score_marks;
    array<VersusGUI_ScoreMark> left_score_marks;

    VersusGUI(){
        right_score_marks.resize(5);
        left_score_marks.resize(5);
    }
    
    void Init() {
        player_one_win_alpha = 0.0f;
        player_two_win_alpha = 0.0f;
        blackout_amount = 0.0f;
        score_change_time = 0.0f;
        
        for(int i=0; i<5; ++i){
            right_score_marks[i].mirrored = false;
            right_score_marks[i].lit = false;
            right_score_marks[i].scale_mult = 1.0f;
        }
        
        for(int i=0; i<5; ++i){
            left_score_marks[i].mirrored = true;
            left_score_marks[i].lit = false;
            left_score_marks[i].scale_mult = 1.0f;
        }
    }

    void Update(){
        for(int i=0; i<5; ++i){
            if(right_score_marks[i].lit){
                right_score_marks[i].scale_mult = mix(1.0f, right_score_marks[i].scale_mult, 0.9f);
            } else {
                right_score_marks[i].scale_mult = mix(0.0f, right_score_marks[i].scale_mult, 0.9f);
            }
        }
        for(int i=0; i<5; ++i){
            if(left_score_marks[i].lit){
                left_score_marks[i].scale_mult = mix(1.0f, left_score_marks[i].scale_mult, 0.9f);
            } else {
                left_score_marks[i].scale_mult = mix(0.0f, left_score_marks[i].scale_mult, 0.9f);
            }
        }
    }
    
    void DrawGUI(){
        float ui_scale = GetScreenWidth() / 2560.0f;
        
        HUDImage @top_crete_image = hud.AddImage();
        top_crete_image.SetImageFromPath("Data/Textures/ui/versus_mode/top_crete.tga");
        top_crete_image.position.y = GetScreenHeight() - 256 * ui_scale;
        top_crete_image.position.x = GetScreenWidth() * 0.5 - 1024 * ui_scale;
        top_crete_image.scale = vec3(ui_scale);
        
        HUDImage @left_portrait_image = hud.AddImage();
        left_portrait_image.SetImageFromPath("Data/Textures/ui/versus_mode/rabbit_1_portrait.tga");
        left_portrait_image.position.y = GetScreenHeight() - 512 * ui_scale * 0.6f;
        left_portrait_image.position.x = GetScreenWidth() * 0.5 - 850 * ui_scale;
        left_portrait_image.position.z = 1.0f;
        left_portrait_image.scale = vec3(ui_scale * 0.6f);
        
        HUDImage @right_portrait_image = hud.AddImage();
        right_portrait_image.SetImageFromPath("Data/Textures/ui/versus_mode/rabbit_2_portrait.tga");
        right_portrait_image.position.y = GetScreenHeight() - 512 * ui_scale * 0.6f;
        right_portrait_image.position.x = GetScreenWidth() * 0.5 + 530 * ui_scale;
        right_portrait_image.position.z = 1.0f;
        right_portrait_image.scale = vec3(ui_scale * 0.6f);
        
        HUDImage @left_vignette_image = hud.AddImage();
        left_vignette_image.SetImageFromPath("Data/Textures/ui/versus_mode/corner_vignette.tga");
        left_vignette_image.position.y = GetScreenHeight() - 256 * ui_scale * 2.0f;
        left_vignette_image.position.x = 0.0f;
        left_vignette_image.position.z = -1.0f;
        left_vignette_image.scale = vec3(ui_scale * 2.0f);
        
        HUDImage @right_vignette_image = hud.AddImage();
        right_vignette_image.SetImageFromPath("Data/Textures/ui/versus_mode/corner_vignette.tga");
        right_vignette_image.position.y = GetScreenHeight() - 256 * ui_scale * 2.0f;
        right_vignette_image.position.x = GetScreenWidth();
        right_vignette_image.position.z = -1.0f;
        right_vignette_image.scale = vec3(ui_scale * 2.0f);
        right_vignette_image.scale.x *= -1.0f;
        
        HUDImage @blackout_image = hud.AddImage();
        blackout_image.SetImageFromPath("Data/Textures/diffuse.tga");
        blackout_image.position.y = (GetScreenWidth() + GetScreenHeight())*-1.0f;
        blackout_image.position.x = (GetScreenWidth() + GetScreenHeight())*-1.0f;
        blackout_image.position.z = -2.0f;
        blackout_image.scale = vec3(GetScreenWidth() + GetScreenHeight())*2.0f;
        blackout_image.color = vec4(0.0f,0.0f,0.0f,blackout_amount);
        
        HUDImage @blackout_over_image = hud.AddImage();
        blackout_over_image.SetImageFromPath("Data/Textures/diffuse.tga");
        blackout_over_image.position.y = 0;
        blackout_over_image.position.x = 0;
        blackout_over_image.position.z = 2.0f;
        blackout_over_image.scale = vec3(GetScreenWidth() + GetScreenHeight());
        blackout_over_image.color = vec4(0.0f,0.0f,0.0f,max(player_one_win_alpha,player_two_win_alpha)*0.5f);
        
        HUDImage @player_one_win_image = hud.AddImage();
        player_one_win_image.SetImageFromPath("Data/Textures/ui/versus_mode/rabbit_1_win.tga");
        float player_one_scale = 1.5f + sin(player_one_win_alpha*1.570796f) * 0.2f;
        player_one_win_image.position.y = GetScreenHeight() * 0.5 - 512 * ui_scale * player_one_scale;
        player_one_win_image.position.x = GetScreenWidth() * 0.5 - 512 * ui_scale * player_one_scale;
        player_one_win_image.position.z = 3.0f;
        player_one_win_image.scale = vec3(ui_scale * player_one_scale);
        player_one_win_image.color.a = player_one_win_alpha;
        
        HUDImage @player_two_win_image = hud.AddImage();
        player_two_win_image.SetImageFromPath("Data/Textures/ui/versus_mode/rabbit_2_win.tga");
        float player_two_scale = 1.5f + sin(player_two_win_alpha*1.570796f) * 0.2f;
        player_two_win_image.position.y = GetScreenHeight() * 0.5 - 512 * ui_scale * player_two_scale;
        player_two_win_image.position.x = GetScreenWidth() * 0.5 - 512 * ui_scale * player_two_scale;
        player_two_win_image.position.z = 3.0f;
        player_two_win_image.scale = vec3(ui_scale * player_two_scale);
        player_two_win_image.color.a = player_two_win_alpha;
        
        for(int i=0; i<5; ++i){
            float special_scale = 1.0f;
            HUDImage @hud_image = hud.AddImage();
            hud_image.SetImageFromPath("Data/Textures/ui/versus_mode/match_mark.tga");
            hud_image.position.y = GetScreenHeight() - (122 + 128 * special_scale) * ui_scale;
            hud_image.position.x = GetScreenWidth() * 0.5 + (498 - 128 * special_scale) * ui_scale - i * 90 * ui_scale;
            hud_image.scale = vec3(ui_scale * 0.6f * special_scale);
            special_scale = right_score_marks[i].scale_mult;
            HUDImage @glow_image = hud.AddImage();
            glow_image.SetImageFromPath("Data/Textures/ui/versus_mode/match_win.tga");
            glow_image.position.y = GetScreenHeight() - (122 + 128 * special_scale) * ui_scale;
            glow_image.position.z = 0.1f;
            glow_image.position.x = GetScreenWidth() * 0.5 + (498 - 128 * special_scale) * ui_scale - i * 90 * ui_scale;
            glow_image.scale = vec3(ui_scale * 0.6f * special_scale);
            glow_image.color.a = 1.0f - abs(special_scale - 1.0f);
        }
        for(int i=0; i<5; ++i){
            float special_scale = 1.0f;
            HUDImage @hud_image = hud.AddImage();
            hud_image.SetImageFromPath("Data/Textures/ui/versus_mode/match_mark.tga");
            hud_image.position.y = GetScreenHeight() - (122 + 128 * special_scale) * ui_scale;
            hud_image.position.x = GetScreenWidth() * 0.5 - (528 - 128 * special_scale) * ui_scale + i * 90 * ui_scale;
            hud_image.scale = vec3(ui_scale * 0.6f * special_scale);
            hud_image.scale.x *= -1.0f;
            special_scale = left_score_marks[i].scale_mult;
            HUDImage @glow_image = hud.AddImage();
            glow_image.SetImageFromPath("Data/Textures/ui/versus_mode/match_win.tga");
            glow_image.position.y = GetScreenHeight() - (122 + 128 * special_scale) * ui_scale;
            glow_image.position.z = 0.1f;
            glow_image.position.x = GetScreenWidth() * 0.5 - (528 - 128 * special_scale) * ui_scale + i * 90 * ui_scale;
            glow_image.scale = vec3(ui_scale * 0.6f * special_scale);
            glow_image.scale.x *= -1.0f;
            glow_image.color.a = 1.0f - abs(special_scale - 1.0f);
        }

        if(waiting_for_players) {
            DrawWaitingForPlayerText(ui_scale);
        }
    }

    void DrawWaitingForPlayerText(float ui_scale) {
        int font_size = int(36 * ui_scale);
        string font_path = "Data/Fonts/Lato-Regular.ttf";
        string waiting_for_players_text = "Waiting for players!";
        float opacity = (sin(time) * 0.5f + 0.5f) * 0.5f + 0.5f; // map sin(time) [-1;1] to [0.5;1]

        TextMetrics metrics = GetTextAtlasMetrics(font_path, font_size, 0, waiting_for_players_text);
        DrawTextAtlas(font_path, font_size, 0, waiting_for_players_text, GetScreenWidth() / 2 - metrics.bounds_x / 2, int(250 * ui_scale), vec4(vec3(1.0f), opacity));
    }

    void SetLeftIndicator(uint score) {
        for(uint i = 0; i < left_score_marks.length(); i++) {
            SetIndicator(@left_score_marks[i], i < score);
        }
    }

    void SetRightIndicator(uint score) {
        for(uint i = 0; i < right_score_marks.length(); i++) {
            SetIndicator(@right_score_marks[i], i < score);
        }
    }

    void SetIndicator(VersusGUI_ScoreMark@ indicator, bool is_lit) {
        if(indicator.lit != is_lit) {
            indicator.lit = is_lit;
            
            if(is_lit) {
                indicator.scale_mult = 2.0f;
                PlaySoundGroup("Data/Sounds/versus/fight_win1.xml");
            } else {
                indicator.scale_mult = 1.0f;
            }
        }
    }
    
    void ClearScores() {
        for(int i=0; i<5; ++i) {
            left_score_marks[i].lit = false;
            right_score_marks[i].lit = false;
        }
    }
}

VersusGUI versus_gui;

void RegisterMPCallBacks() {
    alive_state = Online_RegisterState("versusModeAliveStatus");
    Online_RegisterStateCallback(alive_state, "void OnVersusModeAliveStatus(array<uint8>& data)");

    update_score_state = Online_RegisterState("versusModeUpdateScoreState");
    Online_RegisterStateCallback(update_score_state, "void OnVersusModeUpdateScoreState(array<uint8>& data)");
}

void OnVersusModeUpdateScoreState(array<uint8>& data) {
    score_left = data[0];
    score_right = data[1];
    versus_gui.SetLeftIndicator(score_left);
    versus_gui.SetRightIndicator(score_right);
}

void OnVersusModeAliveStatus(array<uint8>& data) {
    if (data.size() > 1) {
        num_alive_team_guard = data[0];
        num_alive_team_turner = data[1];
        uint8 temp_reset_val = data[2];

        if(Online_IsClient()) {
            bool is_first_sync = last_remote_reset_flag == -1;
            bool server_requested_reset = (temp_reset_val == 1 && last_remote_reset_flag == 0);
            if(is_first_sync || server_requested_reset) {
                level.SendMessage("reset");
            }
            last_remote_reset_flag = temp_reset_val;
        }

        reset_timer = temp_reset_val == 1 ? -1.0f : 1.0f;
    }
}

void SendAliveState(int state, array<uint8> data) {
    if(Online_IsHosting()) {
        Online_AddSyncState(state, data);
        Online_SendState(state, data);
    }
}


void Update() {
    versus_gui.Update();
    time += time_step;
    VictoryCheckVersus();
    if(waiting_for_players && GetPlayerStates().length > 1) {
        waiting_for_players = false;
        ClearVersusScores();
        level.SendMessage("reset");
    }
}

void IncrementScoreLeft(){
    score_left++;
    SyncScoreState();

    if(score_left <= 5) {
        versus_gui.SetLeftIndicator(score_left);
    }
}

void IncrementScoreRight() {
    score_right++;
    SyncScoreState();

    if(score_right <= 5) {
        versus_gui.SetRightIndicator(score_right);
    }
}

void SyncScoreState() {
    if(Online_IsHosting()) {
        array<uint8> data(2, 0);
        data[0] = score_left;
        data[1] = score_right;
        Online_AddSyncState(update_score_state, data);
        Online_SendState(update_score_state, data);
    }
}

void ClearVersusScores(){
    score_left = 0;
    score_right = 0;
    SyncScoreState();
    versus_gui.ClearScores();
}
 

void VictoryCheckVersus() {
    int which_alive = -1;

    int num_alive = 0;
    int num = GetNumCharacters();

    int temp_alive_turner = 0;
    int temp_alive_guard = 0;

    for(int i=0; i<num; ++i){
        MovementObject@ char = ReadCharacter(i);

        bool is_alive = char.GetIntVar("knocked_out") == _awake;
        if(is_alive) {
            if (char.GetTeamString() == "turner") {
                temp_alive_turner += 1;
            }

            if (char.GetTeamString() == "guard") {
                temp_alive_guard += 1;
            }
        }
    }

    if (Online_IsClient() == false && (temp_alive_guard != num_alive_team_guard || temp_alive_turner != num_alive_team_turner)) {

        num_alive_team_guard = temp_alive_guard;
        num_alive_team_turner = temp_alive_turner;

        if (Online_IsHosting()) {
            array<uint8> data(3, 0);
            data[0] = num_alive_team_guard;
            data[1] = num_alive_team_turner;
            data[2] = reset_timer <= 0.0f ? 1 : 0;
            SendAliveState(alive_state, data);
        }
    }
    const float _blackout_speed = 2.0f;
    if(/*num_alive <= 1*/num_alive_team_guard == 0 || num_alive_team_turner == 0){
        if(reset_timer <= 1.0f / _blackout_speed){
            versus_gui.blackout_amount = min(1.0f, versus_gui.blackout_amount + time_step * _blackout_speed);
        }
        if(end_game_delay == 0.0f){
            reset_timer -= time_step;
            if(reset_timer <= 0.0f){
                if(num_alive_team_guard == 0 || num_alive_team_turner == 0){
                    //Print("Player "+(controller+1)+" wins!\n");
                    if(!Online_IsClient()) {
                        if(num_alive_team_guard == 0){
                            IncrementScoreLeft();
                        } else {
                            IncrementScoreRight();
                        }
                    }
                    if(score_left >= 5 || score_right >= 5){
                        end_game_delay = 3.0f;
                        if(Online_IsClient() == false) {
                            PlaySound("Data/Sounds/versus/fight_end.wav");
                        }
                    } else {
                        if(Online_IsClient() == false) {
                            level.SendMessage("reset");
                        } else {
                            reset_timer = 100.0f;
                        }
                    }
                } else {
                    if(Online_IsClient() == false) {
                        PlaySoundGroup("Data/Sounds/versus/fight_lose1.xml");
                        level.SendMessage("reset");
                    }
                }
            }
        }
    } else {
        versus_gui.blackout_amount = max(0.0f, versus_gui.blackout_amount - time_step * _blackout_speed);
        reset_timer = 2.0f;
    }
    if(end_game_delay != 0.0f){
        float old_end_game_delay = end_game_delay;
        end_game_delay = max(0.0f, end_game_delay - time_step);
        if(old_end_game_delay > 2.0f && end_game_delay <= 2.0f){
            if(score_left > score_right){
                PlaySound("Data/Sounds/versus/voice_end_1.wav");
            } else {
                PlaySound("Data/Sounds/versus/voice_end_2.wav");
            }
        }
        if(end_game_delay > 1.0f){
            if(score_left > score_right){
                versus_gui.player_one_win_alpha = min(1.0f, versus_gui.player_one_win_alpha + time_step);
            } else {
                versus_gui.player_two_win_alpha = min(1.0f, versus_gui.player_two_win_alpha + time_step);
            }
        } else {
            versus_gui.player_one_win_alpha = max(0.0f, versus_gui.player_one_win_alpha - time_step);
            versus_gui.player_two_win_alpha = max(0.0f, versus_gui.player_two_win_alpha - time_step);
        }
        if(end_game_delay == 0.0f){
            ClearVersusScores();
            PlaySound("Data/Sounds/versus/voice_start_1.wav");

            // Don't move to the next level if we didn't have enough players yet
            if(!waiting_for_players) {
                SendGlobalMessage("levelwin");
            } else {
                level.SendMessage("reset");
            }
        }
    } else {
        versus_gui.player_one_win_alpha = 0.0f;
        versus_gui.player_two_win_alpha = 0.0f;
    }
}
