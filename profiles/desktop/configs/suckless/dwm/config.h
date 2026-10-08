/* See LICENSE file for copyright and license details. */

#include <X11/X.h>
#include <X11/XF86keysym.h>

/* appearance */
static const unsigned int borderpx  = 4;        /* border pixel of windows */
static const unsigned int snap      = 32;       /* snap pixel */
static const int showbar            = 1;        /* 0 means no bar */
static const int topbar             = 1;        /* 0 means bottom bar */
static const char *fonts[]          = {"monospace:size=14"};
//static const char *fonts[]          = {"-misc-firacode nerd font propo-bold-r-normal--17-120-100-100-p-0-iso8859-15:size=18"};
static const char dmenufont[]       = "monospace:size=14";
//static const char col_gray1[]       = "#222222";
//static const char col_gray2[]       = "#444444";
//static const char col_gray3[]       = "#bbbbbb";
//static const char col_gray4[]       = "#eeeeee";
//static const char col_cyan[]        = "#005577";
/* ── Palettes ────────────────────────────────────────────────────
 * Two 7x3 scheme tables (fg, bg, border), selected at runtime from the shared
 * theme state (~/.local/state/theme) by reloadtheme() in dwm.c.
 *
 * The values mirror the terminal themes in configs/wezterm/wezterm.lua and the
 * tmux palettes in configs/theme/scripts/tmux_theme_sync.sh, using the same
 * roles those use: bar surface, muted text, and blue/magenta chips.
 * Both tables must stay the same length (compile-time check in dwm.c).
 * Everything else that used to live here was dead: grep found no users outside
 * this file. */

/* dark — Night Owl (wezterm: background #011627, foreground #d6deeb) */
static const char col_night_bg[]      = "#011627";
static const char col_night_fg[]      = "#d6deeb";
static const char col_night_muted[]   = "#565f89";
static const char col_night_blue[]    = "#82aaff";
static const char col_night_magenta[] = "#c792ea";
static const char col_night_border[]  = "#1d3b53";

/* light — Catppuccin Latte, with the black-text override wezterm applies
 * (Latte's own #4C4F69 foreground reads as grey), and the #FAFAFA surface the
 * tmux palette and greeter already use. */
static const char col_latte_bg[]      = "#FAFAFA";
static const char col_latte_fg[]      = "#000000";
static const char col_latte_blue[]    = "#1E66F5";
static const char col_latte_purple[]  = "#8839EF";
static const char col_latte_border[]  = "#E6E9EF";

/* Roles are identical in both themes; only the colours change.
 * (Chip colours equal the tmux status bar's, so bar and status line match.) */
static const char *colors[][3] = {
	/*                fg                 bg                  border           */
	[SchemeNorm]     = { col_night_fg,      col_night_bg,       col_night_border }, /* bar base, unfocused window border */
	[SchemeSel]      = { col_night_bg,      col_night_blue,     col_night_blue   }, /* focused border + its title chip */
	[SchemeStatus]   = { col_night_fg,      col_night_bg,       col_night_bg     }, /* slstatus text (monochrome: see notes) */
	[SchemeTagsSel]  = { col_night_bg,      col_night_magenta,  col_night_bg     }, /* selected tag chip */
	[SchemeTagsNorm] = { col_night_muted,   col_night_bg,       col_night_bg     }, /* other tags */
	[SchemeInfoSel]  = { col_night_bg,      col_night_blue,     col_night_bg     }, /* active window tab */
	[SchemeInfoNorm] = { col_night_muted,   col_night_bg,       col_night_bg     }, /* inactive tabs */
};

static const char *colors_light[][3] = {
	/*                fg                 bg                  border           */
	[SchemeNorm]     = { col_latte_fg,      col_latte_bg,       col_latte_border },
	[SchemeSel]      = { col_latte_bg,      col_latte_blue,     col_latte_blue   },
	[SchemeStatus]   = { col_latte_fg,      col_latte_bg,       col_latte_bg     },
	[SchemeTagsSel]  = { col_latte_bg,      col_latte_purple,   col_latte_bg     },
	[SchemeTagsNorm] = { col_latte_fg,      col_latte_bg,       col_latte_bg     },
	[SchemeInfoSel]  = { col_latte_bg,      col_latte_blue,     col_latte_bg     },
	[SchemeInfoNorm] = { col_latte_fg,      col_latte_bg,       col_latte_bg     },
};

