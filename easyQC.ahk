﻿#Requires AutoHotkey v2.0
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
DEFAULT_TAB := devMode ? 3 : 1
tabTitles := [ "Main", "Samples", "Label", "Settings"]
tabStatusMessages := ["Press ctrl+1 to output values", "Press ctrl+2 to output values, w/ blank upc", "", ""]
; COLORS
PALE_BLUE := "eef2ff"
NAVY_BLUE := "4d6d9a"
SOLAR_BLUE := "268bd2"
LIGHT_ORANGE := "fed7aa"

; GLOBAL VARIABLES
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

settings := {
	delay: { value: 100, displayName: "Delay (ms)" },
	autoStyle : { value: 0, displayName: "Auto Style" },
	quickOrder: { value: 0, displayName: "Quick Order" },
	orderPrefix: { value: "20010", displayName: "Prefix" },
}
setupForIni(settings, "settings")

sampleData := {
	initials: { value: "..", displayName: "Initials" },
	customer: { value: "<customer>", displayName: "Customer" },
	order: { value: "<order>", displayName: "Order" },
	style: { value: "....", displayName: "Style" },
	roll: { value: "1", displayName: "Roll" },
}
setupForIni(sampleData, "samples")

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

samplePlusButton := { }
sampleMinusButton := { }

