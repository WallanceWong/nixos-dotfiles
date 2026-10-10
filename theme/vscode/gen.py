#!/usr/bin/env python3
"""whisper for VS Code — builds the colour theme from theme/palette.json.

    gen.py <palette.json> <extension-src-dir> <out-dir>

Writes a complete extension (package.json, the theme, the status-bar script)
into <out-dir>. The mood: a night sky over a city — deep blue-teal surfaces,
text like moonlit paper, and the streetlamp's warm yellow for whatever matters
most (the cursor, function names, the active tab).
"""
import json, os, shutil, sys

pal = json.load(open(sys.argv[1]))
src, out = sys.argv[2], sys.argv[3]
css_only = "--css-only" in sys.argv      # just whisper-workbench.css (for the patched VS Code)
p = {k: v for k, v in pal.items() if isinstance(v, str) and v.startswith("#")}
term = pal["terminal"]


def rgb(c):
    c = c.lstrip("#")
    return tuple(int(c[i:i + 2], 16) for i in (0, 2, 4))


def hexc(t):
    return "#" + "".join(f"{max(0, min(255, round(v))):02x}" for v in t)


def mix(a, b, t):
    """a → b by t (0..1)"""
    A, B = rgb(a), rgb(b)
    return hexc(tuple(A[i] + (B[i] - A[i]) * t for i in range(3)))


def a(c, alpha):
    """colour with alpha (0..1)"""
    return c[:7] + f"{round(alpha * 255):02x}"


crust, mantle, base, sunken = p["crust"], p["mantle"], p["base"], p["sunken"]
s0, s1, s2, ov = p["surface0"], p["surface1"], p["surface2"], p["overlay"]
sub, text = p["subtext"], p["text"]
lamp, lampDim = p["lamp"], p["lampDim"]
teal, blue, red, mustard, green, violet = p["teal"], p["blue"], p["red"], p["mustard"], p["green"], p["violet"]
comment = mix(ov, sub, 0.25)          # faint, like writing in pencil on the night
quiet = mix(ov, sub, 0.35)            # secondary labels: readable, but stepping back
tealLight, blueLight = term[14], term[12]