/* tagging */
static const char *tags[] = { "I", "II", "III", "IV", "V", "VI", "VII"};

/* include(s) depending on the tags array */
#include "flextile.h"

static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 */
	/* class      instance    title       tags mask     isfloating   monitor */
	{ "Gimp",     NULL,       NULL,       0,            1,           -1 },
	{ "Firefox",  NULL,       NULL,       1 << 8,       0,           -1 },
};

/* layout(s) */
static const float mfact     = 0.55; /* factor of master area size [0.05..0.95] */
static const Bool resizehints = True; /* True means respect size hints in tiled resizals */
static const int nmaster = 1; /* default number of clients in the master area */
static const int lockfullscreen = 0; /* 1 will force focus on the fullscreen window */
#include "nmaster.c"

/* Bartabgroups properties */
#define BARTAB_BORDERS 1       // 0 = off, 1 = on
#define BARTAB_BOTTOMBORDER 1  // 0 = off, 1 = on
#define BARTAB_TAGSINDICATOR 1 // 0 = off, 1 = on if >1 client/view tag, 2 = always on
#define BARTAB_TAGSPX 5        // # pixels for tag grid boxes
#define BARTAB_TAGSROWS 3      // # rows in tag grid (9 tags, e.g. 3x3)
static void (*bartabmonfns[])(Monitor *) = { monocle /* , customlayoutfn */ };
static void (*bartabfloatfns[])(Monitor *) = { NULL /* , customlayoutfn */ };


static const int layoutaxis[] = {
	1,    /* layout axis: 1 = x, 2 = y; negative values mirror the layout, setting the master area to the right / bottom instead of left / top */
	2,    /* master axis: 1 = x (from left to right), 2 = y (from top to bottom), 3 = z (monocle) */
	2,    /* stack axis:  1 = x (from left to right), 2 = y (from top to bottom), 3 = z (monocle) */
};
 
static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "-|=",      tile },
	{ "-|-",      restack },
	{ "[M]",      monocle },
	{ "><>",      NULL },    /* no layout function means floating behavior */
};

/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      viewandfocusmaster,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */

/* dmenu is compiled in, so it stays Night Owl regardless of the theme. */
static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", col_night_bg, "-nf", col_night_fg, "-sb", col_night_blue, "-sf", col_night_bg, NULL };
static const char *termcmd[]  = { "wezterm", NULL };
static const char *roficmd[] = { "rofi", "-show", "drun", "-theme", "~/.config/rofi/current.rasi"};

/* Application Launch */
static const char *firecmd[] = {"firefox", NULL};

/* Clip Menu */
/* Colours come from rofi's own theme (configs/theme/scripts/rofi_theme.sh writes
 * it on every toggle), not from dmenu-style flags, so the clipboard picker
 * follows light/dark like the rest of the desktop. */
static const char *clipmenucmd[] = { "sh", "-c", "CM_LAUNCHER=rofi clipmenu -i", NULL };

/* Light Control */
static const char *brighter[] = { "brightnessctl", "set", "10%+", NULL };
static const char *dimmer[]   = { "brightnessctl", "set", "10%-", NULL };

/* Theme toggle — the single entry point every surface follows: flips
 * ~/.local/state/theme, syncs tmux, nudges dwm (SIGWINCH) and wezterm (state
 * file poll), and pushes to every host in ~/.config/theme/remote-hosts. */
static const char *theme_toggle_cmd[] = { "sh", "-c",
	"exec \"$HOME/dotfiles/configs/theme/scripts/propagate_state.sh\" toggle", NULL };

