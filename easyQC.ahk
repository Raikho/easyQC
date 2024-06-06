; Load Variables
; =================================
initials := IniRead("config.ini", "main", "initials", "??")

; Create GUI
; =================================
MyGui := Gui()
MyGui.SetFont("s14", "Verdana")
MyGui.Move(0, 0, 1000, 1000)

MyGui.AddText("Section", "Initials: ")
MyGui.AddEdit("ys", initials)

MyGui.AddText("xs Section", "Customer: ")
customer := MyGui.AddEdit("ys", "Alltag")

MyGui.AddText("xs Section", "Order: ")
order := MyGui.AddEdit("ys", "1000000000")

MyGui.AddText("xs Section", "UPC: ")
upc := MyGui.AddEdit("ys", "2000000000")

MyGui.AddText("xs Section", "Style: ")
style := MyGui.AddEdit("ys", "3000")

MyGui.AddText("xs Section", "Roll: ")
Roll := MyGui.addEdit("ys")
MyGui.AddUpDown("Range1-40 Wrap", 1)

RestartButton := MyGui.AddButton("xs Default", "Restart")
MyGui.AddButton("xs Default", "Continue?")
MyGui.AddButton("xs Default", "Get Results")
saveButton := MyGui.AddButton("xs Default", "Save")

saveButton.OnEvent("Click", onSave)
RestartButton.OnEvent("Click", onRestart)

onSave(*) => IniWrite("abcde", "config.ini", "main", "initials")

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

MyGui.Show("NA")

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








; Explanation
; ========================
; [^ => Ctrl] [! => Alt] [+ => Shift]
; [# => Win] [_ & _ => (combo hotkey)]

; Examples
; ========================
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