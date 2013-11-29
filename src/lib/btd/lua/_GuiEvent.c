/***************************************************************************/
/* GUI event.                                                              */
/* Provides functionality to move the mouse and fire it's buttons and to   */
/* fire keyboard events under program control.                             */
/*                                                                         */
/* Remark                                                                  */
/* - This version only for Windows NT 4 SP 3 or above.                     */
/* - Compile with (MinGW) :                                                */
/*   gcc -O2 -I <lua>\include -shared -s -o XXX.dll XXX.c <lua>\lua51.dll  */
/*                                                                         */
/* Copyright (c) 2008, 2009 Wim Langers. All rights reserved.              */
/* Licensed under the same terms as Lua itself.                            */
/* see LICENSE.txt                                                         */
/*                                                                         */
/* release 1.7.1 - 7 Feb 2010                                              */                                                    
/***************************************************************************/

#include <string.h>

#define _WIN32_WINNT 0x403 // Windows NT 4 SP 3
#include <windows.h>

#define LUA_API __declspec(dllexport)

#pragma comment(lib,"lua.lib")
#pragma comment(lib,"lualib.lib")

#include "lua.h"

#include "lauxlib.h"
#include "lualib.h"


/***************************************************************************/
/* Move mouse.                                                             */
/***************************************************************************/
static int moveAbs (lua_State *L)
{
    INPUT input = {0};
    input.mi.dx = luaL_checklong(L,1);
    input.mi.dy = luaL_checklong(L,2);
    input.mi.dwFlags = MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_MOVE;// | 0x4000; // MOUSEEVENTF_VIRTUALDESK -> unknown in MinGW // what's virtualdesk size ?
    SendInput(1,&input,sizeof(INPUT));
    return 0;
}

static int moveRel (lua_State *L)
{
    INPUT input = {0};
    input.mi.dx = luaL_checklong(L,1);
    input.mi.dy = luaL_checklong(L,2);
    input.mi.dwFlags = MOUSEEVENTF_MOVE;
    SendInput(1,&input,sizeof(INPUT));
    return 0;
}


/***************************************************************************/
/* Left mouse button.                                                      */
/***************************************************************************/
static int leftDown (lua_State *L)
{
    INPUT input = {0};
    input.type = INPUT_MOUSE;
    input.mi.dwFlags = MOUSEEVENTF_LEFTDOWN;
    SendInput(1,&input,sizeof(INPUT));
    return 0;
}

static int leftUp (lua_State *L)
{
    INPUT input = {0};
    input.type = INPUT_MOUSE;
    input.mi.dwFlags = MOUSEEVENTF_LEFTUP;
    SendInput(1,&input,sizeof(INPUT));
    return 0;
}


/***************************************************************************/
/* Middle mouse button.                                                    */
/***************************************************************************/
static int middleDown (lua_State *L)
{
    INPUT input = {0};
    input.type = INPUT_MOUSE;
    input.mi.dwFlags = MOUSEEVENTF_MIDDLEDOWN;
    SendInput(1,&input,sizeof(INPUT));
    return 0;
}

static int middleUp (lua_State *L)
{
    INPUT input = {0};
    input.type = INPUT_MOUSE;
    input.mi.dwFlags = MOUSEEVENTF_MIDDLEUP;
    SendInput(1,&input,sizeof(INPUT));
    return 0;
}


/***************************************************************************/
/* Right mouse button.                                                     */
/***************************************************************************/
static int rightDown (lua_State *L)
{
    INPUT input = {0};
    input.type = INPUT_MOUSE;
    input.mi.dwFlags = MOUSEEVENTF_RIGHTDOWN;
    SendInput(1,&input,sizeof(INPUT));
    return 0;
}

static int rightUp (lua_State *L)
{
    INPUT input = {0};
    input.type = INPUT_MOUSE;
    input.mi.dwFlags = MOUSEEVENTF_RIGHTUP;
    SendInput(1,&input,sizeof(INPUT));
    return 0;
}


/***************************************************************************/
/* 'Normal' keyboard keys.                                                 */
/***************************************************************************/
static int keyDown (lua_State *L)
{
    const char *normal;
    normal = luaL_checklstring(L,1,NULL);
    INPUT input = {0};
    input.ki.wVk = toupper((char)*normal);
    if ((input.ki.wVk < 32) || (input.ki.wVk > 126)) return 0;
    input.type = INPUT_KEYBOARD;
    SendInput(1,&input,sizeof(INPUT));
    return 0;
}

