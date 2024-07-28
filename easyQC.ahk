; =============================================================================
; LOAD VARIABLES
; =============================================================================
data := {
    initials: { value: ".." }, 
    customer: { value:  "<customer>" },
    preOrder: {value: "20010" },
    postOrder: { value: "...." },
    order: { value: "20010...." },
    upc: { value: "............" }, 
    style: { value: "...." },
    roll: { value: 1 },
    delay: { value: 100 },
}

For key, val in data.OwnProps()
    data.%key%.value := IniRead("config.ini", "main", key, val.value)

autoStyle := { value: IniRead("config.ini", "main", "autoStyle", 0) }
quickOrder := { value: IniRead("config.ini", "main", "quickOrder", 0) }

; set development or production mode
dev := IniRead("config.ini", "main", "dev", 0)

; =============================================================================
; CREATE GUI
; =============================================================================
MyGui := Gui()
MyGui.SetFont("s14", "Verdana")
MyGui.SetFont("s14", "Courier")
MyGui.SetFont("s14", "Courier New")
MyGui.Title := "easyQC"
;MyGui.BackColor := "f1f5f9"

Tab := MyGui.Add("Tab3",, ["Main", "Settings", "Label"])
;Tab.Opt("BackgroundWhite")

; =============================================================================
; Main TAB ================================================================

MyGui.AddGroupBox("w330 h310 cGray Section", "data")

MyGui.AddText("xp+20 yp+45 Section", "Initials: ")
data.initials.gui := MyGui.AddEdit("ys w40 limit2", data.initials.value)
data.initials.gui.Opt("Backgroundeff6ff")

MyGui.AddText("xs Section", "Customer: ")
data.customer.gui := MyGui.AddEdit("ys w170", data.customer.value)
data.customer.gui.Opt("Backgroundeff6ff")

; ==== Order ====
MyGui.AddText("xs Section", "   Order: ")
data.preOrder.gui := MyGui.AddEdit("ys w82 number limit5", SubStr(data.order.value, 1, 5))
data.preOrder.gui.Enabled := false
data.postOrder.gui := MyGui.AddEdit("ys w70 number limit4", SubStr(data.order.value, -4))
data.order.gui := MyGui.AddEdit("ys x+-170 w170 number limit9", data.order.value)
data.preOrder.gui.Opt("Backgroundeff6ff")
data.postOrder.gui.Opt("Backgroundeff6ff")
data.order.gui.Opt("Backgroundeff6ff")

setupQuickOrder(quickOrder.value)

MyGui.AddText("xs Section", "     UPC: ")
data.upc.gui := MyGui.AddEdit("ys w170 number", data.upc.value)
data.upc.gui.Opt("Backgroundeff6ff")

data.style.text := MyGui.AddText("xs Section", "   Style: ")
data.style.gui := MyGui.AddEdit("ys w60 limit4", data.style.value)
data.style.gui.Opt("Backgroundeff6ff")

if (autoStyle.value)
    lockStyle 

MyGui.AddText("xs Section", "    Roll: ")
data.roll.gui := MyGui.addEdit("ys w60")
data.roll.gui.setFont("")
data.roll.gui.Opt("+Backgroundeff6ff")
MyGui.AddUpDown("Range1-200 Wrap", data.roll.value)

defaultButton := MyGui.AddButton("ys Default", "BUTTON")
defaultButton.Visible := false

MyGui.AddGroupBox("xs-20 y+40 W330 h150 cGray Section", "actions")
openButton := MyGui.AddButton("xp+20 yp+45 Section", "Open")
startButton := MyGui.AddButton("xs Section", "Input")

; DEV MODE TEXT
if (dev) {
    dev_text := MyGui.AddText("xs y+40", "Dev Mode Active")
    dev_text.SetFont("bold cRed")
}
MyGui.AddStatusBar("xs", "Press ctrl+1 to output values")

; =============================================================================
; SETTINGS TAB ================================================================

Tab.UseTab(2)

MyGui.AddGroupBox("w330 H310 cGray Section", "general")

MyGui.AddText("xp+20 yp+45 Section", "Delay")
data.delay.gui := MyGui.AddEdit("ys w80")
MyGui.AddUpDown("range1-9999 Wrap", data.delay.value)

MyGui.AddText("ys", "ms")
autoStyle.gui := MyGui.AddCheckBox("xs Section" . (autoStyle.value ? " checked" : ""), "Auto Style")
quickOrder.gui := MyGui.AddCheckBox("xs Section" . (quickOrder.value ? " checked" : ""), "Quick Order")

; =============================================================================
; Label TAB ===================================================================

Tab.UseTab(3)

MyGui.AddGroupBox("w330 H310 cGray Section", "general")

