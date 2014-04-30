


Meteor.startup ->
	window.setInterval ->
		MathJax.Hub.Queue(["Typeset",MathJax.Hub])
	,1200
	$(document.body).on "click", ->
		
		$("body").removeClass "editing"
		$(".element").removeClass "editing"
		Session.set "activeElement", null



Router.map ->
	@route 'sheet',
		path: "/sheet/:_id",
		waitOn: ->
			Meteor.subscribe 'sheets'
		data: ->
			{
				sheet_id: @params._id
				sheet: Sheets.findOne({_id: @params._id})
			}

		action: ->
			if @ready()
				@render()
			else
				@render "loading"


Template.sheet.elements = ->
	
	Elements.find {sheet_id: @sheet_id}, sort: position: 1


updateElement = (element_id, text) ->
	console.log "update element"
	if text?.length == 0
		Elements.remove {_id: element_id}
	else
		Elements.update {_id: element_id}, $set: content: text

saveNewElement = (sheet_id, text) ->
	
	lastElement = getLastElement()
	
	if lastElement?
		lastPosition = lastElement.position
	else
		lastPosition = 0
	
	Meteor.call "increasePositions", sheet_id, lastPosition, ->
		Session.set "activeElement", Elements.insert
			sheet_id: sheet_id
			content: text
			position: lastPosition+1
		window.setTimeout ->
			$(".editor-tail").focus()
		,100

	
getLastElement = ->
	Elements.findOne _id: Session.get "activeElement"

	

Template.oneElement.rendered = ->
	MathJax.Hub.Queue(["Typeset",MathJax.Hub])


Template.oneElement.isActiveElement = ->
	@_id == Session.get "activeElement"


Template.oneElement.events
	"click .element": (event, template) ->
		Session.set "activeElement", template.data._id
		$("body").addClass "editing"
		$(".element").removeClass "editing"
		template.$(".element").addClass "editing"
		template.$(".editor-element").focus()
		return false


hasDoublePressedEnter = (event) ->
	unless event.ctrlKey or event.shiftKey
		if Session.get("lastKey") == 13 == event.which
			Session.set "lastKey", null
			return true
		else
			Session.set "lastKey", event.which
	return false



Template.sheet.events
	"blur .editor-tail": (event, template) ->
		
		text = $(event.target).val()
		if text.length > 0
			console.log text
			saveNewElement template.data.sheet_id, text
			$(event.target).val ""
	"keyup .editor-tail": (event, template) ->
		if hasDoublePressedEnter event
			saveNewElement template.data.sheet_id, $(event.target).val()
			$(event.target).val ""
	"click .editor-tail": (event, template) ->
		$("body").removeClass "editing"
		$(".element").removeClass "editing"
		return false

Template.oneElement.events
	"blur .editor-element": (event, template) ->
		
		updateElement template.data._id, $(event.target).val()
		template.$(".element").removeClass "editing"
		$("body").removeClass "editing"
	"keyup .editor-element": (event, template) ->
		if hasDoublePressedEnter event
			updateElement template.data._id, $(event.target).val()
			template.$(".element").removeClass "editing"
			$("body").removeClass "editing"

	"drop .element": (event, template) ->
		
		fromID = event.originalEvent.dataTransfer.getData '_id'
		toID = template.data._id
		# swap positions
		element1 = Elements.findOne _id: fromID
		element2 = Elements.findOne _id: toID
		Elements.update {_id: fromID}, $set: position: element2.position
		Elements.update {_id: toID}, $set: position: element1.position
		
		return false
	"dragover .element": (event, template) ->
		event.preventDefault()
		#console.log event, template
	"dragstart .element": (event, template) ->
		event.originalEvent.dataTransfer.setData '_id', @_id


