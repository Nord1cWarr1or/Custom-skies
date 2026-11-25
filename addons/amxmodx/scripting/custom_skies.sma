#include <amxmodx>
#include <amxmisc>

#pragma semicolon 1

public stock const PluginName[]        = "Custom skies";
public stock const PluginVersion[]     = "1.0.0";
public stock const PluginAuthor[]      = "Nordic Warrior";
public stock const PluginURL[]         = "https://github.com/Nord1cWarr1or/Custom-skies";
public stock const PluginDescription[] = "Random skybox from a list, per-map skybox lists and per-map built-in skybox";

new const CONFIG_FILE[]             = "custom_skies.ini";
new const SECTION_RANDOM_SKIES[]    = "list random skies";
new const SECTION_MAP_SETTINGS[]    = "map settings";
new const SKY_NONE[]                = "none";

new const sky_sides[][] = { "bk", "dn", "ft", "lf", "rt", "up" };

#if !defined MAX_MAPNAME_LENGTH
const MAX_MAPNAME_LENGTH = 64;
#endif

const SKY_NAME_LENGTH = 32;
const SKY_LIST_LENGTH = 192;

enum {
    Section_None,
    Section_RandomSkies,
    Section_MapSettings
};

new Array: random_skies;
new Array: map_skies;

new current_section;
new map_name[MAX_MAPNAME_LENGTH];

public plugin_precache() {
    if (get_amxx_verint() < 1100) {
        register_plugin(PluginName, PluginVersion, PluginAuthor);
    }

    create_cvar("CustomSkies_version", PluginVersion, FCVAR_SERVER | FCVAR_SPONLY | FCVAR_UNLOGGED);

    random_skies = ArrayCreate(SKY_NAME_LENGTH);
    map_skies = ArrayCreate(SKY_NAME_LENGTH);

    get_mapname(map_name, charsmax(map_name));

    read_config();

    apply_sky();
}

read_config() {
    new config_path[PLATFORM_MAX_PATH];
    get_configsdir(config_path, charsmax(config_path));
    format(config_path, charsmax(config_path), "%s/%s", config_path, CONFIG_FILE);

    new INIParser: parser = INI_CreateParser();
    INI_SetReaders(parser, "ini_key_value", "ini_new_section");

    new const bool: parsed = INI_ParseFile(parser, config_path);
    INI_DestroyParser(parser);

    if (!parsed) {
        set_fail_state("Unable to open file <%s>.", config_path);
    }
}

public bool: ini_new_section(INIParser: handle, const section[], bool: invalid_tokens, bool: close_bracket, bool: extra_tokens, curtok, any: data) {
    if (!close_bracket) {
        log_amx("Section [%s] has no closing bracket and is ignored.", section);
        current_section = Section_None;
        return true;
    }

    if (equali(section, SECTION_RANDOM_SKIES)) {
        current_section = Section_RandomSkies;
    } else if (equali(section, SECTION_MAP_SETTINGS)) {
        current_section = Section_MapSettings;
    } else {
        log_amx("Unknown section [%s] is ignored.", section);
        current_section = Section_None;
    }

    return true;
}

public bool: ini_key_value(INIParser: handle, const key[], const value[], bool: invalid_tokens, bool: equal_token, bool: quotes, curtok, any: data) {
    switch (current_section) {
        case Section_RandomSkies: {
            add_sky(random_skies, key);
        }
        case Section_MapSettings: {
            if (equal_token && equali(key, map_name)) {
                parse_map_skies(value);
            }
        }
    }

    return true;
}

parse_map_skies(const value[]) {
    ArrayClear(map_skies);

    new rest[SKY_LIST_LENGTH];
    copy(rest, charsmax(rest), value);

    new sky_name[SKY_NAME_LENGTH];

    while (rest[0]) {
        strtok2(rest, sky_name, charsmax(sky_name), rest, charsmax(rest), ',');
        trim(sky_name);

        if (sky_name[0]) {
            add_sky(map_skies, sky_name);
        }
    }
}

add_sky(const Array: skies, const sky_name[]) {
    if (equali(sky_name, SKY_NONE) || sky_files_exist(sky_name)) {
        ArrayPushString(skies, sky_name);
    }
}

bool: sky_files_exist(const sky_name[]) {
    static file_path[PLATFORM_MAX_PATH];
    static file_path_upper[PLATFORM_MAX_PATH];
    static side_upper[3];

    for (new i; i < sizeof sky_sides; ++i) {
        formatex(file_path, charsmax(file_path), "gfx/env/%s%s.tga", sky_name, sky_sides[i]);

        if (file_exists(file_path)) {
            continue;
        }

        copy(side_upper, charsmax(side_upper), sky_sides[i]);
        strtoupper(side_upper);

        formatex(file_path_upper, charsmax(file_path_upper), "gfx/env/%s%s.tga", sky_name, side_upper);

        if (!file_exists(file_path_upper)) {
            log_amx("File <%s> is missing.", file_path);
            return false;
        }

        rename_file(file_path_upper, file_path, .relative = 1);
    }

    return true;
}

apply_sky() {
    new Array: skies = random_skies;

    if (ArraySize(map_skies)) {
        skies = map_skies;
    }

    new const skies_num = ArraySize(skies);

    if (!skies_num) {
        log_amx("Map <%s>: no valid skyboxes in <%s>, the built-in skybox is kept.", map_name, CONFIG_FILE);
        return;
    }

    new sky_name[SKY_NAME_LENGTH];
    ArrayGetString(skies, random(skies_num), sky_name, charsmax(sky_name));

    if (equali(sky_name, SKY_NONE)) {
        log_amx("Map <%s>: the built-in skybox is kept.", map_name);
        return;
    }

    new file_path[PLATFORM_MAX_PATH];

    for (new i; i < sizeof sky_sides; ++i) {
        formatex(file_path, charsmax(file_path), "gfx/env/%s%s.tga", sky_name, sky_sides[i]);
        precache_generic(file_path);
    }

    set_cvar_string("sv_skyname", sky_name);

    log_amx("Current skybox: <%s>", sky_name);
}

public plugin_end() {
    ArrayDestroy(random_skies);
    ArrayDestroy(map_skies);
}

stock get_amxx_verint() {
    new buffer[16];
    get_amxx_verstring(buffer, charsmax(buffer));

    if (strfind(buffer, "1.10.0") != -1) {
        return 1100;
    } else if (strfind(buffer, "1.9.0") != -1) {
        return 190;
    } else if (strfind(buffer, "1.8.3") != -1) {
        return 183;
    } else if (strfind(buffer, "1.8.2") != -1) {
        return 182;
    }

    return 0;
}
