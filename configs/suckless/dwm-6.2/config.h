/* See LICENSE file for copyright and license details. */

#include <X11/XF86keysym.h>
/* appearance */
static const unsigned int borderpx  = 4;        /* border pixel of windows */
static const unsigned int snap      = 32;       /* snap pixel */
static const int showbar            = 1;        /* 0 means no bar */
static const int topbar             = 1;        /* 0 means bottom bar */
static const char *fonts[]          = {"monospace:size=16"};
static const char dmenufont[]       = "monospace:size=16";
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
static const char col_dark_blue[]    = "#0d274f";
static const char col_orange[]      = "#eaac79";
static const char col_red[]         = "#c15a5e";
static const char col_green[]       = "#8fa176";
static const char col_cyan[]        = "#8cb5af";
static const char col_yellow[]      = "#d8b170";
static const char col_magenta[]     = "#b183ba";

/**
static const char *colors[][3]      = {
	/*               fg         bg         border   *//**
	[SchemeNorm] = { col_gray3, col_gray1, col_gray2 },
	[SchemeSel]  = { col_gray4, col_cyan,  col_cyan  },
};
**/

static const char *colors[][3] = {
    /*               fg         bg         border   */
    [SchemeNorm] = {col_gray3, col_back, col_gray2},
//    [SchemeBtn] = {col_blue, col_gray1, col_gray2},
//    [SchemeLt] = {col_gray4, col_back, col_gray2},
    [SchemeSel] = {col_gray4, col_dark_blue, col_dark_blue},
};

static const char *tagsel[][2] = {
    {col_green, col_back}, {col_red, col_back}, {col_yellow, col_back},
    {col_blue, col_back}, {col_magenta, col_back}, {col_cyan, col_back},
};

/* tagging */
static const char *tags[] = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII" };

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
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 1;    /* 1 means respect size hints in tiled resizals */

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },    /* first entry is default */
	{ "><>",      NULL },    /* no layout function means floating behavior */
	{ "[M]",      monocle },
};

/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */

static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", col_dark_blue, "-nf", col_gray3, "-sb", col_cyan, "-sf", col_blue, NULL };
static const char *termcmd[]  = { "wezterm", NULL };

/* Application Launch */
static const char *firecmd[] = {"firefox", NULL};
static const char *librecmd[] = {"librewolf", NULL};
static const char *whatscmd[] = {"whatsapp", NULL};
static const char *telecmd[] = {"telegram-desktop", NULL};

/* Volume Control */
static const char *up_vol[]   = { "/usr/bin/pactl", "set-sink-volume", "@DEFAULT_SINK@", "+10%",   NULL };
static const char *down_vol[] = { "/usr/bin/pactl", "set-sink-volume", "@DEFAULT_SINK@", "-10%",   NULL };
static const char *mute_vol[] = { "/usr/bin/pactl", "set-sink-mute",   "@DEFAULT_SINK@", "toggle", NULL };

/* Light Control */
static const char *brighter[] = { "brightnessctl", "set", "10%+", NULL };
static const char *dimmer[]   = { "brightnessctl", "set", "10%-", NULL };


static Key keys[] = {
	/* modifier                     key        function        argument */
	{ MODKEY,                       XK_p,      spawn,          {.v = dmenucmd } },
	{ MODKEY|ShiftMask,             XK_Return, spawn,          {.v = termcmd } },

    /* Application launches */
	{ MODKEY|ShiftMask,             XK_f,      spawn,          {.v = firecmd } },
	{ MODKEY|ShiftMask,             XK_l,      spawn,          {.v = librecmd } },
	{ MODKEY|ShiftMask,             XK_w,      spawn,          {.v = whatscmd } },
	{ MODKEY|ShiftMask,             XK_t,      spawn,          {.v = telecmd } },

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
    { 0,         XK_Print, spawn, SHCMD("~/.config/suckless/dwm-6.2/scripts/screenshot.sh") },
    { ShiftMask, XK_Print, spawn, SHCMD("~/.config/suckless/dwm-6.2/scripts/screenshotsel.sh") },

    // Suspend
    { 0,    XF86XK_PowerOff, spawn, SHCMD("systemctl suspend")},


    /* ------------------------ */
    /* END SPECIAL KEY CONTROL  */
    /* ------------------------ */

	{ MODKEY,                       XK_b,      togglebar,      {0} },
	{ MODKEY,                       XK_j,      focusstack,     {.i = +1 } },
	{ MODKEY,                       XK_k,      focusstack,     {.i = -1 } },
	{ MODKEY,                       XK_i,      incnmaster,     {.i = +1 } },
	{ MODKEY,                       XK_d,      incnmaster,     {.i = -1 } },
	{ MODKEY,                       XK_h,      setmfact,       {.f = -0.05} },
	{ MODKEY,                       XK_l,      setmfact,       {.f = +0.05} },
	{ MODKEY,                       XK_Return, zoom,           {0} },
	{ MODKEY,                       XK_Tab,    view,           {0} },
	{ MODKEY|ShiftMask,             XK_c,      killclient,     {0} },
	{ MODKEY,                       XK_t,      setlayout,      {.v = &layouts[0]} },
	{ MODKEY,                       XK_f,      setlayout,      {.v = &layouts[1]} },
	{ MODKEY,                       XK_m,      setlayout,      {.v = &layouts[2]} },
	{ MODKEY,                       XK_space,  setlayout,      {0} },
	{ MODKEY|ShiftMask,             XK_space,  togglefloating, {0} },
	{ MODKEY,                       XK_0,      view,           {.ui = ~0 } },
	{ MODKEY|ShiftMask,             XK_0,      tag,            {.ui = ~0 } },
	{ MODKEY,                       XK_comma,  focusmon,       {.i = -1 } },
	{ MODKEY,                       XK_period, focusmon,       {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_comma,  tagmon,         {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_period, tagmon,         {.i = +1 } },

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

