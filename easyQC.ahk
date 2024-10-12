; TODO:
; Options to disable hotkeys
; Opening & Auto Filling QC program
; Printer scanning
; Check if the generated log sheet is already there

; =======================================================================================
; ==================================== LOAD VARIABLES ===================================
; =======================================================================================

; set development or production mode
dev := IniRead("config.ini", "debug", "dev", 0)

data := {
    initials: { value: ".." },
    customer: { value: "<customer>" },
    preOrder: { value: "20010" },
    postOrder: { value: "...." },
    order: { value: "20010...." },
    upc: { value: "............" },
    style: { value: "...." },
    roll: { value: 1 },
}

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

For key, val in labelData.OwnProps() {
    labelData.%key%.value := IniRead("config.ini", "label", key, val.value)
    labelData.%key%.readValue := labelData.%key%.value
}

sampleData := {
    initials: { value: ".." },
    customer: { value: "<customer>" },
    order: { value: "<order>" },
    style: { value: "<style>" },
    roll: { value: 1 },
}

For key, val in sampleData.OwnProps()
    sampleData.%key%.value := IniRead("config.ini", "sample", key, val.value)

printData := { initials: { value: ".." }, }
printData.initials.value := IniRead("config.ini", "print", "initials", printData.initials.value)

settings := {
    autoStyle: { value: 0 },
    quickOrder: { value: 0 },
    delay: { value: 100 },
    rfidWinPos: { value: 1 },
}

For key, val in settings.OwnProps()
    settings.%key%.value := IniRead("config.ini", "settings", key, val.value)