static int keyUp (lua_State *L)
{
    const char *normal;
    normal = luaL_checklstring(L,1,NULL);
    INPUT input = {0};
    input.ki.wVk = toupper((char)*normal);
    if ((input.ki.wVk < 32) || (input.ki.wVk > 126)) return 0;
    input.type = INPUT_KEYBOARD;
    input.ki.dwFlags = KEYEVENTF_KEYUP;
    SendInput(1,&input,sizeof(INPUT));
    return 0;
}


/***************************************************************************/
/* 'Modifier' keyboard keys.                                               */
/***************************************************************************/
static int altDown (lua_State *L)
{
    INPUT input = {0};
    input.type = INPUT_KEYBOARD;
    input.ki.wVk = VK_MENU;
    SendInput(1,&input,sizeof(INPUT));
    return 0;
}

static int altUp (lua_State *L)
{
    INPUT input = {0};
    input.type = INPUT_KEYBOARD;
    input.ki.wVk = VK_MENU;
    input.ki.dwFlags = KEYEVENTF_KEYUP;
    SendInput(1,&input,sizeof(INPUT));
    return 0;
}

static int ctrlDown (lua_State *L)
{
    INPUT input = {0};
    input.type = INPUT_KEYBOARD;
    input.ki.wVk = VK_CONTROL;
    SendInput(1,&input,sizeof(INPUT));
    return 0;
}

static int ctrlUp (lua_State *L)
{
    INPUT input = {0};
    input.type = INPUT_KEYBOARD;
    input.ki.wVk = VK_CONTROL;
    input.ki.dwFlags = KEYEVENTF_KEYUP;
    SendInput(1,&input,sizeof(INPUT));
    return 0;
}

static int shiftDown (lua_State *L)
{
    INPUT input = {0};
    input.type = INPUT_KEYBOARD;
    input.ki.wVk = VK_SHIFT;
    SendInput(1,&input,sizeof(INPUT));
    return 0;
}

static int shiftUp (lua_State *L)
{
    INPUT input = {0};
    input.type = INPUT_KEYBOARD;
    input.ki.wVk = VK_SHIFT;
    input.ki.dwFlags = KEYEVENTF_KEYUP;
    SendInput(1,&input,sizeof(INPUT));
    return 0;
}


/***************************************************************************/
/* 'Functional' keyboard keys.                                             */
/***************************************************************************/
static int enterDown (lua_State *L)
{
    const char *functional;
    INPUT input = {0};
    input.type = INPUT_KEYBOARD;
    input.ki.wVk = VK_RETURN;
    SendInput(1,&input,sizeof(INPUT));
    return 0;
}

static int enterUp (lua_State *L)
{
    INPUT input = {0};
    input.type = INPUT_KEYBOARD;
    input.ki.wVk = VK_RETURN;
    input.ki.dwFlags = KEYEVENTF_KEYUP;
    SendInput(1,&input,sizeof(INPUT));
    return 0;
}

static int funcDown (lua_State *L)
{
    const char *functional;
    functional = luaL_checklstring(L,1,NULL);
    INPUT input = {0};
    input.type = INPUT_KEYBOARD;
    input.ki.wVk = check(*functional);
    SendInput(1,&input,sizeof(INPUT));
    return 0;
}

static int funcUp (lua_State *L)
{
    const char *functional;
    functional = luaL_checklstring(L,1,NULL);
    INPUT input = {0};
    input.type = INPUT_KEYBOARD;
    input.ki.wVk = check(toupper(*functional));
    input.ki.dwFlags = KEYEVENTF_KEYUP;
    SendInput(1,&input,sizeof(INPUT));
    return 0;
}