paths := {
	rfid_dir: { value: "C:\RFID\PROG\" },
	rfid_file: { value: "RFIDQAR420.exe", displayName: "RFID Program" },
	csv_dir: { value: "C:\RFID\PACKLABEL\", displayName: "CSV Path" },
	csv_file: { value: "RFID-PACKLABEL.csv" },
}
setupForIni(paths, "paths")

csv := { }
defaultButtons := [{}, {}, {}, {}]

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
saveItem(item) {
	switch (item.iniSection . "." . item.iniName) { ; TODO: restrict to data object
		case "main.order":
		data.postOrder.gui.value := SubStr(item.gui.value, -4)
		writeItem(data.postOrder)

		case "main.upc":
		updateStyleLock()

		case "main.postOrder":
		data.order.gui.value := "20010" . item.gui.value
		writeItem(data.order)

		case "main.quickOrder":
		updateQuickOrderVisibility()

		case "main.orderPrefix":
		data.preOrder.gui.value := item.gui.value
		writeItem(data.preOrder)

		case "main.autoStyle":
		updateStyleLock()

		case "main.roll": 
		updateSampleButtons()
	}

	if (item.iniSection := "label" && item.HasProp("fixButton"))
		item.fixButton.visible := canFix(item)

	writeItem(item)
	updateItemBg(item)
}

updateItemBg(item) {
	if item.HasProp("prevValue") {
		if (StrCompare(item.gui.value, item.prevValue, 1))
			item.gui.Opt("Background" . LIGHT_ORANGE)
		else
			item.gui.Opt("-Background")
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
	}
}

writeItem(item) => IniWrite(item.gui.value, "config.ini", item.iniSection, item.iniName)
readItem(item) => IniRead("config.ini", item.iniSection, item.iniName, item.value)
writeItemPrev(item) => IniWrite(item.gui.value, "config.ini", item.iniSection, "prev_" . item.iniName)
readItemPrev(item) => IniRead("config.ini", item.iniSection, "prev_" . item.iniName, item.value)
hasGui(item) => item.HasProp("gui")

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
	editOpt := { uppercase: true, charLimit: 2, ySection: 0, width: 40, background: PALE_BLUE }
	createEdit(data.initials, textOpt, editOpt)

	; CUSTOMER
	textOpt := { xSection: 0, newSection: true }
	editOpt := { ySection: 0, width: 170, background: PALE_BLUE }
	createEdit(data.customer, textOpt, editOpt)

	; ====================== ORDER / QUICK_ORDER ====================
	; ===============================================================

	textOpt := { xSection: 0, newSection: true }
	editOpt := { number: true, charLimit: 9, ySection: 0, width: 130, background: PALE_BLUE }
	createEdit(data.order, textOpt, editOpt)

	editOpt := { number: true, charLimit: 5, xPrev: 0, ySection: 0, width: 82 }
	createEditboxOnly(data.preOrder, editOpt)
	editOpt := { number: true, charLimit: 4, xPrev: 100, ySection: 0, width: 70, background: PALE_BLUE }
	createEditboxOnly(data.postOrder, editOpt)

	data.preOrder.gui.Enabled := false
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
	updateStyleLock()

	; ROLL
	textOpt := { xSection: 0, newSection: true }
	editOpt := { charLimit: 5, ySection: 0, width: 70, background: NAVY_BLUE, center: True }
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

	; CLEAR BUTTON
	buttonOpt := { xMargin: 288, yMargin: 275 + TAB_FONT_SIZE, width: 50, height: 20, stopTab: true}
	fontOpt := { fontSize: 8 }
	createButton(buttonOpt, "CLEAR", (*) => clearItems(data), fontOpt)

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
	myGui.AddGroupBox("w330 h240 cGreen Section", "sample data")

	; INITIALS
	textOpt := { xPrev: 20, yPrev: 30, newSection: true }
	editOpt := { uppercase: true, charLimit: 2, ySection: 0, width: 40, }
	createEdit(sampleData.initials, textOpt, editOpt)

	; CUSTOMER
	textOpt := { xSection: 0, newSection: true }
	editOpt := { ySection: 0, width: 185 }
	createEdit(sampleData.customer, textOpt, editOpt)

	textOpt := { xSection: 0, newSection: true }
	editOpt := { ySection: 0, width: 185 }
	createEdit(sampleData.order, textOpt, editOpt)

	; STYLE
	textOpt := { xSection: 0, newSection: true }
	editOpt := { number: true, charLimit: 4, ySection: 0, width: 185 }
	createEdit(sampleData.style, textOpt, editOpt)

	; ROLL
	textOpt := { xSection: 0, newSection: true }
	editOpt := { charLimit: 12, ySection: 0, width: 70 }
	createEdit(sampleData.roll, textOpt, editOpt)
	myGui.AddUpDown("Range1-200 Wrap", sampleData.roll.value)

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
		item.fixButton.Visible := canFix(item)
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
	editOpt := { charLimit: 3, ySection: 0, width: 50, height: boxHeight}
	createEdit(labelData.initials, textOpt, editOpt)
	quickFixButtonSetup(labelData.initials)

	; DATE TODO: scroll date
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
	editOpt := { number: true, charLimit: 2, ySection: 0, width: 70, height: boxHeight }
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
	myGui.MarginY := 5

	myGui.AddGroupBox("w330 h300 cGray Section", "general")

	textOpt := { xPrev: 20, yPrev: 30, newSection: true }
	editOpt := { ySection: 0, width: 80 }
	createEdit(settings.delay, textOpt, editOpt)
	myGui.AddUpDown("range1-9999 Wrap", settings.delay.value)

	opt := { xSection: 0, newSection: true, checked: settings.autoStyle.value }
	createCheckbox(settings.autoStyle, opt)

	opt := { xSection: 0, newSection: true, checked: settings.quickOrder.value }
	createCheckbox(settings.quickOrder, opt)

	textOpt := { xSection: 0, newSection: true }
	editOpt := { ySection: 0, width: 80 }
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

	createDefaultEnterButton(tabNum)
	myGui.MarginY := 11
}

createDefaultEnterButton(tabNum) {
	defaultButtons[tabNum] := myGui.AddButton("x0 y0 Default", "button")
	defaultButtons[tabNum].Visible := false
	defaultButtons[tabNum].onEvent("Click", (*) => SendInput("{Tab}"))
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

	return btn
}
createCheckbox(item, options) {
	item.gui := myGui.AddCheckBox(formatOptions(options), item.displayName)
	item.gui.onEvent("Click", (*) => saveItem(item))
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
			if SubStr(value, 1, 1) != "'"
				return true

			case "remove_apostrophe":
			if SubStr(value, 1, 1) == "'"
				return true

			case "caps":
			if !IsUpper(LTrim(value, "'"))
				return true

			case "remove_shortage":
			if IsFloat(value)
				return true

			case "fix_date":
			strings := StrSplit(value, "/")
			month := strings[1], day := strings[2], year := strings[3]
			if StrLen(month) == 1 || StrLen(day) == 1 || StrLen(year) == 2
				return true

			case "remove_shortage":

			case "remove_comma":
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
		csvPath := (devMode ? ".\test\out_" : paths.csv_dir.value) . paths.csv_file.value
		file := FileOpen(csvPath, "w") ; TODO: add path option
		file.Write(csvOut)
		file.Close()
		clearBgsForWrite(labelData)
	} catch as e {
		MsgBox("An error ocurred during writing: `n" . e.Message)
	}
}
readCsv(*) {
	csvPath := (devMode ? ".\test\" : paths.csv_dir.value) . paths.csv_file.value
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

	inputDataAndSleep(data.initials.gui.value)
	inputDataAndSleep(data.customer.gui.value)
	inputDataAndSleep(order)
	inputDataAndSleep(data.upc.gui.value)
	inputDataAndSleep(data.style.gui.value)
	inputDataAndSleep(data.roll.gui.value)
	inputDataAndSleep("Y")
	inputDataAndSleep("N")
	inputDataAndSleep("Y")
}

onSamplePrint(*) {
	if (Tab.value != 2)
		return

inputDataAndSleep(sampleData.initials.gui.value)
	inputDataAndSleep(sampleData.customer.gui.value)
	inputDataAndSleep(sampleData.order.gui.value)
	inputDataAndSleep("") ; No upc
	inputDataAndSleep(sampleData.style.gui.value)
	inputDataAndSleep(sampleData.roll.gui.value)
	inputDataAndSleep("Y")
	inputDataAndSleep("N")
	inputDataAndSleep("Y")
}

inputDataAndSleep(obj) {
	if classActive("XLMAIN", "Chrome_WidgetWin_1") {
		return
	}
	SendInput(obj . "{enter}")
	Sleep(settings.delay.gui.value)
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
