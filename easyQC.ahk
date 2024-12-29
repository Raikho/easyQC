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
; colors
PALE_BLUE := "eef2ff"
NAVY_BLUE := "4d6d9a"

data := {
	initials: { value: "..", displayName: "Initials"},
	customer: { value: "<customer>", displayName: "Customer"},
	order: { value: "20010....", displayName: "Order"},
	upc: { value: "............", displayName: "UPC"},
	style: { value: "....", displayName: "Style"},
	roll: { value: "1", displayName: "Roll"},
}
populatePropNames(data)
populateFromIni(data, "main")

IniWrite("TEST", "config.ini", "main", "customer")

; =======================================================================================
; ===================================== CREATE GUI ======================================
; =======================================================================================

MyGui := Gui()
setupGuiAppearance(MyGui)

defaultTab := 1
setupTabs(MyGui, defaultTab)

setupMainTab(MyGui)

MyGui.Show(Format("w{1} h{2} x{3} y{4}", WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_X, WINDOW_Y))

; =======================================================================================
; ===================================== FUNCTIONS =======================================
; =======================================================================================

populatePropNames(obj) {
	for key, val in obj.OwnProps() {
		data.%key%.propName := key
	}
}

populateFromIni(obj, section) {
	for key, val in obj.OwnProps() {
		data.%key%.value := IniRead("config.ini", section, key, val.value)
	}
}

setupGuiAppearance(gui) {
	gui.Title := devMode ? "easyQC - dev mode" : "easyQC"
	gui.SetFont("s" . FONT_SIZE, "Verdana")
	gui.SetFont("s" . FONT_SIZE, "Courier")
	gui.SetFont("s" . FONT_SIZE, "Courier New")
}

setupTabs(gui, defaultTab) {
	MyGui.SetFont("s" . TAB_FONT_SIZE)
	Tab := gui.AddTab3("-wrap choose" . defaultTab, ["MAIN"])
	MyGui.SetFont("s" . FONT_SIZE)
}

setupMainTab(gui) {
	gui.AddGroupBox("w330 h275 cGray Section", "data")

	; INITIALS
	textOpt := { xPrev: 20, yPrev: 20, newSection: true }
	editOpt := { uppercase: true, charLmit: 2, ySection: 0, width: 40, background: PALE_BLUE }
	createEdit(gui, data.initials, textOpt, editOpt)

	; CUSTOMER
	textOpt := { xSection: 0, newSection: true }
	editOpt := {  ySection: 0, width: 170, background: PALE_BLUE }
	createEdit(gui, data.customer, textOpt, editOpt)

	; Order
	textOpt := { xSection: 0, newSection: true }
	editOpt := {  number: true, charLimit: 9, ySection: 0, width: 130, background: PALE_BLUE }
	createEdit(gui, data.order, textOpt, editOpt)

	; UPC
	textOpt := { xSection: 0, newSection: true }
	editOpt := {  number: true, charLimit: 12, ySection: 0, width: 170, background: PALE_BLUE }
	createEdit(gui, data.upc, textOpt, editOpt)

	; STYLE
	textOpt := { xSection: 0, newSection: true }
	editOpt := { number: true, charLimit: 4, ySection: 0, width: 60, background: PALE_BLUE }
	createEdit(gui, data.style, textOpt, editOpt)

	; ROLL
	textOpt := { xSection: 0, newSection: true }
	editOpt := { charLimit: 12, ySection: 0, width: 70, background: NAVY_BLUE, center: True }
	fontOpt := { bold: true, foreground: PALE_BLUE, fontName: "Arial"}
	createEdit(gui, data.roll, textOpt, editOpt, fontOpt)
	gui.AddUpDown("Range1-200 Wrap", data.roll.value)
}

createEdit(gui, obj, textOptions, editboxOptions, fontOptions?) {
	displayName := Format("{:8}", obj.displayName) . ":" ;; align right 8 characters

	gui.AddText(formatOptions(textOptions), displayName)
	obj.gui := gui.AddEdit(formatOptions(editboxOptions), obj.value)

	if (IsSet(fontOptions))
		obj.gui.setFont(formatOptions(fontOptions),
	fontOptions.hasProp("fontName") ? fontOptions.fontName : "")

	obj.gui.onEvent("Change", updateData.Bind(obj.propName))
}

updateData(key, *) {
	IniWrite(data.%key%.gui.value, "config.ini", "main", key)
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

	if (obj.HasProp("newSection"))
		str .= "Section" . " "

	if (obj.HasProp("background"))
		str .= "background" . obj.background . " "
	if (obj.HasProp("charLimit"))
		str .= "limit" . obj.charLimit . " "
	if (obj.HasProp("uppercase"))
		str .= "Uppercase" . " "
	if (obj.HasProp("number"))
		str .= "number" . " "
	if (obj.HasProp("center"))
		str .= "center" . " "
	if(obj.HasProp("fontSize"))
		str .= "s" . obj.fontSize . " "
	if (obj.HasProp("foreground"))
		str .= "c" . obj.foreground . " "
	if (obj.HasProp("bold"))
		str .= "bold" . " "

	return str
}	