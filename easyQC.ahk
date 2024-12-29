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
window.y := 300

data := {
	initials: { value: "..", displayName: "Initials"},
	customer: { value: "<customer>", displayName: "Customer"},
	order: { value: "20010....", displayName: "Order"},
	upc: { value: "............", displayName: "UPC"},
	style: { value: "....", displayName: "Style"},
	roll: { value: "1", displayName: "Roll"},
}

PALE_BLUE := "eef2ff"

; =======================================================================================
; ===================================== CREATE GUI ======================================
; =======================================================================================

MyGui := Gui()
setupGuiAppearance(MyGui)

defaultTab := 1
Tab := MyGui.AddTab3("-wrap choose" . defaultTab, ["Main"])

setupMainTab(MyGui)


MyGui.Show(Format("w{1} h{2} x{3} y{4}", window.width, window.height, window.x, window.y))

; =======================================================================================
; ===================================== FUNCTIONS =======================================
; =======================================================================================

setupGuiAppearance(gui) {
	gui.Title := "easyQC" ; TODO: change for dev mode
	gui.SetFont("s14", "Verdana")
	gui.SetFont("s14", "Courier")
	gui.SetFont("s14", "Courier New")
	gui.SetFont("s11")
}

setupMainTab(gui) {
	gui.AddGroupBox("w330 h275 cGray Section", "data")

	textOpt := { xPrev: 20, yPrev: 20, section: true }
	editOpt := { uppercase: true, charLmit: 2, ySection: 0, width: 40, background: PALE_BLUE }
	createEdit(MyGui, data.initials, opt(textOpt), opt(editOpt))


}

createEdit(gui, obj, textOptions, editboxOptions) {
	displayName := Format("{:8}", obj.displayName) . ":" ;; align right 8 characters

	gui.AddText(formatOptions(textOptions), displayName)
	obj.gui := gui.AddEdit(formatOptions(editboxOptions), obj.value)
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

	if (obj.HasProp("section"))
		str .= "Section" . " "

	if (obj.HasProp("background"))
		str .= "background" . obj.background . " "
	if (obj.HasProp("charLimit"))
		str .= "limit" . obj.charLimit . " "
	if (obj.HasProp("uppercase"))
		str .= "Uppercase" . " "

	return str
}	