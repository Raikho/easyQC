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
}
