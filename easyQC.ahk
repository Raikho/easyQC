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
MyGui.AddEdit("ys", data.initials.value)

MyGui.AddText("xs Section", "Customer: ")
customer := MyGui.AddEdit("ys", data.customer.value)

MyGui.AddText("xs Section", "Order: ")
order := MyGui.AddEdit("ys", data.order.value)

MyGui.AddText("xs Section", "UPC: ")
upc := MyGui.AddEdit("ys", data.upc.value)

MyGui.AddText("xs Section", "Style: ")
style := MyGui.AddEdit("ys", data.style.value)

MyGui.AddText("xs Section", "Roll: ")
Roll := MyGui.addEdit("ys")
MyGui.AddUpDown("Range1-40 Wrap", data.roll.value)

RestartButton := MyGui.AddButton("xs Default", "Restart")
MyGui.AddButton("xs Default", "Continue?")
MyGui.AddButton("xs Default", "Get Results")
saveButton := MyGui.AddButton("xs Default", "Save")

MyGui.Show("NA")

; =============================================================================
; SETUP EVENTS
; =============================================================================
saveButton.OnEvent("Click", onSave)
RestartButton.OnEvent("Click", onRestart)



onSave(*) => IniWrite("x", "config.ini", "main", "initials")
onRestart(*)
{
    TrayTip(
        (
            "Initials:`t`t" initials.value "`n"
            "Customer:`t" customer.value "`n"
            "Order #:`t`t" order.value "`n"
            "Roll:`t`t" roll.value "`n"
            "Style:`t`t" style.value "`n"
            "UPC:`t`t" upc.value "`n"
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