# ── workbench ────────────────────────────────────────────────────────────
colors = {
    # base
    "foreground": text,
    "descriptionForeground": sub,
    "disabledForeground": ov,
    "errorForeground": red,
    "focusBorder": a(lamp, 0.45),
    "contrastBorder": None,
    "selection.background": a(s2, 0.9),
    "icon.foreground": sub,
    "textLink.foreground": teal,
    "textLink.activeForeground": lamp,
    "textPreformat.foreground": mustard,
    "textPreformat.background": a(s0, 0.8),
    "textBlockQuote.background": a(s0, 0.6),
    "textBlockQuote.border": lampDim,
    "textCodeBlock.background": a(sunken, 0.9),
    "textSeparator.foreground": s1,
    "widget.shadow": a(crust, 0.65),
    "widget.border": a(lamp, 0.12),
    "sash.hoverBorder": a(lamp, 0.5),
    "progressBar.background": lamp,
    "toolbar.hoverBackground": a(s1, 0.8),
    "toolbar.activeBackground": a(s2, 0.8),

    # window chrome
    "titleBar.activeBackground": mantle,
    "titleBar.activeForeground": sub,
    "titleBar.inactiveBackground": crust,
    "titleBar.inactiveForeground": ov,
    "titleBar.border": a(s0, 0.6),
    "commandCenter.background": a(s0, 0.7),
    "commandCenter.foreground": sub,
    "commandCenter.activeBackground": a(s1, 0.9),
    "commandCenter.activeForeground": lamp,
    "commandCenter.border": a(lamp, 0.12),
    "commandCenter.activeBorder": a(lamp, 0.35),
    "commandCenter.inactiveBorder": a(s1, 0.5),
    "menu.background": mantle,
    "menu.foreground": text,
    "menu.selectionBackground": a(s1, 0.95),
    "menu.selectionForeground": lamp,
    "menu.separatorBackground": s1,
    "menu.border": a(lamp, 0.14),
    "menubar.selectionBackground": a(s1, 0.8),
    "menubar.selectionForeground": lamp,

    # activity bar (left icons)
    "activityBar.background": crust,
    "activityBar.foreground": lamp,
    "activityBar.inactiveForeground": quiet,
    "activityBar.activeBorder": lamp,
    "activityBar.activeBackground": a(s0, 0.6),
    "activityBar.activeFocusBorder": lamp,
    "activityBar.border": a(s0, 0.5),
    "activityBarBadge.background": lamp,
    "activityBarBadge.foreground": crust,
    "activityBarTop.foreground": lamp,
    "activityBarTop.inactiveForeground": ov,
    "activityBarTop.activeBorder": lamp,

    # side bar
    "sideBar.background": mantle,
    "sideBar.foreground": sub,
    "sideBar.border": a(s0, 0.5),
    "sideBarTitle.foreground": lampDim,
    "sideBarSectionHeader.background": mantle,
    "sideBarSectionHeader.foreground": teal,
    "sideBarSectionHeader.border": a(s0, 0.5),
    "sideBarStickyScroll.background": mantle,
    "sideBarStickyScroll.shadow": a(crust, 0.7),

    # lists and trees
    "list.activeSelectionBackground": a(s1, 0.95),
    "list.activeSelectionForeground": lamp,
    "list.activeSelectionIconForeground": lamp,
    "list.inactiveSelectionBackground": a(s0, 0.95),
    "list.inactiveSelectionForeground": text,
    "list.hoverBackground": a(s0, 0.7),
    "list.hoverForeground": text,
    "list.focusBackground": a(s1, 0.8),
    "list.focusForeground": lamp,
    "list.focusOutline": a(lamp, 0.35),
    "list.inactiveFocusOutline": a(s2, 0.6),
    "list.highlightForeground": lamp,
    "list.focusHighlightForeground": lamp,
    "list.dropBackground": a(teal, 0.15),
    "list.errorForeground": red,
    "list.warningForeground": mustard,
    "list.invalidItemForeground": red,
    "list.deemphasizedForeground": ov,
    "listFilterWidget.background": s0,
    "listFilterWidget.outline": a(lamp, 0.5),
    "listFilterWidget.noMatchesOutline": red,
    "tree.indentGuidesStroke": a(s2, 0.9),
    "tree.inactiveIndentGuidesStroke": a(s1, 0.6),

    # editor groups and tabs
    "editorGroup.border": a(s0, 0.7),
    "editorGroup.dropBackground": a(teal, 0.12),
    "editorGroupHeader.tabsBackground": mantle,
    "editorGroupHeader.tabsBorder": a(s0, 0.5),
    "editorGroupHeader.noTabsBackground": mantle,
    "tab.activeBackground": base,
    "tab.activeForeground": lamp,
    "tab.activeBorder": base,
    "tab.activeBorderTop": lamp,
    "tab.inactiveBackground": mantle,
    "tab.inactiveForeground": quiet,
    "tab.hoverBackground": a(s0, 0.8),
    "tab.hoverForeground": text,
    "tab.unfocusedActiveBackground": base,
    "tab.unfocusedActiveForeground": sub,
    "tab.unfocusedActiveBorderTop": a(lampDim, 0.5),
    "tab.unfocusedInactiveForeground": a(ov, 0.8),
    "tab.border": mantle,
    "tab.lastPinnedBorder": a(s2, 0.8),
    "tab.dragAndDropBorder": lamp,
    "tab.activeModifiedBorder": mustard,
    "tab.inactiveModifiedBorder": a(mustard, 0.5),
    "tab.selectedBackground": base,
    "tab.selectedForeground": lamp,
    "tab.selectedBorderTop": lamp,
    "breadcrumb.foreground": quiet,
    "breadcrumb.focusForeground": text,
    "breadcrumb.activeSelectionForeground": lamp,
    "breadcrumb.background": base,
    "breadcrumbPicker.background": mantle,

    # editor
    "editor.background": base,
    "editor.foreground": text,
    "editorLineNumber.foreground": a(ov, 0.75),
    "editorLineNumber.activeForeground": lamp,
    "editorLineNumber.dimmedForeground": a(ov, 0.4),
    "editorCursor.foreground": lamp,
    "editorCursor.background": crust,
    "editor.lineHighlightBackground": a(s0, 0.45),
    "editor.lineHighlightBorder": "#00000000",
    "editor.selectionBackground": a(s2, 0.85),
    "editor.selectionForeground": None,
    "editor.inactiveSelectionBackground": a(s1, 0.7),
    "editor.selectionHighlightBackground": a(teal, 0.14),
    "editor.selectionHighlightBorder": a(teal, 0.25),
    "editor.wordHighlightBackground": a(teal, 0.12),
    "editor.wordHighlightStrongBackground": a(lamp, 0.12),
    "editor.wordHighlightTextBackground": a(teal, 0.12),
    "editor.findMatchBackground": a(lamp, 0.30),
    "editor.findMatchBorder": a(lamp, 0.8),
    "editor.findMatchHighlightBackground": a(lamp, 0.13),
    "editor.findMatchHighlightBorder": a(lamp, 0.3),
    "editor.findRangeHighlightBackground": a(s1, 0.5),
    "editor.hoverHighlightBackground": a(teal, 0.1),
    "editor.rangeHighlightBackground": a(s1, 0.4),
    "editor.symbolHighlightBackground": a(lamp, 0.14),
    "editor.linkedEditingBackground": a(teal, 0.1),
    "editorLink.activeForeground": teal,
    "editorWhitespace.foreground": a(s2, 0.8),
    "editorIndentGuide.background1": a(s1, 0.7),
    "editorIndentGuide.activeBackground1": a(lampDim, 0.45),
    "editorRuler.foreground": a(s1, 0.75),
    "editorCodeLens.foreground": a(ov, 0.9),
    "editorLightBulb.foreground": mustard,
    "editorLightBulbAutoFix.foreground": teal,
    "editorBracketMatch.background": a(lamp, 0.12),
    "editorBracketMatch.border": a(lamp, 0.5),
    "editorBracketHighlight.foreground1": lamp,
    "editorBracketHighlight.foreground2": teal,
    "editorBracketHighlight.foreground3": violet,
    "editorBracketHighlight.foreground4": green,
    "editorBracketHighlight.foreground5": blue,
    "editorBracketHighlight.foreground6": mustard,
    "editorBracketHighlight.unexpectedBracket.foreground": red,
    "editorBracketPairGuide.activeBackground1": a(lamp, 0.5),
    "editorBracketPairGuide.activeBackground2": a(teal, 0.5),
    "editorBracketPairGuide.activeBackground3": a(violet, 0.5),
    "editorBracketPairGuide.activeBackground4": a(green, 0.5),
    "editorBracketPairGuide.activeBackground5": a(blue, 0.5),
    "editorBracketPairGuide.activeBackground6": a(mustard, 0.5),
    "editorInlayHint.foreground": a(sub, 0.75),
    "editorInlayHint.background": a(s0, 0.6),
    "editorInlayHint.typeForeground": a(blueLight, 0.75),
    "editorInlayHint.parameterForeground": a(lampDim, 0.75),
    "editorGhostText.foreground": a(sub, 0.5),
    "editorUnnecessaryCode.opacity": "#00000088",
    "editorStickyScroll.background": base,
    "editorStickyScroll.shadow": a(crust, 0.8),
    "editorStickyScrollHover.background": a(s0, 0.9),
    "editorStickyScroll.border": a(s1, 0.6),
    "editor.foldBackground": a(s0, 0.4),
    "editorGutter.background": base,
    "editorGutter.addedBackground": green,
    "editorGutter.modifiedBackground": blue,
    "editorGutter.deletedBackground": red,
    "editorGutter.foldingControlForeground": ov,
    "editorGutter.commentRangeForeground": a(s2, 0.9),
    "editorError.foreground": red,
    "editorWarning.foreground": mustard,
    "editorInfo.foreground": teal,
    "editorHint.foreground": a(green, 0.8),
    "problemsErrorIcon.foreground": red,
    "problemsWarningIcon.foreground": mustard,
    "problemsInfoIcon.foreground": teal,
    "editorOverviewRuler.border": a(s0, 0.5),
    "editorOverviewRuler.background": base,
    "editorOverviewRuler.errorForeground": a(red, 0.8),
    "editorOverviewRuler.warningForeground": a(mustard, 0.7),
    "editorOverviewRuler.infoForeground": a(teal, 0.6),
    "editorOverviewRuler.findMatchForeground": a(lamp, 0.7),
    "editorOverviewRuler.selectionHighlightForeground": a(teal, 0.5),
    "editorOverviewRuler.modifiedForeground": a(blue, 0.6),
    "editorOverviewRuler.addedForeground": a(green, 0.6),
    "editorOverviewRuler.deletedForeground": a(red, 0.6),
    "editorOverviewRuler.bracketMatchForeground": a(lamp, 0.6),

    # editor widgets (hover, suggest, find, peek)
    "editorWidget.background": mantle,
    "editorWidget.foreground": text,
    "editorWidget.border": a(lamp, 0.14),
    "editorWidget.resizeBorder": a(lamp, 0.4),
    "editorHoverWidget.background": mantle,
    "editorHoverWidget.border": a(lamp, 0.16),
    "editorHoverWidget.statusBarBackground": crust,
    "editorSuggestWidget.background": mantle,
    "editorSuggestWidget.border": a(lamp, 0.16),
    "editorSuggestWidget.foreground": text,
    "editorSuggestWidget.selectedBackground": a(s1, 0.95),
    "editorSuggestWidget.selectedForeground": lamp,
    "editorSuggestWidget.selectedIconForeground": lamp,
    "editorSuggestWidget.highlightForeground": lamp,
    "editorSuggestWidget.focusHighlightForeground": lamp,
    "editorSuggestWidgetStatus.foreground": ov,
    "editorMarkerNavigation.background": mantle,
    "editorMarkerNavigationError.background": red,
    "editorMarkerNavigationWarning.background": mustard,
    "editorMarkerNavigationInfo.background": teal,
    "peekView.border": a(lamp, 0.5),
    "peekViewEditor.background": sunken,
    "peekViewEditor.matchHighlightBackground": a(lamp, 0.25),
    "peekViewEditorGutter.background": sunken,
    "peekViewEditorStickyScroll.background": sunken,
    "peekViewResult.background": mantle,
    "peekViewResult.fileForeground": text,
    "peekViewResult.lineForeground": sub,
    "peekViewResult.matchHighlightBackground": a(lamp, 0.25),
    "peekViewResult.selectionBackground": a(s1, 0.9),
    "peekViewResult.selectionForeground": lamp,
    "peekViewTitle.background": crust,
    "peekViewTitleLabel.foreground": lamp,
    "peekViewTitleDescription.foreground": sub,
    "debugExceptionWidget.background": mantle,
    "debugExceptionWidget.border": red,

    # minimap and scrollbars
    "minimap.background": base,
    "minimap.selectionHighlight": a(s2, 0.9),
    "minimap.findMatchHighlight": a(lamp, 0.6),
    "minimap.errorHighlight": a(red, 0.8),
    "minimap.warningHighlight": a(mustard, 0.7),
    "minimapSlider.background": a(s1, 0.35),
    "minimapSlider.hoverBackground": a(s1, 0.55),
    "minimapSlider.activeBackground": a(s2, 0.65),
    "minimapGutter.addedBackground": green,
    "minimapGutter.modifiedBackground": blue,
    "minimapGutter.deletedBackground": red,
    "scrollbar.shadow": a(crust, 0.6),
    "scrollbarSlider.background": a(s1, 0.5),
    "scrollbarSlider.hoverBackground": a(s2, 0.7),
    "scrollbarSlider.activeBackground": a(lampDim, 0.45),

    # panel (terminal, problems, output)
    "panel.background": mantle,
    "panel.border": a(s1, 0.6),
    "panel.dropBorder": lamp,
    "panelTitle.activeForeground": lamp,
    "panelTitle.activeBorder": lamp,
    "panelTitle.inactiveForeground": quiet,
    "panelSectionHeader.background": crust,
    "panelSectionHeader.foreground": teal,
    "panelInput.border": a(s2, 0.7),
    "panelStickyScroll.background": mantle,
    "outputView.background": mantle,

    # integrated terminal — the same 16 colours as kitty
    "terminal.background": mantle,
    "terminal.foreground": text,
    "terminal.selectionBackground": a(s2, 0.85),
    "terminal.inactiveSelectionBackground": a(s1, 0.6),
    "terminal.findMatchBackground": a(lamp, 0.3),
    "terminal.findMatchHighlightBackground": a(lamp, 0.13),
    "terminal.border": a(s1, 0.6),
    "terminalCursor.foreground": lamp,
    "terminalCursor.background": crust,
    "terminal.dropBackground": a(teal, 0.12),
    "terminalCommandDecoration.defaultBackground": a(ov, 0.8),
    "terminalCommandDecoration.successBackground": green,
    "terminalCommandDecoration.errorBackground": red,
    "terminalOverviewRuler.cursorForeground": a(lamp, 0.6),
    "terminalStickyScroll.background": mantle,
    "terminalStickyScrollHover.background": a(s0, 0.9),
    **{f"terminal.ansi{n}": term[i] for i, n in enumerate([
        "Black", "Red", "Green", "Yellow", "Blue", "Magenta", "Cyan", "White",
        "BrightBlack", "BrightRed", "BrightGreen", "BrightYellow", "BrightBlue",
        "BrightMagenta", "BrightCyan", "BrightWhite"])},

    # status bar — the strip of street below the sky
    "statusBar.background": crust,
    "statusBar.foreground": a(sub, 0.9),
    "statusBar.border": a(s0, 0.6),
    "statusBar.focusBorder": lamp,
    "statusBar.debuggingBackground": a(red, 0.85),
    "statusBar.debuggingForeground": crust,
    "statusBar.debuggingBorder": red,
    "statusBar.noFolderBackground": crust,
    "statusBar.noFolderForeground": sub,
    "statusBarItem.hoverBackground": a(s1, 0.8),
    "statusBarItem.hoverForeground": lamp,
    "statusBarItem.activeBackground": a(s2, 0.8),
    "statusBarItem.remoteBackground": a(teal, 0.85),
    "statusBarItem.remoteForeground": crust,
    "statusBarItem.remoteHoverBackground": teal,
    "statusBarItem.prominentBackground": a(s1, 0.9),
    "statusBarItem.prominentForeground": lamp,
    "statusBarItem.errorBackground": a(red, 0.85),
    "statusBarItem.errorForeground": crust,
    "statusBarItem.warningBackground": a(mustard, 0.85),
    "statusBarItem.warningForeground": crust,
    "statusBarItem.compactHoverBackground": a(s1, 0.8),
    "statusBarItem.focusBorder": lamp,
    "statusBarItem.offlineBackground": a(ov, 0.9),

    # inputs, buttons, dropdowns, badges
    "input.background": a(s0, 0.85),
    "input.foreground": text,
    "input.border": a(s1, 0.9),
    "input.placeholderForeground": a(ov, 0.9),
    "inputOption.activeBackground": a(lamp, 0.18),
    "inputOption.activeBorder": a(lamp, 0.55),
    "inputOption.activeForeground": lamp,
    "inputOption.hoverBackground": a(s1, 0.8),
    "inputValidation.errorBackground": mantle,
    "inputValidation.errorBorder": red,
    "inputValidation.warningBackground": mantle,
    "inputValidation.warningBorder": mustard,
    "inputValidation.infoBackground": mantle,
    "inputValidation.infoBorder": teal,
    "dropdown.background": s0,
    "dropdown.listBackground": mantle,
    "dropdown.border": a(s1, 0.9),
    "dropdown.foreground": text,
    "button.background": lamp,
    "button.foreground": crust,
    "button.hoverBackground": mix(lamp, "#ffffff", 0.25),
    "button.border": a(lamp, 0.3),
    "button.separator": a(crust, 0.4),
    "button.secondaryBackground": s1,
    "button.secondaryForeground": text,
    "button.secondaryHoverBackground": s2,
    "checkbox.background": s0,
    "checkbox.border": a(s2, 0.9),
    "checkbox.foreground": lamp,
    "checkbox.selectBackground": s1,
    "radio.activeBackground": a(lamp, 0.2),
    "radio.activeBorder": lamp,
    "radio.activeForeground": lamp,
    "badge.background": a(lamp, 0.9),
    "badge.foreground": crust,
    "keybindingLabel.background": a(s1, 0.7),
    "keybindingLabel.foreground": lamp,
    "keybindingLabel.border": a(lamp, 0.15),
    "keybindingLabel.bottomBorder": a(crust, 0.6),
    "keybindingTable.headerBackground": crust,
    "keybindingTable.rowsBackground": a(s0, 0.3),
    "settings.headerForeground": lamp,
    "settings.modifiedItemIndicator": mustard,
    "settings.focusedRowBackground": a(s0, 0.6),
    "settings.rowHoverBackground": a(s0, 0.4),
    "settings.focusedRowBorder": a(lamp, 0.3),
    "settings.headerBorder": a(s1, 0.6),
    "settings.sashBorder": a(s1, 0.6),
    "settings.checkboxBackground": s0,
    "settings.dropdownBackground": s0,
    "settings.textInputBackground": a(s0, 0.85),
    "settings.numberInputBackground": a(s0, 0.85),

    # quick input (command palette)
    "quickInput.background": mantle,
    "quickInput.foreground": text,
    "quickInputTitle.background": crust,
    "quickInputList.focusBackground": a(s1, 0.95),
    "quickInputList.focusForeground": lamp,
    "quickInputList.focusIconForeground": lamp,
    "pickerGroup.foreground": teal,
    "pickerGroup.border": a(s1, 0.7),

    # notifications
    "notifications.background": mantle,
    "notifications.foreground": text,
    "notifications.border": a(s1, 0.7),
    "notificationsErrorIcon.foreground": red,
    "notificationsWarningIcon.foreground": mustard,
    "notificationsInfoIcon.foreground": teal,
    "notificationCenter.border": a(lamp, 0.14),
    "notificationCenterHeader.background": crust,
    "notificationCenterHeader.foreground": lamp,
    "notificationToast.border": a(lamp, 0.16),
    "notificationLink.foreground": teal,

    # git and diff
    "gitDecoration.addedResourceForeground": green,
    "gitDecoration.untrackedResourceForeground": green,
    "gitDecoration.modifiedResourceForeground": blueLight,
    "gitDecoration.stageModifiedResourceForeground": blue,
    "gitDecoration.deletedResourceForeground": red,
    "gitDecoration.stageDeletedResourceForeground": red,
    "gitDecoration.renamedResourceForeground": teal,
    "gitDecoration.ignoredResourceForeground": a(ov, 0.75),
    "gitDecoration.conflictingResourceForeground": violet,
    "gitDecoration.submoduleResourceForeground": lampDim,
    "diffEditor.insertedTextBackground": a(green, 0.13),
    "diffEditor.removedTextBackground": a(red, 0.13),
    "diffEditor.insertedLineBackground": a(green, 0.08),
    "diffEditor.removedLineBackground": a(red, 0.08),
    "diffEditor.diagonalFill": a(s1, 0.5),
    "diffEditor.border": a(s1, 0.6),
    "diffEditorGutter.insertedLineBackground": a(green, 0.15),
    "diffEditorGutter.removedLineBackground": a(red, 0.15),
    "multiDiffEditor.headerBackground": mantle,
    "merge.currentHeaderBackground": a(green, 0.35),
    "merge.currentContentBackground": a(green, 0.12),
    "merge.incomingHeaderBackground": a(blue, 0.35),
    "merge.incomingContentBackground": a(blue, 0.12),
    "merge.commonHeaderBackground": a(ov, 0.4),
    "merge.commonContentBackground": a(ov, 0.15),
    "scmGraph.foreground1": lamp,
    "scmGraph.foreground2": teal,
    "scmGraph.foreground3": violet,
    "scmGraph.foreground4": green,
    "scmGraph.foreground5": blue,
    "scmGraph.historyItemRefColor": teal,
    "scmGraph.historyItemRemoteRefColor": violet,
    "scmGraph.historyItemBaseRefColor": mustard,
    "scmGraph.historyItemHoverDefaultLabelForeground": crust,

    # debugging
    "debugToolBar.background": mantle,
    "debugToolBar.border": a(lamp, 0.2),
    "debugIcon.breakpointForeground": red,
    "debugIcon.breakpointDisabledForeground": a(red, 0.4),
    "debugIcon.breakpointUnverifiedForeground": a(red, 0.6),
    "debugIcon.breakpointCurrentStackframeForeground": lamp,
    "debugIcon.breakpointStackframeForeground": lampDim,
    "debugIcon.startForeground": green,
    "debugIcon.pauseForeground": mustard,
    "debugIcon.stopForeground": red,
    "debugIcon.restartForeground": green,
    "debugIcon.stepOverForeground": teal,
    "debugIcon.stepIntoForeground": teal,
    "debugIcon.stepOutForeground": teal,
    "debugIcon.continueForeground": green,
    "debugIcon.disconnectForeground": red,
    "editor.stackFrameHighlightBackground": a(lamp, 0.13),
    "editor.focusedStackFrameHighlightBackground": a(green, 0.13),
    "debugTokenExpression.name": teal,
    "debugTokenExpression.value": text,
    "debugTokenExpression.string": green,
    "debugTokenExpression.number": mustard,
    "debugTokenExpression.boolean": mustard,
    "debugTokenExpression.error": red,
    "debugView.valueChangedHighlight": a(lamp, 0.35),
    "debugView.stateLabelBackground": a(s1, 0.9),
    "debugView.stateLabelForeground": lamp,
    "debugConsole.infoForeground": teal,
    "debugConsole.warningForeground": mustard,
    "debugConsole.errorForeground": red,
    "debugConsole.sourceForeground": sub,
    "debugConsoleInputIcon.foreground": lamp,

    # symbols in outline, breadcrumbs and suggestions
    **{f"symbolIcon.{k}Foreground": v for k, v in {
        "function": lamp, "method": lamp, "constructor": lampDim,
        "variable": text, "field": tealLight, "property": tealLight, "constant": mustard,
        "enumerator": mustard, "enumeratorMember": mustard, "boolean": mustard, "number": mustard,
        "string": green, "key": tealLight, "class": blueLight, "struct": blueLight,
        "interface": blueLight, "typeParameter": blueLight, "module": teal, "namespace": teal,
        "package": teal, "event": violet, "operator": sub, "keyword": teal, "snippet": violet,
        "file": sub, "folder": lampDim, "reference": teal, "unit": mustard, "color": violet,
        "text": text, "array": tealLight, "object": blueLight, "null": red,
    }.items()},

    # misc
    "welcomePage.background": base,
    "welcomePage.tileBackground": mantle,
    "welcomePage.tileHoverBackground": s0,
    "welcomePage.tileBorder": a(lamp, 0.12),
    "welcomePage.progress.foreground": lamp,
    "walkThrough.embeddedEditorBackground": sunken,
    "walkthrough.stepTitle.foreground": lamp,
    "extensionButton.prominentBackground": lamp,
    "extensionButton.prominentForeground": crust,
    "extensionButton.prominentHoverBackground": mix(lamp, "#ffffff", 0.25),
    "extensionBadge.remoteBackground": teal,
    "extensionBadge.remoteForeground": crust,
    "extensionIcon.starForeground": lamp,
    "extensionIcon.verifiedForeground": teal,
    "extensionIcon.preReleaseForeground": violet,
    "editorError.background": None,
    "charts.foreground": text,
    "charts.lines": ov,
    "charts.red": red,
    "charts.blue": blue,
    "charts.yellow": lamp,
    "charts.orange": mustard,
    "charts.green": green,
    "charts.purple": violet,
    "notebook.cellBorderColor": a(s1, 0.7),
    "notebook.focusedCellBorder": a(lamp, 0.45),
    "notebook.cellEditorBackground": sunken,
    "notebook.selectedCellBackground": a(s0, 0.5),
    "notebook.cellHoverBackground": a(s0, 0.3),
    "notebookStatusSuccessIcon.foreground": green,
    "notebookStatusErrorIcon.foreground": red,
    "notebookStatusRunningIcon.foreground": lamp,
    "chat.requestBackground": a(s0, 0.5),
    "chat.requestBorder": a(s1, 0.6),
    "chat.slashCommandForeground": lamp,
    "chat.avatarBackground": s1,
    "chat.avatarForeground": lamp,
    "inlineChat.background": mantle,
    "inlineChat.border": a(lamp, 0.2),
    "testing.iconPassed": green,
    "testing.iconFailed": red,
    "testing.iconQueued": mustard,
    "testing.iconSkipped": ov,
    "testing.runAction": green,
    "ports.iconRunningProcessForeground": green,
    "editorCommentsWidget.resolvedBorder": ov,
    "editorCommentsWidget.unresolvedBorder": lamp,
    "commentsView.resolvedIcon": ov,
    "commentsView.unresolvedIcon": lamp,

    # whisper's own
    "whisper.moon": lamp,

    # Error Lens (inline diagnostics): quiet tints, coloured text
    "errorLens.errorBackground": a(red, 0.07),
    "errorLens.errorForeground": a(red, 0.9),
    "errorLens.warningBackground": a(mustard, 0.06),
    "errorLens.warningForeground": a(mustard, 0.85),
    "errorLens.infoBackground": a(teal, 0.06),
    "errorLens.infoForeground": a(teal, 0.85),
    "errorLens.hintBackground": a(green, 0.05),
    "errorLens.hintForeground": a(green, 0.8),
    "errorLens.statusBarErrorForeground": red,
    "errorLens.statusBarWarningForeground": mustard,
}
colors = {k: v for k, v in colors.items() if v is not None}