static const unsigned int mastersplit = 1;	/* number of tiled clients in the master area */
static Key keys[] = {
	/* modifier                     key        function        argument */
	{ ControlMask|ShiftMask,        XK_y,      spawn,          {.v = theme_toggle_cmd } }, /* global light/dark toggle */
	{ MODKEY,                       XK_p,      spawn,          {.v = roficmd } },
	{ MODKEY|ShiftMask,             XK_Return, spawn,          {.v = termcmd } },

    /* Application launches */
	{ MODKEY|ShiftMask,             XK_f,      spawn,          {.v = firecmd } },

    /* Clip Menu */
	{ MODKEY|ShiftMask,             XK_v,      spawn,          {.v = clipmenucmd } },

    /* ------------------------  */
    /* START SPECIAL KEY CONTROL */
    /* ------------------------  */

    // Volume
	{ 0,                       XF86XK_AudioMute,        spawn, SHCMD("~/dotfiles/configs/dunst/dunst_audio toggle")},
    { 0,                       XF86XK_AudioLowerVolume, spawn, SHCMD("~/dotfiles/configs/dunst/dunst_audio -5%")},
	{ 0,                       XF86XK_AudioRaiseVolume, spawn, SHCMD("~/dotfiles/configs/dunst/dunst_audio +5%")},

    // Light
    { 0,                XF86XK_MonBrightnessDown, spawn,       {.v = dimmer } },
    { 0,                XF86XK_MonBrightnessUp,   spawn,       {.v = brighter } },

    // Screenshots
    { ShiftMask, XK_Print, spawn, SHCMD("flameshot gui") },

    // Suspend
    { 0,    XF86XK_PowerOff, spawn, SHCMD("systemctl suspend")},


    /* ------------------------ */
    /* END SPECIAL KEY CONTROL  */
    /* ------------------------ */

	//{ MODKEY,                       XK_b,      togglebar,      {0} },
	{ MODKEY,                       XK_j,      focusstack,     {.i = +1 } },
	{ MODKEY,                       XK_k,      focusstack,     {.i = -1 } },
	{ MODKEY,                       XK_l,      setmfact,       {.f = -0.05} },
	{ MODKEY,                       XK_h,      setmfact,       {.f = +0.05} },
	{ MODKEY,                       XK_Return, zoom,           {0} },
	{ MODKEY,                       XK_Tab,    view,           {0} },
	{ MODKEY|ShiftMask,             XK_c,      killclient,     {0} },

	/* Layout Control */
	{ MODKEY,                       XK_t,      setlayout,      {.v = &layouts[0]} },
	{ MODKEY,                       XK_s,      setlayout,      {.v = &layouts[1]} },
	{ MODKEY,                       XK_m,      setlayout,      {.v = &layouts[2]} },
	{ MODKEY,                       XK_space,  setlayout,      {0} },
	{ MODKEY|ShiftMask,             XK_space,  togglefloating, {0} },
	{ MODKEY,                       XK_0,      view,           {.ui = ~0 } },
	{ MODKEY|ShiftMask,             XK_0,      tag,            {.ui = ~0 } },
	{ MODKEY,                       XK_period,  focusmon,       {.i = -1 } },
	{ MODKEY,                       XK_comma, focusmon,       {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_period,  tagmon,         {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_comma, tagmon,         {.i = +1 } },

    /* TAG Movement */
	TAGKEYS(                        XK_1,                      0)
	TAGKEYS(                        XK_2,                      1)
	TAGKEYS(                        XK_3,                      2)
	TAGKEYS(                        XK_4,                      3)
	TAGKEYS(                        XK_5,                      4)
	TAGKEYS(                        XK_6,                      5)
	TAGKEYS(                        XK_7,                      6)
	TAGKEYS(                        XK_8,                      7)
	TAGKEYS(                        XK_9,                      8)
	{ MODKEY|ShiftMask,             XK_q,      quit,           {0} },
	/* Switch between master and client column */
	{ MODKEY|ShiftMask,             XK_w,      focusmaster,   {0} },

	/* flextile */
	{ MODKEY|ControlMask,           XK_t,      rotatelayoutaxis, {.i = 0} },    /* 0 = layout axis */
	{ MODKEY|ControlMask,           XK_m,      rotatelayoutaxis, {.i = 1} },    /* 1 = master axis */
	{ MODKEY|ControlMask, 			XK_n,      rotatelayoutaxis, {.i = 2} },    /* 2 = stack axis */
	{ MODKEY|ControlMask,           XK_Return, mirrorlayout,     {0} },
	{ MODKEY|ControlMask,           XK_h,      shiftmastersplit, {.i = -1} },   /* reduce the number of tiled clients in the master area */
	{ MODKEY|ControlMask,           XK_l,      shiftmastersplit, {.i = +1} },   /* increase the number of tiled clients in the master area */
};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button2,        spawn,          {.v = termcmd } },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};

