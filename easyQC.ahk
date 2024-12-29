; TODO:


#Requires AutoHotkey v2.0
#SingleInstance force

; =======================================================================================
; ==================================== LOAD VARIABLES ===================================
; =======================================================================================

window := {}
window.width := 400
window.height := 400
window.x := -600
window.y := 160

FONT_SIZE := 14
TAB_FONT_SIZE := 11

data := {
	initials: { value: "..", displayName: "Initials"},
	customer: { value: "<customer>", displayName: "Customer"},
	order: { value: "20010....", displayName: "Order"},
	upc: { value: "............", displayName: "UPC"},
	style: { value: "....", displayName: "Style"},
	roll: { value: "1", displayName: "Roll"},
}

PALE_BLUE := "eef2ff"
NAVY_BLUE := "4d6d9a"

; =======================================================================================
; ===================================== CREATE GUI ======================================
; =======================================================================================

MyGui := Gui()
setupGuiAppearance(MyGui)

MyGui.SetFont("s" . TAB_FONT_SIZE)
defaultTab := 1
Tab := MyGui.AddTab3("-wrap choose" . defaultTab, ["Main"])
MyGui.SetFont("s" . FONT_SIZE)

setupMainTab(MyGui)


MyGui.Show(Format("w{1} h{2} x{3} y{4}", window.width, window.height, window.x, window.y))

; =======================================================================================
; ===================================== FUNCTIONS =======================================
; =======================================================================================

setupGuiAppearance(gui) {
	gui.Title := "easyQC" ; TODO: change for dev mode
	gui.SetFont("s" . FONT_SIZE, "Verdana")
	gui.SetFont("s" . FONT_SIZE, "Courier")
	gui.SetFont("s" . FONT_SIZE, "Courier New")
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

	; UPC
	textOpt := { xSection: 0, newSection: true }
	editOpt := {  number: true, charLimit: 12, ySection: 0, width: 170, background: PALE_BLUE }
	createEdit(gui, data.upc, textOpt, editOpt)

	; Order
	textOpt := { xSection: 0, newSection: true }
	editOpt := {  number: true, charLimit: 9, ySection: 0, width: 130, background: PALE_BLUE }
	createEdit(gui, data.order, textOpt, editOpt)

	; STYLE
	textOpt := { xSection: 0, newSection: true }
	editOpt := { number: true, charLimit: 4, ySection: 0, width: 60, background: PALE_BLUE }
	createEdit(gui, data.style, textOpt, editOpt)

	; ROLL
	textOpt := { xSection: 0, newSection: true }
	editOpt := { charLimit: 12, ySection: 0, width: 70,
		background: NAVY_BLUE, center: True }
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