# ── syntax ───────────────────────────────────────────────────────────────
def rule(name, scopes, fg=None, style=None):
    s = {}
    if fg: s["foreground"] = fg
    if style is not None: s["fontStyle"] = style
    return {"name": name, "scope": scopes, "settings": s}

tokens = [
    rule("comments — pencil on the night", ["comment", "punctuation.definition.comment", "string.comment"], comment, "italic"),
    rule("doc comment tags", ["comment.block.documentation storage.type", "comment.block.documentation entity.name.type",
                              "storage.type.class.doxygen", "storage.type.class.jsdoc", "keyword.other.documentation"], teal, "italic"),
    rule("doc comment names", ["comment.block.documentation variable", "variable.parameter.doxygen"], lampDim, "italic"),
    rule("plain text", ["source", "text"], text),
    rule("variables", ["variable", "variable.other", "variable.other.readwrite", "meta.definition.variable.name"], text),
    rule("parameters — italic, softly lit", ["variable.parameter", "meta.parameter", "entity.name.variable.parameter"], mix(text, lampDim, 0.45), "italic"),
    rule("language variables (this, self)", ["variable.language", "variable.language.this", "variable.language.self", "variable.language.super"], red, "italic"),
    rule("keywords — the teal of the night sky", ["keyword", "keyword.control", "storage.modifier", "keyword.other.using",
                                                  "keyword.other.import", "keyword.control.import", "keyword.control.from", "keyword.control.export"], teal),
    rule("flow control", ["keyword.control.flow", "keyword.control.conditional", "keyword.control.loop", "keyword.control.return",
                          "keyword.control.trycatch", "keyword.control.switch", "keyword.control.case", "keyword.control.default",
                          "keyword.control.goto", "keyword.control.c", "keyword.control.cpp"], teal, "italic"),
    rule("storage and types", ["storage.type", "storage.type.built-in", "support.type", "support.type.primitive",
                               "keyword.type", "storage.type.primitive", "storage.type.numeric"], blue),
    rule("user types, classes, structs", ["entity.name.type", "entity.name.class", "entity.name.struct", "entity.name.union",
                                          "entity.name.enum", "entity.name.interface", "entity.other.inherited-class",
                                          "support.class", "entity.name.type.class", "entity.name.namespace", "entity.name.scope-resolution"], blueLight),
    rule("functions — lamplight", ["entity.name.function", "support.function", "meta.function-call entity.name.function",
                                   "entity.name.function.member", "entity.name.function.call", "variable.function",
                                   "support.function.builtin", "meta.function-call.generic"], lamp),
    rule("macros and the preprocessor — violet", ["entity.name.function.preprocessor", "entity.name.function.macro",
                                                  "meta.preprocessor", "keyword.control.directive", "punctuation.definition.directive",
                                                  "keyword.other.preprocessor", "meta.preprocessor.macro", "entity.name.other.preprocessor",
                                                  "support.other.macro", "keyword.directive"], violet),
    rule("include paths", ["meta.preprocessor.include string", "string.quoted.other.lt-gt.include",
                           "meta.preprocessor.include punctuation.definition.string"], mix(green, teal, 0.4)),
    rule("strings — the green of the bushes", ["string", "string.quoted", "string.template", "string.unquoted"], green),
    rule("string escapes and placeholders", ["constant.character.escape", "constant.other.placeholder", "constant.character.format.placeholder",
                                             "punctuation.definition.template-expression", "constant.character.string.escape"], mustard),
    rule("regex", ["string.regexp"], tealLight),
    rule("numbers and constants — warm windows", ["constant.numeric", "constant.language", "constant.other", "constant",
                                                  "support.constant", "variable.other.constant", "variable.other.enummember",
                                                  "entity.name.constant", "constant.language.boolean", "constant.language.null"], mustard),
    rule("characters", ["constant.character", "string.quoted.single.c"], mix(green, mustard, 0.35)),
    rule("properties and fields", ["variable.other.property", "variable.other.member", "variable.other.object.property",
                                   "support.variable.property", "meta.object-literal.key", "entity.name.tag.yaml",
                                   "support.type.property-name", "variable.object.property"], tealLight),
    rule("operators", ["keyword.operator", "keyword.operator.assignment", "keyword.operator.arithmetic", "keyword.operator.logical",
                       "keyword.operator.comparison", "keyword.operator.bitwise", "keyword.operator.increment", "keyword.operator.decrement"], sub),
    rule("word operators (sizeof, new, delete)", ["keyword.operator.sizeof", "keyword.operator.new", "keyword.operator.delete",
                                                  "keyword.operator.expression", "keyword.operator.alignof", "keyword.operator.typeof"], teal),
    rule("punctuation", ["punctuation", "meta.brace", "punctuation.separator", "punctuation.terminator", "punctuation.accessor"], a(sub, 0.75)),
    rule("labels", ["entity.name.label", "entity.name.goto-label", "punctuation.definition.label"], mustard, "italic"),
    rule("attributes and decorators", ["entity.other.attribute-name", "meta.attribute", "meta.decorator", "punctuation.decorator",
                                       "storage.type.annotation", "keyword.other.attribute"], violet, "italic"),
    rule("invalid", ["invalid", "invalid.illegal"], red),
    rule("deprecated", ["invalid.deprecated"], red, "strikethrough"),

    # assembly (x86 — your OS's boot code); 13xforever.language-x86-64-assembly
    # names instructions keyword.operator.word.mnemonic.* (more specific than
    # the operators rule above, so they win)
    rule("asm mnemonics", ["keyword.operator.word.mnemonic", "keyword.operator.word.pseudo-mnemonic"], teal),
    rule("asm registers (x86-64 grammar)", ["constant.language.register"], violet),
    rule("asm labels (x86-64 grammar)", ["entity.name.function.asm", "entity.name.function.special.asm"], lamp),
    rule("asm directives (x86-64 grammar)", ["support.function.asm", "support.function.preprocessor.asm",
                                             "support.function.smartalign.asm", "entity.directive", "storage.type.asm"], blue, "italic"),
    rule("asm sections", ["entity.name.section"], mustard, "bold"),
    # assembly (other grammars)
    rule("asm instructions", ["keyword.control.instruction", "support.function.mnemonic", "keyword.instruction",
                              "support.function.instruction", "keyword.mnemonic"], teal),
    rule("asm registers", ["variable.parameter.register", "support.variable.register", "storage.other.register",
                           "variable.language.register", "constant.language.register", "variable.register"], violet),
    rule("asm directives", ["support.function.directive", "keyword.control.directive.asm", "storage.type.directive",
                            "keyword.directive.asm", "support.directive"], blue, "italic"),
    rule("asm labels", ["entity.name.function.label", "entity.name.label.asm", "meta.label"], lamp),
    # linker scripts and Makefiles
    rule("make targets", ["entity.name.function.target.makefile", "entity.name.function.target"], lamp),
    rule("make variables", ["variable.other.makefile", "variable.language.makefile"], tealLight),

    # markup
    rule("headings", ["markup.heading", "markup.heading entity.name", "entity.name.section"], lamp, "bold"),
    rule("bold", ["markup.bold"], mustard, "bold"),
    rule("italic", ["markup.italic"], text, "italic"),
    rule("strikethrough", ["markup.strikethrough"], ov, "strikethrough"),
    rule("links", ["markup.underline.link", "string.other.link", "markup.link"], teal, "underline"),
    rule("inline code", ["markup.inline.raw", "markup.raw", "markup.fenced_code"], green),
    rule("quotes", ["markup.quote"], sub, "italic"),
    rule("lists", ["markup.list punctuation.definition.list", "punctuation.definition.list.begin"], lamp),
    rule("diff inserted", ["markup.inserted", "meta.diff.header.to-file"], green),
    rule("diff deleted", ["markup.deleted", "meta.diff.header.from-file"], red),
    rule("diff changed", ["markup.changed"], blue),
    rule("diff headers", ["meta.diff.range", "meta.diff.header"], violet),
    rule("html/xml tags", ["entity.name.tag", "punctuation.definition.tag"], teal),
    rule("css selectors", ["entity.other.attribute-name.class.css", "entity.other.attribute-name.id.css", "entity.name.tag.css"], lamp),
    rule("json keys", ["support.type.property-name.json", "meta.mapping.key string", "support.type.property-name.toml",
                       "entity.name.tag.toml", "keyword.key.toml"], tealLight, ""),
    rule("nix attributes", ["entity.other.attribute-name.single.nix", "entity.other.attribute-name.multipart.nix",
                            "variable.other.attribute.nix"], tealLight, ""),   # "" resets the italic attribute-name rule above
    rule("nix identifiers", ["variable.parameter.name.nix", "variable.parameter.function.1.nix", "variable.other.nix",
                             "meta.function.nix variable.parameter"], text, ""),
    rule("nix interpolation", ["punctuation.section.embedded.begin.nix", "punctuation.section.embedded.end.nix"], mustard),
    rule("shell variables", ["variable.other.normal.shell", "variable.other.positional.shell", "variable.other.special.shell",
                             "punctuation.definition.variable.shell"], tealLight),
]