paths := {
    rfid: {
        dir: IniRead("config.ini", dev ? "debug" : "paths", "rfidDir", dev ? "" : "C:\RFID\PROG\"),
        file: IniRead("config.ini", dev ? "debug" : "paths", "rfidFile", dev ? "cmd.exe" : "RFIDQAR420.exe"),
    },
    csv: {
        dir: IniRead("config.ini", dev ? "debug" : "paths", "csvDir", dev ? ".\test\" : "C:\RFID\PACKLABEL\"),
        file: IniRead("config.ini", dev ? "debug" : "paths", "csvFile", "RFID-PACKLABEL.csv"),
    },
}
paths.rfid.DefineProp("full", { Get: (this) => this.dir . this.file })
paths.csv.DefineProp("full", { Get: (this) => this.dir . this.file })


; =======================================================================================
; ===================================== CREATE GUI ======================================
; =======================================================================================
MyGui := Gui()
MyGui.SetFont("s14", "Verdana")
MyGui.SetFont("s14", "Courier")
MyGui.SetFont("s14", "Courier New")
MyGui.Title := (!dev) ? "easyQC" : "easyQC - DEV MODE"
;MyGui.BackColor := "f1f5f9"

defaultTab := (dev) ? 1 : 1 ; DEBUG

MyGui.SetFont("s11")
Tab := MyGui.AddTab3("-wrap choose" . defaultTab, ["Main", "Label", "Samples", "Print", "Settings"])
MyGui.SetFont("s14")
;Tab.Opt("BackgroundWhite")

; =======================================================================================
; ===================================== Main TAB ========================================

Tab.UseTab(1)
MyGui.AddGroupBox("w330 h275 cGray Section", "data")

MyGui.AddText("xp+20 yp+30 Section", "Initials: ")
data.initials.gui := MyGui.AddEdit("ys w40 limit2", data.initials.value)
data.initials.gui.Opt("Backgroundeef2ff")

MyGui.AddText("xs Section", "Customer: ")
data.customer.gui := MyGui.AddEdit("ys w170", data.customer.value)
data.customer.gui.Opt("Backgroundeef2ff")

; ==== Order ====
MyGui.AddText("xs Section", "   Order: ")
data.preOrder.gui := MyGui.AddEdit("ys w82 number limit5", SubStr(data.order.value, 1, 5))
data.preOrder.gui.Enabled := false
data.postOrder.gui := MyGui.AddEdit("ys w70 number limit4", SubStr(data.order.value, -4))
data.order.gui := MyGui.AddEdit("ys x+-170 w170 number limit9", data.order.value)
data.preOrder.gui.Opt("Backgroundeef2ff")
data.postOrder.gui.Opt("Backgroundeef2ff")
data.order.gui.Opt("Backgroundeef2ff")

setupQuickOrder(settings.quickOrder.value)

MyGui.AddText("xs Section", "     UPC: ")
data.upc.gui := MyGui.AddEdit("ys w170 number", data.upc.value)
data.upc.gui.Opt("Backgroundeef2ff")

data.style.text := MyGui.AddText("xs Section", "   Style: ")
data.style.gui := MyGui.AddEdit("ys w70 limit4", data.style.value)
data.style.gui.Opt("Backgroundeef2ff")

if (settings.autoStyle.value)
    lockStyle()

MyGui.AddText("xs Section", "    Roll: ")
data.roll.gui := MyGui.addEdit("ys w70")
data.roll.gui.setFont("bold cf1f5f9 s14", "Arial")
data.roll.gui.Opt("+Background4d6d9a center")
MyGui.AddUpDown("Range1-200 Wrap", data.roll.value)

defaultButton := MyGui.AddButton("ys Default", "BUTTON")
defaultButton.Visible := false

MyGui.AddGroupBox("xs-20 y+25 W330 h75 cGray Section", "actions")
openButton := MyGui.AddButton("xp+20 yp+25 Section", "open")
startButton := MyGui.AddButton("ys Section", "start")

statusBar := MyGui.AddStatusBar("xs", "Press ctrl+1 to output values")

; =======================================================================================
; ===================================== Label TAB =======================================

Tab.UseTab(2)

MyGui.AddGroupBox("w330 H70 Section cGray", "actions")

MyGui.SetFont("s12")
readButton := MyGui.AddButton("xp+10 yp+25 Section", "read")
writeButton := MyGui.AddButton("ys Section", "write")
MyGui.SetFont("s8")
MyGui.AddText("x50 y+2 cGray", "path: " . paths.csv.full)
MyGui.SetFont("s12")

MyGui.AddGroupBox("x38 y+5 w330 h275 cGray Section", "data")

MyGui.AddText("xp+15 yp+25 Section", "  Order#:")
labelData.order.gui := MyGui.AddEdit("ys w145", labelData.order.value)

MyGui.AddText("xs ys+35 Section", "     UPC:")
labelData.upc.gui := MyGui.AddEdit("ys w145", labelData.upc.value)

MyGui.AddText("xs ys+35 Section", "   QC By:")
labelData.initials.gui := MyGui.AddEdit("ys w50", labelData.initials.value)

MyGui.AddText("xs ys+35 Section", "    Date:")
labelData.date.gui := MyGui.AddEdit("ys w120", labelData.date.value)

MyGui.AddText("xs ys+35 Section", "    Roll:")
labelData.roll.gui := MyGui.AddEdit("ys w50", labelData.roll.value)
MyGui.AddUpDown("Range1-200 Wrap", labelData.roll.value)

MyGui.AddText("xs ys+35 Section", "     Qty:")
labelData.quantity.gui := MyGui.AddEdit("ys w70", labelData.quantity.value)

MyGui.AddText("xs ys+35 Section", "Customer:")
labelData.customer.gui := MyGui.AddEdit("ys w145", labelData.customer.value)

; =======================================================================================
; ==================================== Samples TAB ======================================

Tab.UseTab(3)
MyGui.AddGroupBox("x38 y+5 w330 h275 cGray Section", "data")

MyGui.AddText("xp+20 yp+30 Section", "Initials:")
sampleData.initials.gui := MyGui.AddEdit("ys w40 limit2", labelData.initials.value)

MyGui.AddText("xs Section", "Customer:")
sampleData.customer.gui := MyGui.AddEdit("ys w170", sampleData.customer.value)

MyGui.AddText("xs Section", "   Order:")
sampleData.order.gui := MyGui.AddEdit("ys w170", sampleData.order.value)

MyGui.AddText("xs Section", "   Style:")
sampleData.style.gui := MyGui.AddEdit("ys w170", sampleData.style.value)

MyGui.AddText("xs Section", "    Roll:")
sampleData.roll.gui := MyGui.AddEdit("ys w50", sampleData.roll.value)
MyGui.AddUpDown("Range1-200 Wrap", sampleData.roll.value)

MyGui.AddText("xs yp+50 Section Wrap w300 cBlue", "Press ctrl-2 to output sample values inputted here")

; =======================================================================================
; ==================================== Print TAB ======================================

Tab.UseTab(4)
MyGui.AddGroupBox("x38 y+5 w330 h165 cGray Section", "shortcuts")

MyGui.AddText("xp+20 yp+30 Section", "Initials:")
printdata.initials.gui := MyGui.AddEdit("ys w40 limit2", printData.initials.value)

MyGui.AddText("xs yp+50 Section Wrap w300 cBlue", "Press Alt + Numpad[0-9] to output [ZZ P-04] through [ZZ P-11], (Numpad1 is for P-11, Numpad0 is for P-10) ")

; =======================================================================================
; ==================================== SETTINGS TAB =====================================

Tab.UseTab(5)

MyGui.AddGroupBox("w330 H310 cGray Section", "general")

MyGui.AddText("xp+20 yp+45 Section", "Delay")
settings.delay.gui := MyGui.AddEdit("ys w80")
MyGui.AddUpDown("range1-9999 Wrap", settings.delay.value)

MyGui.AddText("ys", "ms")
settings.autoStyle.gui := MyGui.AddCheckBox("xs Section" . (settings.autoStyle.value ? " checked" : ""), "Auto Style")
settings.quickOrder.gui := MyGui.AddCheckBox("xs Section" . (settings.quickOrder.value ? " checked" : ""), "Quick Order")

MyGui.AddText("xs Section", "RFID Program:")
paths.rfid.gui := MyGui.addEdit("xs w280", paths.rfid.file)
;ToolTip("defualt paths.rfid.gui value: ", paths.rfid.gui.value)

MyGui.AddText("xs Section", "RFID program position:")
rfidChoose := "Choose" . settings.rfidWinPos.value
settings.rfidWinPos.gui := MyGui.AddDropDownList("xs Section w280 " . rfidChoose, ["default", "left half of monitor 1", "right half of monitor 1", "left half of monitor 2", "right half of monitor 2"])

; =======================================================================================

MyGui.Show("NA" . (dev ? "x-425 y190" : "")) ; if dev, diff location

; =======================================================================================
; ==================================== SETUP EVENTS =====================================
; =======================================================================================
For key, val in data.OwnProps()
    data.%key%.gui.onEvent("Change", onDataUpdated.Bind(key, val))

For key, val in labelData.OwnProps()
    labelData.%key%.gui.onEvent("Change", onLabelDataUpdated.Bind(key, val))

For key, val in sampleData.OwnProps()
    sampleData.%key%.gui.onEvent("Change", onSampleDataUpdated.bind(key, val))

printData.initials.gui.onEvent("Change", onPrintDataUpdated)

settings.autoStyle.gui.onEvent("Click", onAutoStyleUpdated)
settings.quickOrder.gui.onEvent("Click", onQuickOrderUpdated)
settings.delay.gui.onEvent("Change", onDelayUpdated)
paths.rfid.gui.onEvent("Change", onRfidProgramUpdated)
settings.rfidWinPos.gui.onEvent("Change", onRfidWinPosUpdated)

defaultButton.onEvent("Click", (*) => SendInput("{Tab}"))
openButton.onEvent("Click", onOpen)
startButton.onEvent("Click", onStart)
readButton.onEvent("Click", onRead)
writeButton.onEvent("Click", onWrite)

MyGui.OnEvent("Close", onClose)

~WheelUp:: {
    MouseGetPos(, , , &dateControl)
    if (dateControl = "edit12")
        dateChange(1)
}
~WheelDown:: {
    MouseGetPos(, , , &dateControl)
    if (dateControl = "edit12")
        dateChange(-1)
}

; =======================================================================================
; ===================================== FUNCTIONS =======================================
; =======================================================================================
onDataUpdated(key, val, *) {
    if (settings.autoStyle.gui.value && key = "upc")
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
    if (labelData.%key%.gui.value != labelData.%key%.readValue)
        labelData.%key%.gui.Opt("Backgrounddbe2fc")
    else
        labelData.%key%.gui.Opt("-Background")
}

resetLabelReadStatus(*) {
    for key, val in labelData.OwnProps() {
        labelData.%key%.readValue := labelData.%key%.gui.value
        labelData.%key%.gui.Opt("-Background")
    }

}

onSampleDataUpdated(key, val, *) {
    IniWrite(sampleData.%key%.gui.value, "config.ini", "sample", key)
}

onPrintDataUpdated(*) {
    IniWrite(printData.initials.gui.value, "config.ini", "print", "initials")
}


dateChange(num) {
    date := labelData.date.gui.value
    dates := StrSplit(date, "/")
    try {
        month := dates[1]
        day := dates[2]
        year := dates[3]
    } catch {
        return ToolTip("had an error splitting date")
    }
    if (StrLen(month) != 2 || StrLen(day) != 2 || StrLen(year) != 2) {
        return ToolTip("not proper lengths: month, day, length" . month . ", " . day . ", " . year)
    }

    newDate := DateAdd("20" . year . month . day, num, "days")

    labelData.date.gui.value := FormatTime(newDate, "MM/dd/yy")

    onLabelDataUpdated("date", date)
}


onAutoStyleUpdated(*) {
    val := settings.autoStyle.gui.value
    IniWrite(val, "config.ini", "settings", "autoStyle")
    if (val)
        lockStyle
    else
        unlockStyle
}

onQuickOrderUpdated(*) {
    IniWrite(settings.quickOrder.gui.value, "config.ini", "settings", "quickOrder")
    settings.quickOrder.value := settings.quickOrder.gui.value
    setupQuickOrder(settings.quickOrder.gui.value)
}

onDelayUpdated(*) {
    IniWrite(settings.delay.gui.value, "config.ini", "settings", "delay")
    settings.delay.value := settings.delay.gui.value
}

onRfidProgramUpdated(*) {
    IniWrite(paths.rfid.gui.value, "config.ini", dev ? "debug" : "paths", "rfidFile")
    paths.rfid.file := paths.rfid.gui.value
}

setupQuickOrder(val) {
    data.preOrder.gui.Visible := val
    data.postOrder.gui.Visible := val
    data.order.gui.visible := !val
}

onRfidWinPosUpdated(*) {
    IniWrite(settings.rfidWinPos.gui.value, "config.ini", "settings", "rfidWinPos")
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

onStart(*) {
    onOpen()
    ctrl := ControlGetFocus("A")
    f_ctrl := ControlGetClassNN(ctrl)
    printToCtrl(ctrl)
}

onOpen(*) {
    ; ahk_class: ConsoleWindowClass
    ; ahk_exe: cmd.exe
    ; title: Selet RFIDQAR420 - 420

    ; shell := ComObject("WScript.Shell")
    ; exec := shell.Exec(A_ComSpec " /C " "whoami")
    ; output := exec.StdOut.ReadAll()
    ; MsgBox(output)

    currentHwnd := WinGetID("A")
    currentPid := WinGetPID("A")

    n := 0
    n := WinGetList("ahk_exe cmd.exe").length
    if dev
        ToolTip("num of windows: " . n)


    pid := 0
    Run(paths.rfid.full, paths.rfid.dir, , &pid)
    Sleep(500)


    hwnd := WinWait("ahk_exe cmd.exe", , 3)
    if (hwnd = 0)
        return MsgBox("WinWait timed out")

    if (settings.rfidWinPos.gui.value = 2)
        moveToArea(1, "left")
    else if (settings.rfidWinPos.gui.value = 3)
        moveToArea(1, "right")
    else if (settings.rfidWinPos.gui.value = 4)
        moveToArea(2, "left")
    else if (settings.rfidWinPos.gui.value = 5)
        moveToArea(2, "right")

    ;n := WinGetList("ahk_exe cmd.exe").length
    ;ToolTip("num of windows: " . n)

    ; SNIPPET
    /*     WinTitle := 'ahk_exe Notepad.exe'
        hWnd := runAndWaitForInstance('Notepad', winTitle)
        MsgBox hWnd, 'HWND', 'Iconi'
    
        runAndWaitForInstance(commandLine, winTitle) {
            before := WinGetList(winTitle).Length
            Run commandLine
            Loop
                Sleep(30), win := WinGetList(winTitle)
            Until win.Length > before
            Return win[1]
        }
    */

    ;ToolTip("currPID " . currentPid . "`tcurrHwnd: " . currentHwnd . "`npid: " . pid . "`t`thwnd: " . hwnd)

    ;if (WinActive("ahk_pid " pid)) {
    ;sleep(1)
    ;statusBar.SetText("IS ACTIVATE")
    ;}
    ;else {
    ;sleep(1)
    ;WinActivate("ahk_pid " pid)
    ;statusBar.SetText("NOT ACTIVE")
    ;}

    ;WinActivate("ahk_pid " pid)

    ;list := WinGetControls("ahk_pid " pid)
    ;statusBar.SetText("control list: " . list.Length)

    ;list := WinGetControls("ahk_id " hwnd)
    ;out := "test: "
    ;for index, val in list
    ;out .= ", " . val
    ;ToolTip(list[0])
}

moveToArea(monitor_num, side) {
    MonitorGetWorkArea monitor_num, &left1, &top1, &right1, &bot1
    width := (right1 - left1) / 2
    height := bot1 - top1
    x := (side = "left") ? left1 : left1 + width
    y := top1

    WinMove(x, y, width, height, "A")
}

onRead(*) {
    csv := {}

    try {
        Loop read, paths.csv.full {
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
        MsgBox("An error occured:`n`n" . e.Message . "`n`nPlease check that the path is correct: " . paths.csv.full . "`nAlso check that the csv file is in the correct format.")
        return
    }

    updateCsv(csv)
    saveCsv(csv)
    resetLabelReadStatus()
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
    labelData.upc.gui.value := csv.UPC.value
    labelData.initials.gui.value := csv.%"QC By"%.value
    labelData.date.gui.value := csv.Date.value
    labelData.roll.gui.value := csv.%"Roll #"%.value
    labelData.quantity.gui.value := csv.Qty.value
    labelData.customer.gui.value := csv.Customer.value
}

onWrite(*) {
    try {
        file := FileOpen(paths.csv.full, "w") ; TODO: add path option
        out := ""

        out .= "`"Order#`",`"UPC`",`"QC By`",`"Date`",`"Roll #`",`"Qty`",`"Customer`"`n"
        out .= "`"" . labelData.order.gui.value . "`"" . ","
        out .= "`"" . labelData.upc.gui.value . "`"" . ","
        out .= "`"" . labelData.initials.gui.value . "`"" . ","
        out .= "`"" . labelData.date.gui.value . "`"" . ","
        out .= "`"" . labelData.roll.gui.value . "`"" . ","
        out .= "`"" . labelData.quantity.gui.value . "`"" . ","
        out .= "`"" . labelData.customer.gui.value . "`""

        file.Write(out)
        file.Close()

        for key, val in labelData.OwnProps() ; else it isn't clearing background
            labelData.%key%.gui.value := labelData.%key%.gui.value
        resetLabelReadStatus()
    } catch as e {
        MsgBox("An error ocurred: `n", e)
    }

}

onPrint(*) {
    inputDelay := settings.delay.gui.value

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

onSamplePrint(*) {
    inputDelay := settings.delay.gui.value

    SendInput sampleData.initials.gui.value "{enter}"
    Sleep inputDelay
    SendInput sampleData.customer.gui.value "{enter}"
    Sleep inputDelay
    SendInput sampleData.order.gui.value "{enter}"
    Sleep inputDelay
    SendInput "{enter}"
    Sleep inputDelay
    SendInput sampleData.style.gui.value "{enter}"
    Sleep inputDelay
    SendInput sampleData.roll.gui.value "{enter}"
    Sleep inputDelay
    SendInput "Y{enter}"
    Sleep inputDelay
    SendInput "N{enter}"
    Sleep inputDelay
    SendInput "Y{enter}"
    Sleep inputDelay
}

printToCtrl(ctrl) {
    ctrlSendSleep(data.initials.gui.value "{enter}", ctrl)
    ctrlSendSleep(data.customer.gui.value "{enter}", ctrl)
    ctrlSendSleep(data.order.gui.value "{enter}", ctrl)
    ctrlSendSleep(data.upc.gui.value "{enter}", ctrl)
    ctrlSendSleep(data.style.gui.value "{enter}", ctrl)
    ctrlSendSleep(data.roll.gui.value "{enter}", ctrl)
    ctrlSendSleep("Y{enter}", ctrl)
    ctrlSendSleep("N{enter}", ctrl)
    ctrlSendSleep("Y{enter}", ctrl)
}

ctrlSendSleep(text, ctrl) {
    ControlSend(text, ctrl)
    Sleep data.delay.gui.value
}

onClose(*) {
    if not (dev)
        ExitApp
}

#HotIf WinActive("ahk_exe cmd.exe") or WinActive("ahk_exe WindowsTerminal.exe") or WinActive("ahk_class Notepad") or WinActive("ahk_exe WINWORD.EXE")
^1:: onPrint()
^2:: onSamplePrint()

#HotIf WinActive("ahk_class XLMAIN")
!Numpad1:: SendInput printData.initials.gui.value . " P-11+{enter}{enter}"
!Numpad4:: SendInput printData.initials.gui.value . " P-04+{enter}{enter}"
!Numpad5:: SendInput printData.initials.gui.value . " P-05+{enter}{enter}"
!Numpad6:: SendInput printData.initials.gui.value . " P-06+{enter}{enter}"
!Numpad7:: SendInput printData.initials.gui.value . " P-07+{enter}{enter}"
!Numpad8:: SendInput printData.initials.gui.value . " P-08+{enter}{enter}"
!Numpad9:: SendInput printData.initials.gui.value . " P-09+{enter}{enter}"
!Numpad0:: SendInput printData.initials.gui.value . " P-10+{enter}{enter}"

#HotIf true

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

    ; DEBUG
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