; TO ADD: OrderNumber, UPC, QCBy, DATE, RollNum, Customer

MyGui.AddText("xp+20 yp+45 Section", " Order #:")
MyGui.AddEdit("ys w80")

MyGui.AddText("xs Section", "     UPC:")
MyGui.AddEdit("ys w80")

MyGui.AddText("xs Section", "   QC BY:")
MyGui.AddEdit("ys w80")

MyGui.AddText("xs Section", "    Date:")
MyGui.AddEdit("ys w80")

MyGui.AddText("xs Section", "  Roll #:")
MyGui.AddEdit("ys w80")

MyGui.AddText("xs Section", "Customer:")
MyGui.AddEdit("ys w80")


;data.delay.gui := MyGui.AddEdit("ys w80")
;MyGui.AddUpDown("range1-9999 Wrap", data.delay.value)

;MyGui.AddText("ys", "ms")
;autoStyle.gui := MyGui.AddCheckBox("xs Section" . (autoStyle.value ? " checked" : ""), "Auto Style")
;quickOrder.gui := MyGui.AddCheckBox("xs Section" . (quickOrder.value ? " checked" : ""), "Quick Order")

;MyGui.Show("NA" . (dev ? "x-425 y190" : "")) ; if dev, diff location

; =============================================================================

MyGui.Show("NA" . (dev ? "x-425 y190" : "")) ; if dev, diff location

; =============================================================================
; SETUP EVENTS
; =============================================================================
For key, val in data.OwnProps()
    data.%key%.gui.onEvent("Change", onDataUpdated.Bind(key, val))

autoStyle.gui.onEvent("Click", onAutoStyleUpdated)
quickOrder.gui.onEvent("Click", onQuickOrderUpdated)

defaultButton.onEvent("Click", (*) => SendInput("{Tab}"))
openButton.onEvent("Click", onOpen)
startButton.onEvent("Click", onStart)

MyGui.OnEvent("Close", onClose)

; =============================================================================
; FUNCTIONS
; =============================================================================
onDataUpdated(key, val, *) {
    if (autoStyle.gui.value && key = "upc")
        data.style.gui.value := SubStr(data.upc.gui.value, -4)
    if (key = "preOrder")
        return MsgBox("Error: preOrder was somehow updated using the gui)")
    if (key = "postOrder") {
        data.order.gui.value := data.preOrder.gui.value . data.postOrder.gui.value
        IniWrite(data.order.gui.value, "config.ini", "main", "order")
        return
    }
    if (key = "order") {
        val := data.order.gui.value
        postLength := min((5 - StrLen(val)), 0)
        data.preOrder.gui.value := SubStr(val, 1, 5)
        data.postOrder.gui.value := SubStr(val, postLength)
    }
    IniWrite(data.%key%.gui.value, "config.ini", "main", key)
}

onAutoStyleUpdated(*) {
    val := autoStyle.gui.value
    IniWrite(val, "config.ini", "main", "autoStyle")
    if (val) 
        lockStyle
    else 
        unlockStyle
}

onQuickOrderUpdated(*) {
    IniWrite(quickOrder.gui.value, "config.ini", "main", "quickOrder")
    quickOrder.value := quickOrder.gui.value
    setupQuickOrder(quickOrder.gui.value)
}

setupQuickOrder(val) {
    data.preOrder.gui.Visible := val
    data.postOrder.gui.Visible := val
    data.order.gui.visible :=  !val
}

lockStyle(*) {
    data.style.gui.Enabled := false
    data.style.gui.value := SubStr(data.upc.gui.value, -4)
    data.style.text.setFont("cSilver")
}
unlockStyle(*) {
    data.style.gui.Enabled := true
    data.style.text.setFont("cBlack")
    data.style.gui.value := IniRead("config.ini", "main", "style", data.style.value)
}

onOpen(*) {
    ; ahk_class: ConsoleWindowClass
    ; ahk_exe: cmd.exe
    ; title: Selet RFIDQAR420 - 420

    ; shell := ComObject("WScript.Shell")
    ; exec := shell.Exec(A_ComSpec " /C " "whoami")
    ; output := exec.StdOut.ReadAll()
    ; MsgBox(output)

    ; pid := "0"
    ; Run("cmd.exe",,, &pid)
    ; WinWait("ahk_pid " . pid)
    ;MsgBox(pid . ", Should open cmd window when pressed, still in progress")
}

onStart(*) {
    MsgBox("Should input commands into cmd window when pressed, still in progress")
}

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
; if (dev) {
;     outputString := ""
;     For key, val in data.OwnProps()
;         outputString .= "[" key ": " val.value "]`n"
;     ToolTip(outputString)
;     SetTimer () => ToolTip(), -1200
; }

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