int check (char *code)
{
    //cursor
    if (strcmp(code,"DELETE")) return VK_DELETE;
    if (strcmp(code,"DOWN")) return VK_DOWN;
    if (strcmp(code,"END")) return VK_END;
    if (strcmp(code,"HOME")) return VK_HOME;
    if (strcmp(code,"INSERT")) return VK_INSERT;
    if (strcmp(code,"LEFT")) return VK_LEFT;
    if (strcmp(code,"NEXT")) return VK_NEXT;            // page down
    if (strcmp(code,"PRIOR")) return VK_PRIOR;          // ?????????????????????
    if (strcmp(code,"RIGHT")) return VK_RIGHT;          // page up
    if (strcmp(code,"UP")) return VK_UP;
    //function
    if (strcmp(code,"F1")) return VK_F1;
    if (strcmp(code,"F2")) return VK_F2;
    if (strcmp(code,"F3")) return VK_F3;
    if (strcmp(code,"F4")) return VK_F4;
    if (strcmp(code,"F5")) return VK_F5;
    if (strcmp(code,"F6")) return VK_F6;
    if (strcmp(code,"F7")) return VK_F7;
    if (strcmp(code,"F8")) return VK_F8;
    if (strcmp(code,"F9")) return VK_F9;
    if (strcmp(code,"F10")) return VK_F10;
    if (strcmp(code,"F11")) return VK_F11;
    if (strcmp(code,"F12")) return VK_F12;
    if (strcmp(code,"F13")) return VK_F13;
    if (strcmp(code,"F14")) return VK_F14;
    if (strcmp(code,"F15")) return VK_F15;
    if (strcmp(code,"F16")) return VK_F16;
    if (strcmp(code,"F17")) return VK_F17;
    if (strcmp(code,"F18")) return VK_F18;
    if (strcmp(code,"F19")) return VK_F19;
    if (strcmp(code,"F20")) return VK_F20;
    if (strcmp(code,"F21")) return VK_F21;
    if (strcmp(code,"F22")) return VK_F22;
    if (strcmp(code,"F23")) return VK_F23;
    if (strcmp(code,"F24")) return VK_F24;
    //numeric keypad
    if (strcmp(code,"ADD")) return VK_ADD;
    if (strcmp(code,"DECIMAL")) return VK_DECIMAL;
    if (strcmp(code,"DIVIDE")) return VK_DIVIDE;
    if (strcmp(code,"MULTIPLY")) return VK_MULTIPLY;
    if (strcmp(code,"NUMLOCK")) return VK_NUMLOCK;
    if (strcmp(code,"NUMPAD0")) return VK_NUMPAD0;
    if (strcmp(code,"NUMPAD1")) return VK_NUMPAD1;
    if (strcmp(code,"NUMPAD2")) return VK_NUMPAD2;
    if (strcmp(code,"NUMPAD3")) return VK_NUMPAD3;
    if (strcmp(code,"NUMPAD4")) return VK_NUMPAD4;
    if (strcmp(code,"NUMPAD5")) return VK_NUMPAD5;
    if (strcmp(code,"NUMPAD6")) return VK_NUMPAD6;
    if (strcmp(code,"NUMPAD7")) return VK_NUMPAD7;
    if (strcmp(code,"NUMPAD8")) return VK_NUMPAD8;
    if (strcmp(code,"NUMPAD9")) return VK_NUMPAD9;
    if (strcmp(code,"SEPARATOR")) return VK_SEPARATOR;      // ?????????????????
    if (strcmp(code,"SUBTRACT")) return VK_SUBTRACT;
    //modifier, extension keys
    if (strcmp(code,"CAPITAL")) return VK_CAPITAL;
    if (strcmp(code,"CONTROL")) return VK_CONTROL;          // see controlUp/Down
    if (strcmp(code,"LCONTROL")) return VK_LCONTROL;
    if (strcmp(code,"LMENU")) return VK_LMENU;              // see altUp/Down
    if (strcmp(code,"LSHIFT")) return VK_LSHIFT;
    if (strcmp(code,"LWIN")) return VK_LWIN;
    if (strcmp(code,"MENU")) return VK_MENU;
    if (strcmp(code,"RMENU")) return VK_RMENU;
    if (strcmp(code,"RCONTROL")) return VK_RCONTROL;
    if (strcmp(code,"RSHIFT")) return VK_RSHIFT;
    if (strcmp(code,"RWIN")) return VK_RWIN;
    if (strcmp(code,"SHIFT")) return VK_SHIFT;              // see shiftUp/Down
    //rest
    if (strcmp(code,"ACCEPT")) return VK_ACCEPT;            // ?????????????????
    if (strcmp(code,"APPS")) return VK_APPS;                // ?????????????????
    if (strcmp(code,"ATTN")) return VK_ATTN;                // ?????????????????
    if (strcmp(code,"BACK")) return VK_BACK;                // back space
    if (strcmp(code,"CANCEL")) return VK_CANCEL;            // ?????????????????
    if (strcmp(code,"CLEAR")) return VK_CLEAR;              // ?????????????????
    if (strcmp(code,"CONVERT")) return VK_CONVERT;          // ?????????????????
    if (strcmp(code,"CRSEL")) return VK_CRSEL;              // ?????????????????
    if (strcmp(code,"EREOF")) return VK_EREOF;              // ?????????????????
    if (strcmp(code,"ESCAPE")) return VK_ESCAPE;            // escape
    if (strcmp(code,"EXECUTE")) return VK_EXECUTE;          // ?????????????????
    if (strcmp(code,"EXSEL")) return VK_EXSEL;              // ?????????????????
    if (strcmp(code,"FINAL")) return VK_FINAL;              // ?????????????????
    if (strcmp(code,"HANGEUL")) return VK_HANGEUL;          // ?????????????????
    if (strcmp(code,"HANGUL")) return VK_HANGUL;            // ?????????????????
    if (strcmp(code,"HANJA")) return VK_HANJA;              // ?????????????????
    if (strcmp(code,"HELP")) return VK_HELP;                // ?????????????????
    if (strcmp(code,"JUNJA")) return VK_JUNJA;              // ?????????????????
    if (strcmp(code,"KANA")) return VK_KANA;                // ?????????????????
    if (strcmp(code,"KANJI")) return VK_KANJI;              // ?????????????????
    if (strcmp(code,"LBUTTON")) return VK_LBUTTON;          // see leftUp/Down
    if (strcmp(code,"MBUTTON")) return VK_MBUTTON;          // see middleUp/Down
    if (strcmp(code,"MODECHANGE")) return VK_MODECHANGE;    // ?????????????????
    if (strcmp(code,"NONAME")) return VK_NONAME;            // ?????????????????
    if (strcmp(code,"NONCONVERT")) return VK_NONCONVERT;    // ?????????????????
    if (strcmp(code,"OEM_1")) return VK_OEM_1;              // ?????????????????
    if (strcmp(code,"OEM_2")) return VK_OEM_2;              // ?????????????????
    if (strcmp(code,"OEM_3")) return VK_OEM_3;              // ?????????????????
    if (strcmp(code,"OEM_4")) return VK_OEM_4;              // ?????????????????
    if (strcmp(code,"OEM_5")) return VK_OEM_5;              // ?????????????????
    if (strcmp(code,"OEM_6")) return VK_OEM_6;              // ?????????????????
    if (strcmp(code,"OEM_7")) return VK_OEM_7;              // ?????????????????
    if (strcmp(code,"OEM_8")) return VK_OEM_8;              // ?????????????????
    if (strcmp(code,"OEM_CLEAR")) return VK_OEM_CLEAR;      // ?????????????????
    if (strcmp(code,"PA1")) return VK_PA1;                  // ?????????????????
    if (strcmp(code,"PAUSE")) return VK_PAUSE;              // ?????????????????
    if (strcmp(code,"PLAY")) return VK_PLAY;                // ?????????????????
    if (strcmp(code,"PRINT")) return VK_PRINT;              // print screen ????
    if (strcmp(code,"PROCESSKEY")) return VK_PROCESSKEY;    // ?????????????????
    if (strcmp(code,"RBUTTON")) return VK_RBUTTON;          // see rightUp/Down
    if (strcmp(code,"RETURN")) return VK_RETURN;            // see enterUp/Down
    if (strcmp(code,"SCROLL")) return VK_SCROLL;            // scroll lock
    if (strcmp(code,"SELECT")) return VK_SELECT;            // ?????????????????
    if (strcmp(code,"SLEEP")) return VK_SLEEP;              // ?????????????????
    if (strcmp(code,"SNAPSHOT")) return VK_SNAPSHOT;        // print screen?????
    if (strcmp(code,"SPACE")) return VK_SPACE;              // space
    if (strcmp(code,"TAB")) return VK_TAB;                  // tabulator
    if (strcmp(code,"ZOOM")) return VK_ZOOM;                // ?????????????????
}

/***************************************************************************/
/* Register methods.                                                       */
/***************************************************************************/
static const luaL_reg _GuiEvent[] = 
{
    {"altDown",altDown},
    {"altUp",altUp},
    {"ctrlDown",ctrlDown},
    {"ctrlUp",ctrlUp},
    {"enterDown",ctrlDown},
    {"enterUp",ctrlUp},
    {"funcUp",keyUp},
    {"funcDown",keyDown},
    {"keyDown",keyDown},
    {"keyUp",keyUp},
    {"leftDown",leftDown},
    {"leftUp",leftUp},
    {"middleDown",middleDown},
    {"middleUp",middleUp},
    {"moveAbs",moveAbs},
    {"moveRel",moveRel},
    {"rightDown",rightDown},
    {"rightUp",rightUp},
    {"shiftDown",keyDown},
    {"shiftUp",keyUp},
    {NULL,NULL}
};


/***************************************************************************/
/* Open library.                                                           */
/***************************************************************************/
LUALIB_API int luaopen__GuiEvent (lua_State *L)
{
    luaL_openlib(L, "_GuiEvent", _GuiEvent, 0);
    return 1;
}

