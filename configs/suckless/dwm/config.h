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
static const char col_back[]        = "#121111";
static const char col_gray1[]       = "#212126";
static const char col_gray2[]       = "#444444";
static const char col_gray3[]       = "#bbbbbb";
static const char col_gray4[]       = "#dbdfdf";
static const char col_blue[]        = "#808fbe";
static const char col_navy1[]       = "#0d274f";
static const char col_navy2[]       = "#21296e";
static const char col_orange[]      = "#eaac79";
static const char col_red[]         = "#c15a5e";
static const char col_green[]       = "#8fa176";
static const char col_cyan[]        = "#8cb5af";
static const char col_yellow[]      = "#d8b170";
static const char col_magenta[]     = "#b183ba";
static const char col_magenta2[]    = "#ce92d4";
static const char col_golden[]      = "#ffd700";
static const char col_gold_warm[]   = "#f38518";
static const char col_ivory[]       = "#FFFFF0";
static const char col_rose_gold[]   = "#E0BFB8";

// synthwave pallete
static const char col_sy_yellow[] = "#f9f972";
static const char col_sy_pink[] = "#ff00f6";
static const char col_sy_purple[] = "#aa54f9";
static const char col_sy_blue[] = "#55a8fb";
static const char col_sy_celeste[] = "#00fbfd";
static const char col_sy_black[] = "#241b30";


static const char *colors[][3] = {
    /*               		 fg               bg              border          */
    [SchemeNorm] 		 = { col_sy_blue,  col_sy_black,   col_sy_black    },
    [SchemeSel] 		 = { col_sy_black,    col_sy_blue, col_sy_blue  },
	//[SchemeTabActive]  	 = { col_sy_black,    col_sy_blue, col_sy_black    },
	//[SchemeTabInactive]  = { col_sy_blue,  col_sy_black,   col_sy_black    },
	[SchemeStatus]  	 = { col_sy_blue,  col_sy_black,   col_sy_black    }, // Statusbar right {text,background,not used but cannot be empty}
	[SchemeTagsSel]      = { col_sy_black,    col_sy_blue, col_sy_black    }, // Tagbar left selected {text,background,not used but cannot be empty}
	[SchemeTagsNorm]     = { col_sy_blue,  col_sy_black,   col_sy_black    }, // Tagbar left unselected {text,background,not used but cannot be empty}
	[SchemeInfoSel]      = { col_sy_black,    col_sy_blue, col_sy_black    }, // infobar middle  selected {text,background,not used but cannot be empty}
	[SchemeInfoNorm]     = { col_sy_blue,  col_sy_black,   col_sy_black    }, // infobar middle  unselected {text,background,not used but cannot be empty}


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

static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", col_sy_black, "-nf", col_sy_celeste, "-sb", col_rose_gold, "-sf", col_sy_black, NULL };
static const char *termcmd[]  = { "wezterm", NULL };
static const char *roficmd[] = { "rofi", "-show", "drun", "-theme", "~/.config/rofi/current.rasi"};

/* Application Launch */
static const char *firecmd[] = {"firefox", NULL};

/* Clip Menu */
static const char *clipmenucmd[] = { "sh", "-c", "CM_LAUNCHER=rofi clipmenu -i -fn 'monospace:size=14' -nb '#241b30' -nf '#00fbfd' -sb '#E0BFB8' -sf '#241b30'", NULL };

/* Volume Control */
static const char *up_vol[]   = { "/usr/bin/pactl", "set-sink-volume", "@DEFAULT_SINK@", "+10%",   NULL };
static const char *down_vol[] = { "/usr/bin/pactl", "set-sink-volume", "@DEFAULT_SINK@", "-10%",   NULL };
static const char *mute_vol[] = { "/usr/bin/pactl", "set-sink-mute",   "@DEFAULT_SINK@", "toggle", NULL };

/* Light Control */
static const char *brighter[] = { "brightnessctl", "set", "10%+", NULL };
static const char *dimmer[]   = { "brightnessctl", "set", "10%-", NULL };

static const unsigned int mastersplit = 1;	/* number of tiled clients in the master area */
static Key keys[] = {
	/* modifier                     key        function        argument */
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
    { 0,                       XF86XK_AudioLowerVolume, spawn, {.v = down_vol } },
	{ 0,                       XF86XK_AudioMute, spawn,        {.v = mute_vol } },
	{ 0,                       XF86XK_AudioRaiseVolume, spawn, {.v = up_vol   } },

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

