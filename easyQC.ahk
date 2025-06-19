#Requires AutoHotkey v2.0
#SingleInstance force
; =======================================================================================
; ==================================== LOAD VARIABLES ===================================
; =======================================================================================

devMode := IniRead("config.ini", "debug", "devMode", 0)

; CONSTANTS
WINDOW_WIDTH := 371
WINDOW_HEIGHT :=  400
WINDOW_X := devMode ? -600 : 0
WINDOW_Y := devMode ? 160 : 0
FONT_SIZE := 14
TAB_FONT_SIZE := 10
DEFAULT_TAB := devMode ? 2 : 2
tabTitles := [ "Main", "Samples", "Label", "Settings"]
tabStatusMessages := ["Press ctrl+1 to output values", "Press ctrl+2 to output values, w/ blank upc", "", ""]
; COLORS
PALE_BLUE := "eef2ff"
NAVY_BLUE := "4d6d9a"
SOLAR_BLUE := "268bd2"
LIGHT_ORANGE := "fed7aa"
PALE_ORANGE := "fdebd0"
DARK_ORANGE := "d57d55" ;"94755c", af8561, 946a6c, 9d816c
DARK_YELLOW := "99873e" ; d4ac0d
SLATE := "94a3b8"
LIGHT_STONE := "e7e5e4"

; GLOBAL VARIABLES TODO: use object.base to move more options to this section
data := {
	initials: { value: "..", displayName: "Initials", bg: PALE_BLUE, bgChanged: PALE_ORANGE },
	customer: { value: "<customer>", displayName: "Customer", bg: PALE_BLUE, bgChanged: PALE_ORANGE },
	preOrder: { value: "20010", displayName: "Order" },
	postOrder: { value: "....", displayName: "", bg: PALE_BLUE, bgChanged: PALE_ORANGE },
	order: { value: "20010....", displayName: "Order", bg: PALE_BLUE, bgChanged: PALE_ORANGE },
	upc: { value: "............", displayName: "UPC", bg: PALE_BLUE, bgChanged: PALE_ORANGE },
	style: { value: "....", displayName: "Style", bg: PALE_BLUE, bgChanged: PALE_ORANGE },
	roll: { value: "1", displayName: "Roll", bg: NAVY_BLUE, bgChanged: DARK_ORANGE },
}
setupForIni(data, "main", hasPreviousValues := true)

settings := {
	delay: { value: 100, displayName: "Delay (ms)" },
	autoStyle : { value: 0, displayName: "Auto Style" },
	quickOrder: { value: 0, displayName: "Quick Order" },
	orderPrefix: { value: "20010", displayName: "Prefix" }, 
	enableFixes: { value: 1, displayname: "Enable Label Fixing" },
	enableSampleButtons: { value: 0, displayname: "Enable Shortage Buttons" }, ; TODO: rename all "Sample" to "Shortage"
}
setupForIni(settings, "settings")

sampleData := {
	initials:     { value: "ZZ", displayName: "Initials", bg: PALE_BLUE, bgChanged: PALE_ORANGE },
	roll:         { value: "1", displayName: "Roll #", bg: PALE_BLUE, bgChanged: PALE_ORANGE, fg: "000000" },
	customer:     { value: "HILLMAN", displayName: "Customer", bg: PALE_BLUE, bgChanged: PALE_ORANGE },
	order:        { value: "HILLMAN-", displayName: "Order" },
	date:         { value: "-1-1-25", displayName: "", bg: PALE_BLUE, bgChanged: PALE_ORANGE },
	style:        { value: "TAGEOS", displayName: "Style", index: 0, bg: PALE_BLUE, bgChanged: PALE_ORANGE },
	rollId:       { value: "Hillm001", displayName: "Roll Id", bg: PALE_BLUE, bgChanged: PALE_ORANGE },
	styleFilter:  { value: 0},
}
setupForIni(sampleData, "samples", hasPreviousValues := true)

sampleData.styleFilter.titles := ["All", "Tageos", "Paragon", "Arizon", "Avery",
"430", "402", "430", "300", "261", "241", "M7", "M8", "R6", "U8", "U9"]

inlays := {}
for i, v in sampleData.styleFilter.titles {
	inlays.DefineProp(v, { value: Array()})
}
inlays.names := []

