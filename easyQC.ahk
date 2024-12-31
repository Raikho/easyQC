#Requires AutoHotkey v2.0
#SingleInstance force

; =======================================================================================
; ==================================== LOAD VARIABLES ===================================
; =======================================================================================

devMode := IniRead("config.ini", "debug", "devMode", 0)

; constants
WINDOW_WIDTH := 400
WINDOW_HEIGHT :=  400
WINDOW_X := devMode ? -600 : 0
WINDOW_Y := devMode ? 160 : 0
FONT_SIZE := 14
TAB_FONT_SIZE := 10
DEFAULT_TAB := devMode ? 1 : 1
; colors
PALE_BLUE := "eef2ff"
NAVY_BLUE := "4d6d9a"

data := {
	initials: { value: "..", displayName: "Initials" },
	customer: { value: "<customer>", displayName: "Customer" },
	preOrder: { value: "20010", displayName: "Order" },
	postOrder: { value: "....", displayName: "" },
	order: { value: "20010....", displayName: "Order" },
	upc: { value: "............", displayName: "UPC" },
	style: { value: "....", displayName: "Style" },
	roll: { value: "1", displayName: "Roll" },
}
setupForIni(data, "main")
populateFromIni(data) 

settings := {
	delay: { value: 100, displayName: "Delay (ms)" },
	autoStyle : { value: 0, displayName: "Auto Style" },
	quickOrder: { value: 0, displayName: "Quick Order" },
}
setupForIni(settings, "settings")
populateFromIni(settings)

; =======================================================================================
; ===================================== CREATE GUI ======================================
; =======================================================================================

myGui := Gui("+0x40000") ; resizable
setupGuiAppearance()

Tab := setupTabs()
setupMainTab()
setupSettingsTab()

statusBar := myGui.AddStatusBar("xs", "Press ctrl+1 to output values")
statusBar.SetFont("s10")

myGui.OnEvent("Close", (*) => ExitApp)
myGui.Show(Format(devMode ? "w{1} h{2} x{3} y{4}" : "w{1} h{2}",
	WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_X, WINDOW_Y))

; =======================================================================================
; ===================================== FUNCTIONS =======================================
; =======================================================================================

setupForIni(items, section) {
	for (key, item in items.OwnProps()) {
		item.iniName := key
		item.iniSection := section
	}
}
populateFromIni(items) {
	for (key, item in items.OwnProps()) {
 		item.value := IniRead("config.ini", item.iniSection, item.iniName, item.value)
	}
}
saveItem(item) {
	switch item.iniName {
		case "order":
		data.postOrder.gui.value := SubStr(item.gui.value, -4)
		writeItem(data.postOrder)

		case "postOrder" :
		data.order.gui.value := "20010" . item.gui.value
		writeItem(data.order)

		case "quickOrder" :
		updateQuickOrderVisibility()
	}

	writeItem(item)
}
writeItem(item) {
	IniWrite(item.gui.value, "config.ini", item.iniSection, item.iniName)
}
readItem(item) {
	return IniRead("config.ini", item.iniSection, item.iniName, item.value)
}
clearItems(items) {
	for key, item in items.OwnProps() {
		if (!item.gui.Enabled)
			continue
		item.gui.value := ""
		saveItem(item)
	}
}

setupGuiAppearance() {
	myGui.Title := devMode ? "easyQC - dev mode" : "easyQC"
	myGui.SetFont("s" . FONT_SIZE, "Verdana")
	myGui.SetFont(, "Courier")
	myGui.SetFont(, "Courier New")
}

setupTabs() {
	myGui.SetFont("s" . TAB_FONT_SIZE)
	Tab := myGui.AddTab3("-wrap choose" . DEFAULT_TAB, ["Main", "Settings"])
	myGui.SetFont("s" . FONT_SIZE)
	return Tab
}

