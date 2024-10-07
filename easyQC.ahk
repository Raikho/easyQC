; TODO:
; Samples Mode
; Ability for empty UPCs
; Printer initials hotkeys
; Opening QC program
; Printer scanning

; =======================================================================================
; LOAD VARIABLES ========================================================================
; =======================================================================================
; set development or production mode
dev := IniRead("config.ini", "main", "dev", 0)

data := {
    initials: { value: ".." },
    customer: { value: "<customer>" },
    preOrder: { value: "20010" },
    postOrder: { value: "...." },
    order: { value: "20010...." },
    upc: { value: "............" },
    style: { value: "...." },
    roll: { value: 1 },
    delay: { value: 100 },
}
rfidPath := (dev)
    ? IniRead("config.ini", "main", "debugPath", "cmd.exe")
    : IniRead("config.ini", "main", "path", "C:\RFID\PROG\RFIDQAR420.exe")
rfidPathDir := (dev)
    ? IniRead("config.ini", "main", "debugPathDir", ".\")
    : IniRead("config.ini", "main", "pathDir", "C:\RFID\PROG\")

For key, val in data.OwnProps()
    data.%key%.value := IniRead("config.ini", "main", key, val.value)

labelData := {
    order: { value: "20010....", title: "Order#", index: 1 },
    upc: { value: "............", title: "Upc", index: 2 },
    initials: { value: "..", title: "QC By", index: 3 },
    date: { value: "../../..", title: "Date", index: 4 },
    roll: { value: "1", title: "Roll #", index: 5 },
    quantity: { value: "....", title: "Qty", index: 6 },
    customer: { value: "<customer>", title: "Customer", index: 7 },
}
labelCsvPath := (dev)
    ? IniRead("config.ini", "label", "debugPath", "test/RFID-PACKLABEL.csv")
    : IniRead("config.ini", "label", "path", "C:\RFID\PACKLABEL\RFID-PACKLABEL.csv")

For key, val in labelData.OwnProps()
    labelData.%key%.value := IniRead("config.ini", "label", key, val.value)

autoStyle := { value: IniRead("config.ini", "main", "autoStyle", 0) }
quickOrder := { value: IniRead("config.ini", "main", "quickOrder", 0) }

; =======================================================================================
; CREATE GUI ============================================================================
; =======================================================================================
MyGui := Gui()
MyGui.SetFont("s14", "Verdana")
MyGui.SetFont("s14", "Courier")
MyGui.SetFont("s14", "Courier New")
MyGui.Title := "easyQC"
;MyGui.BackColor := "f1f5f9"

defaultTab := (dev) ? 1 : 1 ; // DEBUG:
Tab := MyGui.AddTab3("choose" . defaultTab, ["Main", "Label", "Settings"])
;Tab.Opt("BackgroundWhite")

; =======================================================================================
; Main TAB ==============================================================================

Tab.UseTab(1)
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

MyGui.AddGroupBox("xs-20 y+40 W330 h85 cGray Section", "actions")
startButton := MyGui.AddButton("xp+20 yp+30 Section", "open")
;startButton := MyGui.AddButton("ys Section", "Input")

; DEV MODE TEXT
if (dev) {
    dev_text := MyGui.AddText("xs y+40", "Dev Mode Active")
    dev_text.SetFont("bold cRed")
}
MyGui.AddStatusBar("xs", "Press ctrl+1 to output values")

; =======================================================================================
; SETTINGS TAB ==========================================================================

Tab.UseTab(3)

MyGui.AddGroupBox("w330 H310 cGray Section", "general")

MyGui.AddText("xp+20 yp+45 Section", "Delay")
data.delay.gui := MyGui.AddEdit("ys w80")
MyGui.AddUpDown("range1-9999 Wrap", data.delay.value)

MyGui.AddText("ys", "ms")
autoStyle.gui := MyGui.AddCheckBox("xs Section" . (autoStyle.value ? " checked" : ""), "Auto Style")
quickOrder.gui := MyGui.AddCheckBox("xs Section" . (quickOrder.value ? " checked" : ""), "Quick Order")

; =======================================================================================
; Label TAB =============================================================================

Tab.UseTab(2)

MyGui.AddGroupBox("w330 H120 cGray Section", "actions")

readButton := MyGui.AddButton("xp+20 yp+40 Section", "read")
writeButton := MyGui.AddButton("ys Section", "write")
MyGui.SetFont("s8")
MyGui.AddText("x60 y+15 cGray", "path: " . labelCsvPath)
MyGui.SetFont("s14")

MyGui.AddGroupBox("xs-105 y+30 w330 H330 cGray Section", "data")

MyGui.AddText("xp+20 yp+45 Section", "  Order#:")
labelData.order.gui := MyGui.AddEdit("ys w160", labelData.order.value)

MyGui.AddText("xs Section", "     UPC:")
labelData.upc.gui := MyGui.AddEdit("ys w160", labelData.upc.value)

MyGui.AddText("xs Section", "   QC By:")
labelData.initials.gui := MyGui.AddEdit("ys w80", labelData.initials.value)

MyGui.AddText("xs Section", "    Date:")
labelData.date.gui := MyGui.AddEdit("ys w140", labelData.date.value)

MyGui.AddText("xs Section", "    Roll:")
labelData.roll.gui := MyGui.AddEdit("ys w80", labelData.roll.value)

MyGui.AddText("xs Section", "     Qty:")
labelData.quantity.gui := MyGui.AddEdit("ys w80", labelData.quantity.value)

MyGui.AddText("xs Section", "Customer:")
labelData.customer.gui := MyGui.AddEdit("ys w160", labelData.customer.value)

; =======================================================================================

MyGui.Show("NA" . (dev ? "x-425 y190" : "")) ; if dev, diff location

; =======================================================================================
; SETUP EVENTS ==========================================================================
; =======================================================================================
For key, val in data.OwnProps()
    data.%key%.gui.onEvent("Change", onDataUpdated.Bind(key, val))

For key, val in labelData.OwnProps()
    labelData.%key%.gui.onEvent("Change", onLabelDataUpdated.Bind(key, val))

autoStyle.gui.onEvent("Click", onAutoStyleUpdated)
quickOrder.gui.onEvent("Click", onQuickOrderUpdated)

defaultButton.onEvent("Click", (*) => SendInput("{Tab}"))
startButton.onEvent("Click", onOpen)
readButton.onEvent("Click", onRead)
writeButton.onEvent("Click", onWrite)

MyGui.OnEvent("Close", onClose)

; =======================================================================================
; FUNCTIONS =============================================================================
; =======================================================================================
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

onLabelDataUpdated(key, val, *) {
    IniWrite(labelData.%key%.gui.value, "config.ini", "label", key)
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
    data.order.gui.visible := !val
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


    pid := 0
    Run(rfidPath, rfidPathDir, , &pid)
    WinWaitActive(pid)
    Sleep(500)

    SendInput WinActive(pid)
    ;onStart()
}

onStart(*) {
    onPrint()
}

onRead(*) {
    csv := {}

    try {
        Loop read, labelCsvPath {
            line := A_Index

            Loop parse, A_LoopReadLine, "CSV" {
                i := A_Index

                if (line == 1)
                    csv.%A_LoopField% := { index: i, value: "" }
                else if (line == 2)
                    For key, val in csv.OwnProps()
                        if (csv.%key%.index == i)
                            csv.%key%.value := A_LoopField
            }
        }
    }
    catch Error as e {
        MsgBox("An error occured:`n`n" . e.Message . "`n`nPlease check that the path is correct: " . labelCsvPath . "`nAlso check that the csv file is in the correct format.")
        return
    }

    updateCsv(csv)
    saveCsv(csv)
}

saveCsv(csv) {
    for key, val in labelData.OwnProps()
        onLabelDataUpdated(key, val)
}

printCsv(csv) {
    out := ""
    for key, val in csv.OwnProps()
        out .= csv.%key%.index . " - " . key . ": " . csv.%key%.value . "`n"
    MsgBox(out)
}

updateCsv(csv) {
    labelData.order.gui.value := csv.%"Order#"%.value
    labelData.upc.gui.value := csv.Upc.value
    labelData.initials.gui.value := csv.%"QC By"%.value
    labelData.date.gui.value := csv.Date.value
    labelData.roll.gui.value := csv.%"Roll #"%.value
    labelData.quantity.gui.value := csv.Qty.value
    labelData.customer.gui.value := csv.Customer.value
}

onWrite(*) {
    file := FileOpen(labelCsvPath, "w") ; TODO: add path option
    out := ""

    out .= "`"Order#`",`"Upc`",`"QC By`",`"Date`",`"Roll #`",`"Qty`",`"Customer`"`n"
    out .= "`"" . labelData.order.gui.value . "`"" . ","
    out .= "`"" . labelData.upc.gui.value . "`"" . ","
    out .= "`"" . labelData.initials.gui.value . "`"" . ","
    out .= "`"" . labelData.date.gui.value . "`"" . ","
    out .= "`"" . labelData.roll.gui.value . "`"" . ","
    out .= "`"" . labelData.quantity.gui.value . "`"" . ","
    out .= "`"" . labelData.customer.gui.value . "`""

    file.Write(out)
    file.Close()
}

onPrint(*) {
    inputDelay := data.delay.gui.value

    SendInput data.initials.gui.value "{enter}"
    Sleep inputDelay
    SendInput data.customer.gui.value "{enter}"
    Sleep inputDelay
    SendInput data.order.gui.value "{enter}"
    Sleep inputDelay
    ; // TODO: make sure still works if empty
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

^1:: onPrint()

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

; =======================================================================================
; MISC ==================================================================================
; =======================================================================================
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

    ; ===================================================================================
    ; EXAMPLES ==========================================================================
    ; ===================================================================================
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