inlays.All := [
    { name: "Tageos 241 M7",          brand: "Tageos",  inlay: "241", chip: "M7" },
    { name: "Tageos 241 M8",          brand: "Tageos",  inlay: "241", chip: "M8" },
    { name: "Tageos 241 U9",          brand: "Tageos",  inlay: "241", chip: "U9" },
    { name: "Tageos 261 M7",          brand: "Tageos",  inlay: "261", chip: "M7" },
    { name: "Tageos 261 M8",          brand: "Tageos",  inlay: "261", chip: "M8" },
    { name: "Tageos 261 U9",          brand: "Tageos",  inlay: "261", chip: "U9" },
    { name: "Tageos 300 M7",          brand: "Tageos",  inlay: "300", chip: "M7" },
    { name: "Tageos 300 R6",          brand: "Tageos",  inlay: "300", chip: "R6" },
	{ name: "Tageos 300 U8",          brand: "Tageos",  inlay: "300", chip: "U8" },
    { name: "Tageos 300 U9 Zero Max", brand: "Tageos",  inlay: "300", chip: "U9" },
    { name: "Tageos 300 U9",          brand: "Tageos",  inlay: "300", chip: "U9" },
    { name: "Tageos 402 R6",          brand: "Tageos",  inlay: "402", chip: "R6" },
    { name: "Tageos 402 R6-P",        brand: "Tageos",  inlay: "402", chip: "R6" },
    { name: "Tageos 430 M7",          brand: "Tageos",  inlay: "430", chip: "M7" },
    { name: "Tageos 430 M8",          brand: "Tageos",  inlay: "430", chip: "M8" },
    { name: "Tageos 430 U9",          brand: "Tageos",  inlay: "430", chip: "U9" },
    { name: "Arizon 300 M7",          brand: "Arizon",  inlay: "300", chip: "M7" },
    { name: "Arizon 300 M8",          brand: "Arizon",  inlay: "300", chip: "M8" },
    { name: "Arizon 430 M7",          brand: "Arizon",  inlay: "430", chip: "M7" },
    { name: "Arizon 430 M8",          brand: "Arizon",  inlay: "430", chip: "M8" },
    { name: "Paragon 261 M7",         brand: "Paragon", inlay: "261", chip: "M7" },
    { name: "Paragon 300 M7",         brand: "Paragon", inlay: "300", chip: "M7" },
    { name: "Paragon 300 R6-P",       brand: "Paragon", inlay: "300", chip: "R6" },
    { name: "Paragon 402 R6-P",       brand: "Paragon", inlay: "402", chip: "R6" },
    { name: "Paragon 430 M7",         brand: "Paragon", inlay: "430", chip: "M7" },
    { name: "Avery 241 M7",           brand: "Avery",   inlay: "241", chip: "M7" },
    { name: "Avery 241 M8",           brand: "Avery",   inlay: "241", chip: "M8" },
    { name: "Avery 261 M8 Sonic",     brand: "Avery",   inlay: "261", chip: "M8" },
    { name: "Avery 261 U9 Sonic",     brand: "Avery",   inlay: "261", chip: "U9" },
    { name: "Avery 300 M7",           brand: "Avery",   inlay: "300", chip: "M7" },
    { name: "Avery 300 U9",           brand: "Avery",   inlay: "300", chip: "U9" },
    { name: "Avery 402 M7",           brand: "Avery",   inlay: "402", chip: "M7" },
    { name: "Avery 402 M8 Burst",     brand: "Avery",   inlay: "402", chip: "M8" },
    { name: "Avery 402 U9",           brand: "Avery",   inlay: "402", chip: "U9" },
    { name: "Avery 430 U9 Longbow",   brand: "Avery",   inlay: "430", chip: "U9" },
]

for i, inlay in inlays.All {
		inlays.names.Push(inlay.name)
		inlays.%inlay.brand%.Push(inlay.name)
		inlays.%inlay.inlay%.Push(inlay.name)
		inlays.%inlay.chip%.Push(inlay.name)
}

;out := "output: `n"
;for i, name in inlays.Tageos {
;	out .= name . "`n"
;}
;MsgBox(out)

labelData := {
	order: { value: "'20010....", displayName: "Order#", index: 1, fixes: ["add_apostrophe"] },
 	upc: { value: "'............", displayName: "UPC", index: 2, fixes: ["add_apostrophe"] },
 	initials: { value: "'..", displayName: "QC By", index: 3, fixes: ["add_apostrophe", "caps"] },
 	date: { value: "../../....", displayName: "Date", index: 4, fixes: ["fix_date"] },
	roll: { value: "1", displayName: "Roll #", index: 5, fixes: ["remove_shortage"] },
 	quantity: { value: "0", displayName: "Qty", index: 6, fixes: ["remove_comma"] },
 	customer: { value: "<customer>", displayName: "Customer", index: 7, fixes: [] },
}
setupForIni(labelData, "label", hasPreviousValues := true)
setupColors(labelData, PALE_BLUE, LIGHT_ORANGE)

samplePlusButton := { }
sampleMinusButton := { }
addStyleButton := { }