setupMainTab() {
	myGui.AddGroupBox("w330 h275 cGray Section", "data")

	; INITIALS
	textOpt := { xPrev: 20, yPrev: 30, newSection: true }
	editOpt := { uppercase: true, charLimit: 2, ySection: 0, width: 40, background: PALE_BLUE }
	createEdit(data.initials, textOpt, editOpt)

	; CUSTOMER
	textOpt := { xSection: 0, newSection: true }
	editOpt := { ySection: 0, width: 170, background: PALE_BLUE }
	createEdit(data.customer, textOpt, editOpt)

	; ============================ ORDER ============================
	; ===============================================================

	textOpt := { xSection: 0, newSection: true }
	editOpt := { number: true, charLimit: 9, ySection: 0, width: 130, background: PALE_BLUE }
	createEdit(data.order, textOpt, editOpt)

	editOpt := { number: true, charLimit: 5, xPrev: 0, ySection: 0, width: 82 }
	createEditboxOnly(data.preOrder, editOpt)
	editOpt := { number: true, charLimit: 4, xPrev: 100, ySection: 0, width: 70, background: PALE_BLUE }
	createEditboxOnly(data.postOrder, editOpt)

	updateQuickOrderVisibility()

	; ===============================================================
	; ===============================================================

	; UPC
	textOpt := { xSection: 0, newSection: true }
	editOpt := { number: true, charLimit: 12, ySection: 0, width: 170, background: PALE_BLUE }
	createEdit(data.upc, textOpt, editOpt)

	; STYLE
	textOpt := { xSection: 0, newSection: true }
	editOpt := { number: true, charLimit: 4, ySection: 0, width: 60, background: PALE_BLUE }
	createEdit(data.style, textOpt, editOpt)

	; ROLL
	textOpt := { xSection: 0, newSection: true }
	editOpt := { charLimit: 12, ySection: 0, width: 70, background: NAVY_BLUE, center: True }
	fontOpt := { bold: true, foreground: PALE_BLUE, fontName: "Arial"}
	createEdit(data.roll, textOpt, editOpt, fontOpt)
	myGui.AddUpDown("Range1-200 Wrap", data.roll.value)

	buttonOpt := { xPrev: 140, yPrev: 30, width: 50, height: 30}
	fontOpt := { fontSize: 8 }
	CREATEBUTTON(BUTTONOPT, "CLEAR", (*) => CLEARITEMS(data), fontOpt)

	setupPressEnterForNextItem()
}

setupSettingsTab() {
	Tab.UseTab(2)

	myGui.AddGroupBox("w330 h310 cGray Section", "general")

	textOpt := { xPrev: 20, yPrev: 30, newSection: true }
	editOpt := {ySection: 0, width: 80}
	createEdit(settings.delay, textOpt, editOpt)
	myGui.AddUpDown("range1-9999 Wrap", settings.delay.value)

	opt := { xSection: 0, newSection: true, checked: settings.autoStyle.value}
	createCheckbox(settings.autoStyle, opt)

	opt := { xSection: 0, newSection: true, checked: settings.quickOrder.value}
	createCheckbox(settings.quickOrder, opt)
}

setupPressEnterForNextItem() {
	defaultButton := MyGui.AddButton("ys Default", "button")
	defaultButton.Visible := false
	defaultButton.onEvent("Click", (*) => SendInput("{Tab}"))
}

createEditboxOnly(item, editboxOptions) {
	item.gui := myGui.AddEdit(formatOptions(editboxOptions), item.value)

	item.gui.onEvent("Change", (*) => saveItem(item))
}