semantic = {
    "function": lamp, "method": lamp, "function.defaultLibrary": lamp,
    "macro": violet, "macro.defaultLibrary": violet,
    "variable": text, "variable.readonly": mustard, "variable.global": {"foreground": text, "bold": True},
    "variable.static": {"foreground": text, "underline": False},
    "parameter": {"foreground": mix(text, lampDim, 0.45), "italic": True},
    "property": tealLight, "property.readonly": tealLight,
    "enumMember": mustard, "enum": blueLight,
    "type": blueLight, "type.defaultLibrary": blue, "class": blueLight, "struct": blueLight,
    "interface": blueLight, "typeParameter": {"foreground": blueLight, "italic": True},
    "namespace": teal, "concept": blueLight,
    "label": {"foreground": mustard, "italic": True},
    "comment": {"foreground": comment, "italic": True},
    "operator": sub, "keyword": teal, "string": green, "number": mustard,
    "unknown": {"foreground": a(red, 0.85), "underline": True},
    "*.deprecated": {"strikethrough": True},
    "*.declaration": {"bold": False},
}

theme = {
    "name": "Whisper",
    "type": "dark",
    "semanticHighlighting": True,
    "colors": colors,
    "tokenColors": tokens,
    "semanticTokenColors": semantic,
}

# ── write the extension ──────────────────────────────────────────────────
os.makedirs(os.path.join(out, "themes"), exist_ok=True)
if css_only:
    os.makedirs(out, exist_ok=True)