paths := {
	rfid_dir: { value: "C:\RFID\PROG\" },
	rfid_file: { value: "RFIDQAR420.exe", displayName: "RFID Program" },
	csv_dir: { value: "C:\RFID\PACKLABEL\", displayName: "CSV Path" },
	csv_file: { value: "RFID-PACKLABEL.csv" },
}
setupForIni(paths, "paths")

csv := { }
defaultButtons := [{}, {}, {}, {}]

history := { index: { value: 0} }
Loop 10 {
	i := A_Index - 1
	for (key, item in ["initials", "customer", "order", "upc", "style", "roll", "time"]) {
		history.%item . i% := { value: "" }
	}
}
setupForIni(history, "history")

; =======================================================================================
; ===================================== CREATE GUI ======================================
; =======================================================================================

myGui := Gui("+0x40000") ; resizable
myGui.MarginX := 10
myGui.Marginy := 10
setupGuiAppearance()

statusBar := myGui.AddStatusBar("xs", "")
statusBar.SetFont("s10")

Tab := setupTabs()
setupMainTab(1)
setupSamplesTab(2)
setupLabelTab(3)
setupSettingsTab(4)
onTabChange(Tab)

myGui.OnEvent("Close", (*) => ExitApp)
myGui.Show(Format(devMode ? "w{1} h{2} x{3} y{4}" : "w{1} h{2}",
	WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_X, WINDOW_Y))

; =======================================================================================
; ===================================== FUNCTIONS =======================================
; =======================================================================================

setupForIni(items, section, hasPreviousValues := false) {
	for (key, item in items.OwnProps()) {
		item.iniName := key
		item.iniSection := section
		item.value := readItem(item)

		if (hasPreviousValues)
			item.prevValue := readItemPrev(item)
	}
}
setupColors(items, bg, bgChanged) {
	for (key, item in items.OwnProps()) {
		item.bg := bg
		item.bgChanged := bgChanged
	}
}

saveItem(item) {
	switch (item.iniSection . "." . item.iniName) {
		case "main.order":
		data.postOrder.gui.value := SubStr(item.gui.value, -4)
		writeItem(data.postOrder)

		case "main.upc":
		updateStyleLock()

		case "main.postOrder":
		data.order.gui.value := "20010" . item.gui.value
		writeItem(data.order)

		case "settings.orderPrefix":
		data.preOrder.gui.value := item.gui.value
		writeItem(data.preOrder)

		case "samples.customer":
		sampleData.order.gui.value := sampleData.customer.gui.value . "-"
		writeItem(sampleData.order)

		case "main.roll": 
		updateSampleButtons()

		case "settings.autoStyle":
		updateStyleLock()

		case "settings.quickOrder":
		updateQuickOrderVisibility()

		case "settings.enableFixes":
		updateFixVisibility()

		case "settings.enableSampleButtons":
		updateSampleButtonsVisibility()
	}

	if (item.iniSection == "label" && item.HasProp("fixButton"))
		item.fixButton.visible := settings.enableFixes.gui.value ? canFix(item) : false

	writeItem(item)
	updateItemBg(item)
}

updateFixVisibility() {
	for (key, item in labelData.OwnProps())
		if item.HasProp("fixButton")
			item.fixButton.Visible := settings.enableFixes.gui.value ? canFix(item) : false
}
updateSampleButtonsVisibility() {
	for (key, item in [samplePlusButton, sampleMinusButton])
		if item.HasProp("gui")
			item.gui.Visible := settings.enableSampleButtons.gui.value
}

updateItemBg(item) {
	if item.HasProp("prevValue") && item.HasProp("bg") && item.gui.Enabled && item.gui.Visible {
		if (StrCompare(item.gui.value, item.prevValue, 1))
			item.gui.Opt("Background" . item.bgChanged)
		else
			item.gui.Opt("Background" . item.bg)
		item.gui.Opt("+Redraw")
	}
}
clearBgsForWrite(items) {
	for key, item in items.OwnProps(){
		if (item.gui.value != item.prevValue)
			item.gui.Opt("Background" . PALE_BLUE)
		else
			item.gui.Opt("-Background")
		item.gui.Opt("+Redraw")
	}
}
updatePrevValues(items) {
	for (key, item in items.OwnProps()) {
		item.prevValue := item.gui.value
		writeItemPrev(item)
		updateItemBg(item)
	}
}

writeItem(item) => IniWrite(item.gui.value, "config.ini", item.iniSection, item.iniName) 
readItem(item) => IniRead("config.ini", item.iniSection, item.iniName, item.value)
writeItemPrev(item) => IniWrite(item.gui.value, "config.ini", item.iniSection, "prev_" . item.iniName)
readItemPrev(item) => IniRead("config.ini", item.iniSection, "prev_" . item.iniName, item.value)
writeHistory(item) => IniWrite(item.value, "config.ini", "history", item.iniName) 
hasGui(item) => item.HasProp("gui")

onStyleFilterChange(*) {
	value := sampleData.styleFilter.gui.text

	sampleData.style.gui.Delete()
	names := []
	for i, inlay in inlays.All {
		if (inlay.brand == value || inlay.inlay == value || inlay.chip == value) {
			names.Push(inlay.name)
			continue
		}
	}
	sampleData.style.gui.Add(names)
}

onTabChange(tabObj) {
	statusBar.SetText(tabStatusMessages[tabObj.Value])
	tabNum := tabObj.value
	defaultButtons[tabNum].Opt("+Default")
}

clearItems(items) {
	for key, item in items.OwnProps() {
		if (!item.gui.Enabled)
			continue
		item.gui.value := ""
		saveItem(item) ; TODO: find out why it's not saving roll clear
	}
	updatePrevValues(items)
}

showHistory(*) {
	out := ""
	fields := ["time", "initials", "customer", "order", "upc", "style", "roll"]
	indicies := [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]

	for i, v in indicies {
		indicies[i] := Mod(indicies[i] + history.index.value, 10)
	}

	for i, index in indicies {
		for j, field in fields {
			item := history.%field . index%
			out .= field . "`t : " . item.value . "`n"
		}
		out .= "`n"
	}
	msgBox(out)
}

saveHistory(fullOrder) {
	i := history.index.value

	initials := history.%'initials' . i%
	customer := history.%'customer' . i%
	order := history.%'order' . i%
	upc := history.%'upc' . i%
	style := history.%'style' . i%
	roll := history.%'roll' . i%
	time := history.%'time' . i%

	initials.value := data.initials.gui.value
	customer.value := data.customer.gui.value
	order.value := fullOrder
	upc.value := data.upc.gui.value
	style.value := data.style.gui.value
	roll.value := data.roll.gui.value
	time.value := FormatTime()

	history.index.value := Mod(history.index.value + 1, 10)
	for index, item in [initials, customer, order, upc, style, roll, time, history.index] {
		writeHistory(item)
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
	Tab := myGui.AddTab3("-wrap choose" . DEFAULT_TAB, ["Main", "Samples", "Label", "Settings"])
	myGui.SetFont("s" . FONT_SIZE)

	Tab.OnEvent("Change", (*) => onTabChange(Tab))
	return Tab
}

setupMainTab(tabNum) {
	Tab.useTab(tabNum)
	myGui.AddGroupBox("w330 h275 cGray Section", "data")

	; INITIALS
	textOpt := { xPrev: 20, yPrev: 30, newSection: true }
	editOpt := { uppercase: true, charLimit: 2, ySection: 0, width: 40, background: data.initials.bg }
	createEdit(data.initials, textOpt, editOpt)

	; CUSTOMER
	textOpt := { xSection: 0, newSection: true }
	editOpt := { ySection: 0, width: 170, background: data.customer.bg }
	createEdit(data.customer, textOpt, editOpt)

	; ====================== ORDER / QUICK_ORDER ====================
	; ===============================================================

	textOpt := { xSection: 0, newSection: true }
	editOpt := { number: true, charLimit: 9, ySection: 0, width: 130, background: data.order.bg }
	createEdit(data.order, textOpt, editOpt)

	editOpt := { number: true, charLimit: 5, xPrev: 0, ySection: 0, width: 82 }
	createEditboxOnly(data.preOrder, editOpt)
	editOpt := { number: true, charLimit: 4, xPrev: 100, ySection: 0, width: 70, background: data.postOrder.bg }
	createEditboxOnly(data.postOrder, editOpt)

	data.preOrder.gui.Enabled := false
	updateQuickOrderVisibility()

	; ===============================================================
	; ===============================================================

	; UPC
	textOpt := { xSection: 0, newSection: true }
	editOpt := { number: true, charLimit: 12, ySection: 0, width: 170, background: data.upc.bg }
	createEdit(data.upc, textOpt, editOpt)

	; STYLE
	textOpt := { xSection: 0, newSection: true }
	editOpt := { number: true, charLimit: 4, ySection: 0, width: 60, background: data.style.bg }
	createEdit(data.style, textOpt, editOpt)
	updateStyleLock()

	; ROLL
	textOpt := { xSection: 0, newSection: true }
	editOpt := { charLimit: 5, ySection: 0, width: 70, background: data.roll.bg, center: True }
	fontOpt := { bold: true, foreground: PALE_BLUE, fontName: "Arial"}
	createEdit(data.roll, textOpt, editOpt, fontOpt)
	myGui.AddUpDown("Range1-200 Wrap", data.roll.value)

	; SAMPLE BUTTONS
	buttonOpt := { xSection: 200, ySection: -5, width: 20, height: 20, stopTab: true} ; 286 aligns right edge
	fontOpt := { fontSize: 8 }
	samplePlusButton.gui := createButton(buttonOpt, "s+", (*) => addSample("plus"), fontOpt)
	buttonOpt := { xPrev: 0, yPrev: 20, width: 20, height: 20, stopTab: true}
	fontOpt := { fontSize: 8 }
	sampleMinusButton.gui := createButton(buttonOpt, "s-", (*) => addSample("minus"), fontOpt)

	updateSampleButtons()
	samplePlusButton.gui.Visible := settings.enableSampleButtons.value
	sampleMinusButton.gui.Visible := settings.enableSampleButtons.value


	; CLEAR BUTTON
	buttonOpt := { xMargin: 288, yMargin: 275 + TAB_FONT_SIZE, width: 50, height: 20, stopTab: true}
	fontOpt := { fontSize: 8 }
	createButton(buttonOpt, "CLEAR", (*) => clearItems(data), fontOpt)

	; HISTORY BUTTON
	buttonOpt := { xMargin: 315, yMargin: 15 + TAB_FONT_SIZE, width: 45, height: 16, stopTab: true }
	fontOpt := { fontSize: 7, fontName: "Consolas" }
	createButton(buttonOpt, "history", (*) => showHistory(), fontOpt)


	createDefaultEnterButton(tabNum)
}

updateStyleLock() {
	if (hasGui(settings.autoStyle))
		isAutoStyle := settings.autoStyle.gui.value
	else
		isAutoStyle := readItem(settings.autoStyle)

	data.style.gui.Enabled := !isAutoStyle
	data.style.gui.value := isAutoStyle ? SubStr(data.upc.gui.value, -4) : data.style.gui.value
	data.style.textGui.setFont(isAutoStyle ? "cSilver" : "cBlack")
}

setupSamplesTab(tabNum) {
	Tab.UseTab(tabNum)
	myGui.AddGroupBox("w340 h310 cGreen Section", "sample data")

	; INITIALS 
	textOpt := { xPrev: 20, yPrev: 30, newSection: true }
	editOpt := { uppercase: true, charLimit: 2, ySection: 0, width: 40 } 
	createEdit(sampleData.initials, textOpt, editOpt)

	; CUSTOMER
	textOpt := { xSection: 0, newSection: true, noMulti: true }
	editOpt := { ySection: 0, width: 207, background: sampleData.customer.bg }
	createEdit(sampleData.customer, textOpt, editOpt)
 
	; ORDER
	textOpt := { xSection: 0, newSection: true }
	editOpt := { ySection: 0, width: 121, justify: "Left" , noMulti: true}
	fontOpt := { fontSize: 11, fontName: "Consolas" }
	createEdit(sampleData.order, textOpt, editOpt, fontOpt)
	sampleData.order.gui.Enabled := false

	editOpt := { xPrev: 122, ySection: 0, width: 85, noMulti: true, background: sampleData.date.bg  }
	fontOpt := { fontSize: 12, fontName: "Consolas" }
	createEditBoxOnly(sampleData.date, editOpt, fontOpt)


	; ORIGINAL STYLE
	textOpt := { xSection: 0, newSection: true, noMulti: true }
	editOpt := { ySection: 0, width: 180, background: sampleData.style.bg }
	myGui.AddText(formatOptions(textOpt), "   Style:")
	fontOpt := { fontSize: 8, fontName: "Aptos Narrow", foreground: SLATE, bold: true }


	sampleData.style.gui := myGui.AddComboBox(formatOptions(editOpt), inlays.names)
	sampleData.style.gui.setFont(formatOptions(fontOpt), fontOpt.fontName)

	; ROLL
	textOpt := { xSection: 0, newSection: true }
	editOpt := { charLimit: 12, ySection: 0, width: 70, background: sampleData.roll.bg }
	fontOpt := { fontSize: 14, fontName: "Arial", foreground: sampleData.roll.fg }
	createEdit(sampleData.roll, textOpt, editOpt, fontOpt)
	myGui.AddUpDown("Range1-200 Wrap", sampleData.roll.value)

	; CUSTOMER
	textOpt := { xSection: 0, newSection: true, noMulti: true }
	editOpt := { ySection: 0, width: 207, background: sampleData.rollId.bg }
	createEdit(sampleData.rollId, textOpt, editOpt)

	; DROPDOWN:
	textOpt := { xSection: 85, newSection: true }
	fontOpt := { fontSize: 8, fontName: "Aptos Narrow", foreground: SLATE }
	tempText := myGui.AddText(formatOptions(textOpt), "Style Filter")
	tempText.setFont(formatOptions(fontOpt))

	editOpt := 	{ xPrev: 90, ySection: -2, width: 140, background: LIGHT_STONE, stopTab: true }
	fontOpt := { fontSize: 8, fontName: "Aptos Narrow", foreground: SLATE, bold: true }

	sampleData.styleFilter.gui := myGui.AddDropDownList(formatOptions(editOpt), sampleData.styleFilter.titles)
	sampleData.styleFilter.gui.onEvent("Change", (*) => onStyleFilterChange())
	sampleData.styleFilter.gui.setFont(formatOptions(fontOpt), fontOpt.hasProp("fontName") ? fontOpt.fontName : "")

	createDefaultEnterButton(tabNum)
}

setupLabelTab(tabNum) {
	Tab.UseTab(tabNum)
	myGui.MarginY := 6
	myGui.SetFont("s12")
	boxHeight := 24

	; ==== ACTIONS ==== 
	myGui.AddGroupBox("w330 h65 cGray Section", "actions")
	readButton := MyGui.AddButton("xp+10 yp+20 h30 -TabStop", "read")
	readButton.OnEvent("Click", onRead)
	writeButton := MyGui.AddButton("x+15 yp h30 -TabStop", "write")
	writeButton.OnEvent("Click", onWrite)

	myGui.SetFont("s8")
	path := (devMode ? ".\test\" : paths.csv_dir.value) . paths.csv_file.value
	pathText := MyGui.AddText("xS+22 yS+55 cGray", "Path: " . path)
	myGui.SetFont("s12")

	; ==== LABEL DATA ====
	myGui.AddGroupBox("xS w330 h245 cBlue Section", "label data")

	quickFixButtonSetup(item) {
		if item.fixes.length == 0
			return
		btnOptions := { xPrev: 160 + 30, yPrev: 0, height: 25, width: 25, stopTab: true }
		item.fixButton := createButton(btnOptions, "fix", (*) => fixItem(item))
		item.fixButton.SetFont("s6")
		item.fixButton.Visible := readItem(settings.enableFixes) && canFix(item)
	}

	; ORDER
	textOpt := { xSection: 10, ySection: 25, newSection: true, height: boxHeight }
	editOpt := { ySection: 0, width: 160, height: boxHeight }
	createEdit(labelData.order, textOpt, editOpt)
	quickFixButtonSetup(labelData.order)

	; UPC
	textOpt := { xSection: 0, newSection: true, height: boxHeight }
	editOpt := { ySection: 0, width: 160, height: boxHeight }
	createEdit(labelData.upc, textOpt, editOpt)
	quickFixButtonSetup(labelData.upc)

	; INITIALS
	textOpt := { xSection: 0, newSection: true, height: boxHeight }
	editOpt := { charLimit: 4, ySection: 0, width: 50, height: boxHeight}
	createEdit(labelData.initials, textOpt, editOpt)
	quickFixButtonSetup(labelData.initials)

	; DATE 
	textOpt := { xSection: 0, newSection: true, height: boxHeight }
	editOpt := { charLimit: 10, ySection: 0, width: 130, height: boxHeight}
	createEdit(labelData.date, textOpt, editOpt)
	quickFixButtonSetup(labelData.date)

	; ROLL
	textOpt := { xSection: 0, newSection: true, height: boxHeight }
	editOpt := { charLimit: 5, ySection: 0, width: 70, height: boxHeight }
	createEdit(labelData.roll, textOpt, editOpt)
	x := myGui.AddUpDown("Range1-200 Wrap", labelData.roll.value)
	labelData.roll.gui.value := readItem(labelData.roll)
	quickFixButtonSetup(labelData.roll)

	; QTY
	textOpt := { xSection: 0, newSection: true, height: boxHeight }
	editOpt := { number: true, charLimit: 6, ySection: 0, width: 70, height: boxHeight }
	createEdit(labelData.quantity, textOpt, editOpt)
	quickFixButtonSetup(labelData.quantity)

	; CUSTOMER
	textOpt := { xSection: 0, newSection: true, height: boxHeight }
	editOpt := { ySection: 0, width: 130, height: boxHeight }
	createEdit(labelData.customer, textOpt, editOpt)

	myGui.SetFont("s14")
	myGui.MarginY := 11

	createDefaultEnterButton(tabNum)
	for key, item in labelData.OwnProps() {
		updateItemBg(item)
	}
}

setupSettingsTab(tabNum) {
	Tab.UseTab(tabNum)
	myGui.SetFont("s12")
	myGui.MarginY := 5

	myGui.AddGroupBox("w330 h310 cGray Section", "general")

	textOpt := { xPrev: 20, yPrev: 30, newSection: true }
	editOpt := { ySection: 0, width: 80 }
	createEdit(settings.delay, textOpt, editOpt)
	myGui.AddUpDown("range1-9999 Wrap", settings.delay.value)

	opt := { xSection: 0, newSection: true, checked: settings.autoStyle.value }
	createCheckbox(settings.autoStyle, opt, (*) => saveItem(settings.autoStyle))

	opt := { xSection: 0, newSection: true, checked: settings.quickOrder.value }
	createCheckbox(settings.quickOrder, opt, (*) => saveItem(settings.quickOrder))

	textOpt := { xSection: 0, newSection: true }
	editOpt := { charLimit: 5, ySection: 0, width: 80 }
	createEdit(settings.orderPrefix, textOpt, editOpt)
	updateQuickOrderVisibility()

	textOpt := { xSection: 0, newSection: true }
	editOpt := { xSection: 0, width: 260 }
	fontOpt := { fontSize: 12, fontName: "Consolas" }
	createEdit(paths.rfid_file, textOpt, editOpt, fontOpt)
	paths.rfid_file.textGui.SetFont("s12")

	textOpt := { xSection: 0, newSection: true }
	editOpt := { xSection: 0, width: 260 }
	fontOpt := { fontSize: 11, fontName: "Consolas" }
	createEdit(paths.csv_dir, textOpt, editOpt, fontOpt)
	paths.csv_dir.textGui.SetFont("s12")

	opt := { xSection: 0, newSection: true, checked: settings.enableFixes.value }
	createCheckbox(settings.enableFixes, opt, (*) => saveItem(settings.enableFixes))

	opt := { xSection: 0, newSection: true, checked: settings.enableSampleButtons.value }
	createCheckbox(settings.enableSampleButtons, opt, (*) => saveItem(settings.enableSampleButtons))

	createDefaultEnterButton(tabNum)
	myGui.SetFont("s14")
	myGui.MarginY := 11
}

createDefaultEnterButton(tabNum) {
	defaultButtons[tabNum] := myGui.AddButton("x0 y0 Default", "button")
	defaultButtons[tabNum].Visible := false
	defaultButtons[tabNum].onEvent("Click", (*) => SendInput("{Tab}"))
}

createEditboxOnly(item, editboxOptions, fontOptions?) {
	item.gui := myGui.AddEdit(formatOptions(editboxOptions), item.value)

	if (IsSet(fontOptions))
		item.gui.setFont(formatOptions(fontOptions), fontOptions.hasProp("fontName") ? fontOptions.fontName : "")

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

	return btn
}
createCheckbox(item, options, my_function) {
	checkString := item.value ? " checked1" : "checked0"
	item.gui := myGui.AddCheckBox(formatOptions(options) . checkString, item.displayName)
	item.gui.onEvent("Click", my_function)
}

fixItem(item) {
	for index, fix in item.fixes {
		value := item.gui.value
		switch fix {
			case "add_apostrophe":
			firstChar := SubStr(value, 1, 1)
			if (firstChar != "'")
				item.gui.value := "'" . value

			case "remove_apostrophe":
			firstChar := SubStr(value, 1, 1)
			if (firstChar == "'")
				item.gui.value := SubStr(value, 2) ; TODO: test this

			case "caps":
			item.gui.value := StrUpper(value)

			case "fix_date":
			strings := StrSplit(value, "/")
			month := strings[1], day := strings[2], year := strings[3]
			if StrLen(month) == 1
				month := "0" . month
			if StrLen(day) == 1
				day := "0" . day
			if StrLen(year) == 2
				year := "20" . year
			item.gui.value := month . "/" . day . "/" . year

			case "remove_shortage":
			item.gui.value := String(Floor(Number(value)))

			case "remove_comma":
			item.gui.value := RegExReplace(value, ",", "")
		}
	}
	saveItem(item)
}

canFix(item) {
	for index, fix in item.fixes {
		value := item.gui.value
		switch fix {
			case "add_apostrophe":
			regexString := ""
			if item.displayName == "Order#"
				regexString := "^[0-9]{9}$"
			else if item.displayName == "UPC"
				regexString := "^[0-9]{12}$"
			else if item.displayName == "QC By"
				regexString := "^[a-zA-Z]{2,3}$"
			if RegExMatch(value, regexString)
				return true

			case "remove_apostrophe":
			if RegExMatch(value, "^'[0-9]{12}$")
				return true

			case "caps":
			trimmed := LTrim(value, "'")
			if (!IsUpper(trimmed) && RegexMatch(LTrim(value, "'"), "^\w+$"))
				return true

			case "remove_shortage":
			if IsFloat(value)
				return true

			case "fix_date": ; can have 1-2 day digits, 1-2 month, and 2 or 4 year, but not 3
			if !RegExMatch(value, "^\d\d/\d\d/\d\d\d\d$") 
				&& RegExMatch(value, "^\d\d?/\d\d?/\d\d\d?\d?$")
			&& !RegExMatch(value, "^\d\d?/\d\d?/\d\d\d$") {
				return true
				}

			case "remove_comma":
			if RegExMatch(value, ",")
				return true
		}
	}
	return false
}

updateQuickOrderVisibility() {
	if (hasGui(settings.quickOrder))
		isQuickOrder := settings.quickOrder.gui.value
	else
		isQuickOrder := readItem(settings.quickOrder)

	data.order.gui.Visible := !isQuickOrder
	data.preOrder.gui.Visible := isQuickOrder
	data.postOrder.gui.Visible := isQuickOrder

	if(settings.orderPrefix.HasProp("gui")) {
		settings.orderPrefix.textGui.Enabled := isQuickOrder
		settings.orderPrefix.gui.Enabled := isQuickOrder
	}
}

addSample(type) {
	rollString := data.roll.gui.value
	if(!isNumber(rollString) || Number(rollString) < 0)
		return MsgBox("Error: current roll value is not a number or is negative, cannot change to add sample")
	rollNum := Round(Number(rollString), 1)
	modulus := Round(Mod(rollNum, 1), 1)

	switch {
		case (type == "plus" && modulus <= 0.1):
		rollNum := Round(rollNum + 0.2, 1)
		case (type == "plus" && modulus < 0.9):
		rollNum := Round(rollNum + 0.1, 1)
		case (type == "minus" && modulus <= 0.2):
		rollNum := Round(rollNum, 0)
		case (type == "minus" && modulus <= 0.9):
		rollNum := Round(rollNum - 0.1, 1)
	}
	data.roll.gui.value := rollNum
	saveItem(data.roll)
	updateSampleButtons()
}

updateSampleButtons() {
	rollString := data.roll.gui.value
	if(!isNumber(rollString) || Number(rollString) < 0) {
		samplePlusButton.gui.Enabled := 0
		sampleMinusButton.gui.Enabled := 0
		return
	}
	rollNum := Round(Number(rollString), 1)
	modulus := Round(Mod(rollNum, 1), 1)


	samplePlusButton.gui.Enabled := (modulus < 0.9)
	sampleMinusButton.gui.Enabled := (modulus >= 0.2)
}

onRead(*) {
	if !readCsv()
		return

	for key1, csvItem in csv.OwnProps()
	for key2, labelItem  in labelData.OwnProps()
	if (labelItem.index == csvItem.index) {
		labelItem.gui.value := csvItem.value
		saveItem(labelItem)
	}

	updatePrevValues(labelData)
}
csvConcat(array) {
	out .= ""
	for (index, value in array)
		out .= "`"" . value . "`"" . (index != array.Length ? "," : "")
	return out
}
onWrite(*) {
	try {
		csvKeysArray := ["","","","","","",""]
		csvValuesArray := ["","","","","","",""]
		for key, item in labelData.OwnProps() {
			csvKeysArray[item.index] := item.displayName
			csvValuesArray[item.index] := item.gui.value
		}
		csvKeys := csvConcat(csvKeysArray)
		csvValues := csvConcat(csvValuesArray)
		csvOut := csvKeys . "`n" . csvValues
		csvPath := (devMode ? ".\test\out_" : paths.csv_dir.gui.value) . paths.csv_file.value
		file := FileOpen(csvPath, "w")
		file.Write(csvOut)
		file.Close()
		clearBgsForWrite(labelData)
	} catch as e {
		MsgBox("An error ocurred during writing try path: " . csvPath . "`n" . e.Message)
	}
}
readCsv(*) {
	csvPath := (devMode ? ".\test\" : paths.csv_dir.gui.value) . paths.csv_file.value
	try {
		Loop read, csvPath {
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
		MsgBox("An error occured:`n`n" . e.Message . "`n`nPlease check that the path is correct: " . csvPath . "`nAlso check that the csv file is in the correct format.")
		return 0
	}
	return 1
}

changeDate(item, direction, delimiter := "/") {
    dlm := delimiter

	if !RegExMatch(item.gui.value, "^\d\d?" . dlm . "\d\d?" . dlm . "\d\d\d?\d?$") {
		return 
	}
	dates := StrSplit(item.gui.value, dlm)
	month := dates[1], day := dates[2], year := dates[3]
	if (day == '0' || day == '00' || month == '0' || month == '00') {
		return
	}

	mFormat := "MM", dFormat := "dd", yFormat := "yyyy"
	if StrLen(month) == 1 {
		month := '0' . month
		mFormat := "M"
	}
	if StrLen(day) == 1 {
		day := '0' . day
		dFormat := "d"
	}
	if StrLen(year) == 2 {
		year := '20' . year
		yFormat := "yy"
	}
	if StrLen(month) != 2 || StrLen(day) !== 2 || StrLen(year) != 4 {
		return
	}
	format := mFormat . dlm . dFormat . dlm . yFormat

	newDate := FormatTime(DateAdd(year . month . day, (direction == "up" ? 1 : -1), "days"), format)
	item.gui.value := newDate
	saveItem(item)
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
		str .= "ys" . ((obj.ySection >= 0) ? "+" : "") . obj.ySection . " "
	if (obj.HasProp("xMargin"))
		str .= "xm" . "+" . obj.xMargin . " "
	if (obj.HasProp("yMargin")) 
		str .= "ym" . obj.yMargin . " "

	if (obj.HasProp("justify"))
		str .= obj.justify . " "
	if (obj.HasProp("noWrap"))
		str .= "-Wrap "
	if (obj.HasProp("noMulti"))
		str .= "-Multi r1 "
	


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
	if (obj.HasProp("stopTab") && obj.stopTab == true)
		str .= "-TabStop" . " "

	return str
}

; =======================================================================================
; ====================================== HOTKEYS ========================================
; =======================================================================================

#HotIf ( (Tab.value == "3") || (Tab.value == "2") )
~WheelUp:: {
	if (Tab.value == 3) {
		MouseGetPos(, , , &dateControl)
		if (dateControl == labelData.date.gui.ClassNN)
			changeDate(labelData.date, "up", "/")
	}
	if (Tab.value == 2) {
		MouseGetPos(, , , &dateControl)
		if (dateControl == sampleData.date.gui.ClassNN)
			changeDate(sampleData.date, "up", "-")
	}
}
~WheelDown:: {
	if (Tab.value == 3) {
		MouseGetPos(, , , &dateControl)
		if (dateControl == labelData.date.gui.ClassNN)
			changeDate(labelData.date, "down", "/")
	}
	if (Tab.value == 2) {
		MouseGetPos(, , , &dateControl)
		if (dateControl == sampleData.date.gui.ClassNN)
			changeDate(sampleData.date, "down", "-")
	}
}

#HotIf exeActive("cmd.exe", "WindowsTerminal.exe", "emacs.exe", "sublime_text.exe") or classActive("Notepad")
^1::onPrint()
^2::onSamplePrint()

onPrint(*) {
	if (Tab.value != 1)
		return

	if (data.order.gui.Visible && !data.preOrder.gui.Visible && !data.postOrder.gui.Visible)
		order := data.order.gui.value
	else if (!data.order.gui.Visible && data.preOrder.gui.Visible && data.postOrder.gui.Visible)
		order := data.preOrder.gui.value . data.postOrder.gui.value
	else
		return MsgBox("error parsing order number, something messed up")

	Send("{Ctrl down}") ; todo: verify this fix works for ctrl key getting stuck
	Send("{Ctrl up}")

	status := [0,0,0,0,0,0,0,0,0]
	status[1] := inputDataAndSleep(data.initials.gui.value)
	status[2] := inputDataAndSleep(data.customer.gui.value)
	status[3] := inputDataAndSleep(order)
	status[4] := inputDataAndSleep(data.upc.gui.value)
	status[5] := inputDataAndSleep(data.style.gui.value)
	status[6] := inputDataAndSleep(data.roll.gui.value)
	status[7] := inputDataAndSleep("Y")
	status[8] := inputDataAndSleep("N")
	status[9] := inputDataAndSleep("Y")

	Send("{Ctrl down}") ; todo: verify this fix works for ctrl key getting stuck
	Send("{Ctrl up}")

    for index, value in status {
		if !value
			return
    }
	updatePrevValues(data)
	saveHistory(order)
}

onSamplePrint(*) {
	if (Tab.value != 2) {
		return
	}

	Send("{Ctrl down}") ; todo: verify this fix works for ctrl key getting stuck
	Send("{Ctrl up}")

	status := [0,0,0,0,0,0,0,0,0]
	status[1] := inputDataAndSleep(sampleData.initials.gui.value)
	status[2] := inputDataAndSleep(sampleData.customer.gui.value)
	status[3] := inputDataAndSleep(sampleData.order.gui.value . sampleData.date.gui.value)
	status[4] := inputDataAndSleep("") ; No upc
	status[5] := inputDataAndSleep(sampleData.brand.gui.value)
	status[6] := inputDataAndSleep(sampleData.roll.gui.value)
	status[7] := inputDataAndSleep("Y")
	status[8] := inputDataAndSleep("N")
	status[9] := inputDataAndSleep("Y")

	Send("{Ctrl down}") ; todo: verify this fix works for ctrl key getting stuck
	Send("{Ctrl up}")

    for index, value in status {
		if !value
			return
    }
	updatePrevValues(sampleData)
}

inputDataAndSleep(obj) {
	if !exeActive("cmd.exe", "WindowsTerminal.exe", "emacs.exe", "sublime_text.exe")
		&& !classActive("Notepad") {
		return 0
	}
	SendInput(obj . "{enter}")
	Sleep(settings.delay.gui.value)
	return 1
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
