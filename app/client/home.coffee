Router.map ->
	@route 'home',
		path: "/"
		data: ->
			sheets: Sheets.find {}, sort: name: 1

createSheet = ->
	sheet_id = Sheets.insert {}
	Router.go "sheet", _id: sheet_id

Template.home.events
	"click .btn-create-sheet": createSheet

Template.home.sheetName = ->
	element = Elements.findOne {sheet_id: @_id}, sort: position: 1
	if element?.content?.trim().length > 0
		element.content.trim()
	else
		@_id