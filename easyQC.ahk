﻿; =============================================================================
; LOAD VARIABLES
; =============================================================================
data := {
    initials: { value: ".." }, 
    customer: { value:  "<customer>" },
    order: { value: "<order num>" },
    upc: { value: "<upc>" }, 
    style: { value: "...." },
    roll: { value: 1 },
    delay: { value: 100 },
}

For key, val in data.OwnProps()
    data.%key%.value := IniRead("config.ini", "main", key, val.value)

dev := IniRead("config.ini", "main", "dev", 0) ; set development or production mode

; =============================================================================
; CREATE GUI
; =============================================================================
MyGui := Gui()
MyGui.SetFont("s14", "Verdana")
MyGui.SetFont("s14", "Courier")
MyGui.SetFont("s14", "Courier New")
MyGui.Title := "easyQC"

Tab := MyGui.Add("Tab3",, ["Main", "Settings"])

MyGui.AddGroupBox("w330 h310 cGray Section", "Data")

MyGui.AddText("xp+20 yp+45 Section", "Initials: ")
data.initials.gui := MyGui.AddEdit("ys w40 limit2", data.initials.value)

MyGui.AddText("xs Section", "Customer: ")
data.customer.gui := MyGui.AddEdit("ys w170", data.customer.value)

MyGui.AddText("xs Section", "   Order: ")
data.order.gui := MyGui.AddEdit("ys w170 number", data.order.value)

MyGui.AddText("xs Section", "     UPC: ")
data.upc.gui := MyGui.AddEdit("ys w170 number", data.upc.value)

MyGui.AddText("xs Section", "   Style: ")
data.style.gui := MyGui.AddEdit("ys w60 limit4", data.style.value)

MyGui.AddText("xs Section", "    Roll: ")
data.roll.gui := MyGui.addEdit("ys w60")
data.roll.gui.setFont("c0xe2e8f0 bold")
data.roll.gui.Opt("+Background0x2563eb")
MyGui.AddUpDown("Range1-40 Wrap", data.roll.value)

MyGui.addText("x16", "Press ctrl+1 to output values")

; ==== Settings Tab ====
Tab.UseTab(2)

MyGui.AddGroupBox("w330 H310 cGray Section", "main")

MyGui.AddText("xp+20 yp+45 Section", "Delay")
data.delay.gui := MyGui.AddEdit("ys w80")
MyGui.AddUpDown("range1-9999 Wrap", data.delay.value)

MyGui.AddText("ys", "ms")
MyGui.AddCheckBox("xs Section", "Check Me")


MyGui.Show("NA")

; =============================================================================
; SETUP EVENTS
; =============================================================================
For key, val in data.OwnProps()
    data.%key%.gui.onEvent("Change", onDataUpdated.Bind(key, val))

onDataUpdated(key, val, *) {
    IniWrite(data.%key%.gui.value, "config.ini", "main", key)
}

MyGui.OnEvent("Close", onClose)

; =============================================================================
; SETUP FUNCTIONS
; =============================================================================
onPrint(*) {
    inputDelay := data.delay.gui.value

    SendInput data.initials.gui.value "{enter}"
    Sleep inputDelay
    SendInput data.customer.gui.value "{enter}"
    Sleep inputDelay
    SendInput data.order.gui.value "{enter}"
    Sleep inputDelay
    SendInput data.upc.gui.value "{enter}"
    Sleep inputDelay
    SendInput data.style.gui.value "{enter}"
    Sleep inputDelay
    SendInput data.roll.gui.value "{enter}"
    Sleep inputDelay
    SendInput "Y{enter}"
    Sleep inputDelay
    SendInput "N{enter}"
    Sleep inputDelay
    SendInput "Y{enter}"
    Sleep inputDelay
}

onClose(*) {
    if not (dev)
        ExitApp
}

^1::onPrint()

addDebugNotification(*) {
    TrayTip(
        (
            "Initials:`t`t" data.initials.value "`n"
            "Customer:`t" data.customer.value "`n"
            "Order #:`t`t" data.order.value "`n"
            "Roll:`t`t" data.roll.value "`n"
            "Style:`t`t" data.style.value "`n"
            "UPC:`t`t" data.upc.value "`n"
        ),
        "Running: " A_ScriptName,
        4
    )
        
    SetTimer () => TrayTip(), -5000
}

; =============================================================================
; MISC
; =============================================================================
Setup:
{
    #Requires AutoHotkey v2.0+
    #SingleInstance force
}

; Helpful Development live reload
~^s::
{
    if (dev) {
        Sleep 100
        Reload
        Sleep 1000
        MsgBox("The script could not be reloaded.")
    }
}

;// DEBUG
if (dev) {
    outputString := ""
    For key, val in data.OwnProps()
        outputString .= "[" key ": " val.value "]`n"
    ToolTip(outputString)
    SetTimer () => ToolTip(), -1200
}

; =============================================================================
; EXAMPLES
; =============================================================================
; [^ => Ctrl] [! => Alt] [+ => Shift]
; [# => Win] [_ & _ => (combo hotkey)]

; #HotIf WinActive("ahk_class MozillaWindowClass")
; ^1::Send "This is Firef"
; ^3::WinMaximize "A"
; :*:ftw::Free the Whales ; Hotstring

; ^a::
; {
;    TrayTip(
;        (
;            "Initials:`t`t" "MZ" "`n"
;             "Customer:`t" "Alltag" "`n"
;             "Upc:`t`t" "6382" "`n"
;         ),
;         "Running: " A_ScriptName "`nHotkey  : " A_ThisHotkey,
;         4
;     )
;     SetTimer () => TrayTip(), -5000
; }

; ^2::
; {
;     ans := InputBox("What is your first name?")
;     TrayTip ("Hi, " ans.value)
;     SetTimer () => TrayTip(), -5000
; }

; !+^x::Run A_Desktop "\Some_Program\Program.exe"