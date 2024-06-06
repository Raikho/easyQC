; =============================================================================
; LOAD VARIABLES
; =============================================================================
data := {
    initials: { value: "<initials>" }, 
    customer: { value:  "<customer>" },
    order: { value: "<order num>" },
    upc: { value: "<upc>" }, 
    style: { value: "<style>" },
    roll: { value: 1 },
}

For key, val in data.OwnProps()
    data.%key%.value := IniRead("config.ini", "main", key, val.value)

; PRINT OUTPUT DEBUG
outputString := ""
For key, val in data.OwnProps()
    outputString .= "[" key ": " val.value "]`n"
ToolTip(outputString) ; debug
SetTimer () => ToolTip(), -1200


initials := IniRead("config.ini", "main", "initials", "??")

; =============================================================================
; CREATE GUI
; =============================================================================
MyGui := Gui()
MyGui.SetFont("s14", "Verdana")
MyGui.Move(0, 0, 1000, 1000)

MyGui.AddText("Section", "Initials: ")
data.initials.gui := MyGui.AddEdit("ys", data.initials.value)

MyGui.AddText("xs Section", "Customer: ")
data.customer.gui := MyGui.AddEdit("ys", data.customer.value)

MyGui.AddText("xs Section", "Order: ")
data.order.gui := MyGui.AddEdit("ys", data.order.value)

MyGui.AddText("xs Section", "UPC: ")
data.upc.gui := MyGui.AddEdit("ys", data.upc.value)

MyGui.AddText("xs Section", "Style: ")
data.style.gui := MyGui.AddEdit("ys", data.style.value)

MyGui.AddText("xs Section", "Roll: ")
data.roll.gui := MyGui.addEdit("ys")
MyGui.AddUpDown("Range1-40 Wrap", data.roll.value)

RestartButton := MyGui.AddButton("xs Default", "Restart")
MyGui.AddButton("xs Default", "Continue?")
MyGui.AddButton("xs Default", "Get Results")
saveButton := MyGui.AddButton("xs Default", "Save")

MyGui.Show("NA")

; =============================================================================
; SETUP EVENTS
; =============================================================================
For key, val in data.OwnProps()
    data.%key%.gui.onEvent("Change", onDataUpdated.Bind(key, val))

onDataUpdated(key, val, *) {
    IniWrite(data.%key%.gui.value, "config.ini", "main", key)
}

;data.initials.gui.onEvent("Change", initialsChanged)

initialsChanged(*) {
    MsgBox("INITIALS CHANGED")
}




saveButton.OnEvent("Click", onSave) ; TODO: make automatic w/ onchange
RestartButton.OnEvent("Click", onRestart)



onSave(*) {
    IniWrite(data.initials.gui.value, "config.ini", "main", "initials")
}

onRestart(*) {
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

; Helpful Development reload
~^s::
{
    Sleep 100
    Reload
    Sleep 1000
    MsgBox("The script could not be reloaded.")
}

; TODO: end script on close


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