json.dump(theme, open(os.path.join(out, "themes", "whisper-color-theme.json"), "w"), indent=2)
for f in os.listdir(src):
    if f.endswith((".js", ".md", ".svg", ".png")) or f == "package.json":
        shutil.copyfile(os.path.join(src, f), os.path.join(out, f))   # content only: store files are read-only
if os.path.isdir(os.path.join(src, "snippets")):
    os.makedirs(os.path.join(out, "snippets"), exist_ok=True)
    for f in os.listdir(os.path.join(src, "snippets")):
        shutil.copyfile(os.path.join(src, "snippets", f), os.path.join(out, "snippets", f))
# ── workbench CSS (patched into VS Code itself, see default.nix) ─────────
import re, urllib.parse
moon = f"""<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 160 160'>
<defs><radialGradient id='g' cx='50%' cy='50%' r='50%'><stop offset='0' stop-color='{lamp}' stop-opacity='.35'/><stop offset='1' stop-color='{lamp}' stop-opacity='0'/></radialGradient>
<mask id='m'><rect width='160' height='160' fill='white'/><circle cx='98' cy='66' r='34' fill='black'/></mask></defs>
<circle cx='80' cy='80' r='70' fill='url(#g)'/>
<circle cx='80' cy='80' r='38' fill='{lamp}' mask='url(#m)'/>
<circle cx='80' cy='80' r='38' fill='none' stroke='{sub}' stroke-opacity='.18'/>
<circle cx='132' cy='34' r='1.6' fill='{text}'/><circle cx='26' cy='46' r='1.2' fill='{text}' opacity='.7'/>
<circle cx='120' cy='128' r='1.1' fill='{text}' opacity='.6'/><circle cx='38' cy='120' r='1.5' fill='{teal}' opacity='.8'/>
</svg>"""
vals = dict(p, subtext=sub, moon_svg=urllib.parse.quote(moon.replace("\n", "")))

