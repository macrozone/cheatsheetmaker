SHEET_ID = 1


Meteor.startup ->
	$(document.body).on "click", ->
		
		$("body").removeClass "editing"
		$(".element").removeClass "editing"
		lastElement = Elements.findOne sheet_id: SHEET_ID, sort: position: -1
		Session.set "activeElement", lastElement?._id

Template.debug.lastKey = ->
	Session.get "lastKey"



saveText = (text, element_id = null) ->
	if element_id?
		if text?.length == 0
			Elements.remove {_id: element_id}
		else
			Elements.update {_id: element_id}, $set: content: text
	else
		lastElement = getLastElement()
		
		if lastElement?
			lastPosition = lastElement.position
		else
			lastPosition = 0
		
		Meteor.call "increasePositions", SHEET_ID, lastPosition, ->
			Session.set "activeElement", Elements.insert
				sheet_id: SHEET_ID
				content: text
				position: lastPosition+1
			window.setTimeout ->
				$(".editor-tail").focus()
			,100


	
getLastElement = ->
	Elements.findOne _id: Session.get "activeElement"

Template.sheet.elements = ->
	Elements.find {sheet_id: SHEET_ID}, sort: position: 1

Template.oneElement.rendered = ->
	MathJax.Hub.Queue(["Typeset",MathJax.Hub])
Template.oneElement.content = ->
	MathJax.Hub.Queue(["Typeset",MathJax.Hub])
	@content

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
		console.log "blur"
		text = $(event.target).val()
		if text.length > 0
			saveText text
			$(event.target).val ""
	"keyup .editor-tail": (event, template) ->
		if hasDoublePressedEnter event
			saveText $(event.target).val()
			$(event.target).val ""
	"click .editor-tail": (event, template) ->
		$("body").removeClass "editing"
		$(".element").removeClass "editing"
		return false

Template.oneElement.events
	"blur .editor-element": (event, template) ->
		
		saveText $(event.target).val(), template.data._id
		template.$(".element").removeClass "editing"
		$("body").removeClass "editing"
	"keyup .editor-element": (event, template) ->
		if hasDoublePressedEnter event
			saveText $(event.target).val(), template.data._id
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
		console.log event
		event.originalEvent.dataTransfer.setData '_id', @_id