createEdit(item, textOptions, editboxOptions, fontOptions?) {
	displayName := Format("{:8}", item.displayName) . ":" ;; align right 8 characters

	if (!(textOptions.hasProp("hide") && textOptions.hide))
		item.textGui := myGui.AddText(formatOptions(textOptions), displayName)
	item.gui := myGui.AddEdit(formatOptions(editboxOptions), item.value)

	if (IsSet(fontOptions))
		item.gui.setFont(formatOptions(fontOptions), fontOptions.hasProp("fontName") ? fontOptions.fontName : "")

	item.gui.onEvent("Change", (*) => saveItem(item))
}
createButton(buttonOptions, name, my_function, fontOptions?) {
	btn := myGui.AddButton(formatOptions(buttonOptions), name)
	btn.Opt("+Default")
	btn.onEvent("Click", my_function)

	if (IsSet(fontOptions))
		btn.setFont(formatOptions(fontOptions),
	fontOptions.hasProp("fontName") ? fontOptions.fontName : "")
}
createCheckbox(item, options) {
	item.gui := myGui.AddCheckBox(formatOptions(options), item.displayName)
	item.gui.onEvent("Click", (*) => saveItem(item))
}

updateQuickOrderVisibility() {
	if (settings.quickOrder.HasProp("gui"))
		quickOrder := settings.quickOrder.gui.value
	else
		quickOrder := readItem(settings.quickOrder)
	data.order.gui.Visible := !quickOrder
	data.preOrder.gui.Visible := quickOrder
	data.postOrder.gui.Visible := quickOrder 
}

formatOptions(obj) {
	str := ""
	if (obj.HasProp("xPrev"))
		str .= "xp" . "+" . obj.xPrev . " "
	if (obj.HasProp("yPrev"))
		str .= "yp" . "+" . obj.yPrev . " "
	if (obj.HasProp("xSection"))
		str .= "xs" . "+" . obj.xSection . " "
	if (obj.HasProp("ySection"))
		str .= "ys" . "+" . obj.ySection . " "

	if (obj.HasProp("width"))
		str .= "w" . obj.width . " "
	if (obj.HasProp("height"))
		str .= "h" . obj.height . " "

	if (obj.HasProp("newSection") && obj.newSection)
		str .= "Section" . " "

	if (obj.HasProp("background"))
		str .= "background" . obj.background . " "
	if (obj.HasProp("charLimit"))
		str .= "limit" . obj.charLimit . " "
	if (obj.HasProp("uppercase") && obj.uppercase)
		str .= "Uppercase" . " "
	if (obj.HasProp("number"))
		str .= "number" . " "
	if (obj.HasProp("center") && obj.center)
		str .= "center" . " "
	if(obj.HasProp("fontSize"))
		str .= "s" . obj.fontSize . " "
	if (obj.HasProp("foreground"))
		str .= "c" . obj.foreground . " "
	if (obj.HasProp("bold") && obj.bold)
		str .= "bold" . " "
	if (obj.HasProp("checked") && obj.checked == 1)
		str .= "checked" . " "

	return str
}

; =======================================================================================
; ====================================== HOTKEYS ========================================
; =======================================================================================

#HotIf exeActive("cmd.exe", "WindowsTerminal.exe", "emacs.exe", "sublime_text.exe") or classActive("Notepad")
^1::onPrint()

onPrint(*) {
	inputDataAndSleep(data.initials.gui.value)
	inputDataAndSleep(data.customer.gui.value)
	inputDataAndSleep(data.order.gui.value)
	inputDataAndSleep(data.upc.gui.value)
	inputDataAndSleep(data.style.gui.value)
	inputDataAndSleep(data.roll.gui.value)
	inputDataAndSleep("Y")
	inputDataAndSleep("N")
	inputDataAndSleep("Y")
}
inputDataAndSleep(obj) {
	if classActive("XLMAIN", "Chrome_WidgetWin_1") {
		return
	}
	SendInput(obj . "{enter}")
	Sleep(150)
}

exeActive(params*) {
	for index, exe in params
	if (WinActive("ahk_exe " . exe))
		return true
	return false
}
classActive(params*) {
	for index, cls in params
	if (WinActive("ahk_class " . cls))
		return true
	return false
}