def fill(m):
    k = m.group(1)
    if k in vals: return vals[k]
    base_, _, al = k.rpartition("_a")
    if base_ in p and re.fullmatch(r"[0-9a-f]{2}", al): return p[base_] + al
    return m.group(0)

tmpl = open(os.path.join(src, "workbench.css.in")).read()
open(os.path.join(out, "whisper-workbench.css"), "w").write(re.sub(r"\{([a-zA-Z0-9_]+)\}", fill, tmpl))
if css_only:
    print("whisper vscode: workbench css"); sys.exit(0)

# …and package it as a .vsix, the only form VS Code will register
import zipfile, hashlib
man = json.load(open(os.path.join(out, "package.json")))
# every build gets its own patch version (from the content), so a palette
# change installs as an upgrade — VS Code won't replace the same version while
# it's running
h = hashlib.sha256()
for root, _, files in sorted(os.walk(out)):
    for f in sorted(files):
        if f.endswith(".vsix") or f == "whisper-workbench.css": continue
        h.update(f.encode()); h.update(open(os.path.join(root, f), "rb").read())
major, minor, _ = man["version"].split(".")
man["version"] = f"{major}.{minor}.{int(h.hexdigest()[:7], 16)}"
json.dump(man, open(os.path.join(out, "package.json"), "w"), indent=2)
vsix = os.path.join(out, "whisper.vsix")
manifest = f"""<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
  <Metadata>
    <Identity Language="en-US" Id="{man['name']}" Version="{man['version']}" Publisher="{man['publisher']}"/>
    <DisplayName>{man['displayName']}</DisplayName>
    <Description xml:space="preserve">{man['description']}</Description>
    <Categories>Themes,Other</Categories>
    <Properties>
      <Property Id="Microsoft.VisualStudio.Code.Engine" Value="{man['engines']['vscode']}"/>
    </Properties>
  </Metadata>
  <Installation><InstallationTarget Id="Microsoft.VisualStudio.Code"/></Installation>
  <Dependencies/>
  <Assets>
    <Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true"/>
  </Assets>
</PackageManifest>
"""
types = """<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension=".json" ContentType="application/json"/><Default Extension=".js" ContentType="application/javascript"/>
  <Default Extension=".vsixmanifest" ContentType="text/xml"/><Default Extension=".css" ContentType="text/css"/>
  <Default Extension=".svg" ContentType="image/svg+xml"/><Default Extension=".md" ContentType="text/markdown"/>
</Types>
"""
# fixed timestamps and order: the same inputs always give the same .vsix
def entry(name):
    return zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
with zipfile.ZipFile(vsix, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr(entry("extension.vsixmanifest"), manifest)
    z.writestr(entry("[Content_Types].xml"), types)
    for root, dirs, files in sorted(os.walk(out)):
        dirs.sort()
        for f in sorted(files):
            full = os.path.join(root, f)
            if full == vsix or f == "whisper-workbench.css": continue
            z.writestr(entry("extension/" + os.path.relpath(full, out)), open(full, "rb").read(), zipfile.ZIP_DEFLATED)
print(f"whisper vscode: {len(colors)} colours, {len(tokens)} syntax rules -> {os.path.basename(vsix)}")
