

exitEditMode = ->

	$("body").removeClass "editing"
	$(".element").removeClass "editing"

	Session.set "activeElement", null

processMathJax = ->
	# little trick to overcome conflicts between mathjax and markdown
	$(".math code").each (index, element) ->
		$code = $(element)
		$code.parent().html $code.html()
		MathJax.Hub.Queue(["Typeset",MathJax.Hub])
	
	

Meteor.startup ->
	window.setInterval ->
		processMathJax()
	,600
	$(document.body).on "click", ->
		exitEditMode()
		
	$(document).on "keyup", (event)->
		if event.which == 27
			exitEditMode()


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


updateElement = (element, content) ->
	
	if content?.replace(/^\s+|\s+$/g, '').trim().length == 0
		Meteor.call "decreasePositions", element.sheet_id, element.position, null, ->
			Elements.remove {_id: element._id}
	else
		Elements.update {_id: element._id}, $set: content: content

saveNewElement = (sheet_id, content, afterElement = null, callback = null) ->
	if content.replace(/^\s+|\s+$/g, '').trim().length > 0
		unless afterElement?
			afterElement = getLastElement sheet_id
		
		if afterElement?
			lastPosition = afterElement.position
		else
			lastPosition = 0
		
		Meteor.call "increasePositions", sheet_id, lastPosition, null, ->
			new_element_id = Elements.insert
				sheet_id: sheet_id
				content: content
				position: lastPosition+1
			Session.set "activeElement", new_element_id
			if _.isFunction callback
				callback null, new_element_id
			window.setTimeout ->
				$(".editor-tail").focus()
			,100


	
getLastElement = (sheet_id)->
	element = Elements.findOne _id: Session.get "activeElement", sheet_id: sheet_id
	unless element?
		# get last
		element = Elements.findOne {sheet_id: sheet_id}, sort: position: -1
	element
	

Template.oneElement.rendered = ->
	processMathJax()


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

escapeRegExp = (str) ->
  str.replace /[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&"

preprocessMath = (string) ->

	regex = /(\$[^$]+\$)/g
	string = string.replace regex, "<span class='math'>`$1`</span>"
preprocessHtmlImages = (string) ->
	regex = /src=\"([a-zA-Z0-9]+)\"/g
	matches = regex.exec string
	if matches? 
		[full, imageID] = matches
		image = Images.findOne _id: imageID
		if image?
			what = new RegExp(escapeRegExp full, "g")
			replacement = "src='#{escape(image.url())}'"
			string = string.replace what, replacement
	string
preprocessMarkdownImages = (string) ->
	regex = /!(\[[^\]]+\])?\(([a-zA-Z0-9]+)\)/g
	matches = regex.exec string
	if matches? 
		[full, altPart, imageID] = matches

		image = Images.findOne _id: imageID
		if image?
			altPart = "[#{image.name()}]" unless altPart?
			what = new RegExp(escapeRegExp full, "g")
			replacement = "!#{altPart}(#{escape(image.url())})"
			string = string.replace what, replacement
	string
Template.oneElement.contentProcessed = ->
	string = @content
	#regex = new RegExp '\\!(\\[[^]]+\\])?\\(([a-zA-Z0-9]+)\\)', "g"
	string = preprocessHtmlImages string
	string = preprocessMarkdownImages string
	string = preprocessMath string

	string

Template.sheet.events
	"blur .editor-tail": (event, template) ->
		
		text = $(event.target).val()
		if text.replace(/^\s+|\s+$/g, '').trim().length > 0

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
	"dropped .sheet": (event, template) ->
		handleFileDrops event, template.data.sheet_id

handleFileDrops = (event, sheet_id, insertFileAfterElement = null) ->
	# check if file
	FS.Utility.eachFile event, (file) ->
		newFile = new FS.File(file)
		Images.insert newFile, (error, fileObj) ->
			if error?
				console.error error
		
			content = "![#{fileObj.name()}](#{fileObj._id})"
			saveNewElement sheet_id, content, insertFileAfterElement
		

Template.oneElement.events
	"blur .editor-element": (event, template) ->
		
		updateElement template.data, $(event.target).val()
		template.$(".element").removeClass "editing"
		$("body").removeClass "editing"
	"keyup .editor-element": (event, template) ->
		if hasDoublePressedEnter event
			updateElement template.data, $(event.target).val()
			template.$(".element").removeClass "editing"
			$("body").removeClass "editing"

	"dropped .element": (event, template) ->
		target_element_id = template.data._id
		targetElement = Elements.findOne _id: target_element_id
		
		dropped_element_id = event.originalEvent?.dataTransfer?.getData 'element_id'

		if dropped_element_id? and dropped_element_id.length > 0
			
			
			droppedElement = Elements.findOne _id: dropped_element_id
			distance = targetElement.position - droppedElement.position
			
			if distance == 0
				# do nothing
			else if distance == 1 or distance == -1

				# swap positions
				Elements.update {_id: dropped_element_id}, $set: position: targetElement.position
				Elements.update {_id: target_element_id}, $set: position: droppedElement.position
			else if distance < -1
				
				Meteor.call "increasePositions", targetElement.sheet_id, targetElement.position-1,  droppedElement.position, ->
					Elements.update {_id: dropped_element_id}, $set: position: targetElement.position
			else if distance > 1
				#down
				
				Meteor.call "decreasePositions", targetElement.sheet_id, droppedElement.position, targetElement.position+1, ->
					Elements.update {_id: dropped_element_id}, $set: position: targetElement.position
				

		else
			handleFileDrops event, targetElement.sheet_id, targetElement		
					
		
		
		return false
	"dragover .element": (event, template) ->
		event.preventDefault()
		#console.log event, template
	"dragstart .element": (event, template) ->
		console.log event
		event.originalEvent.dataTransfer.setData 'element_id', @_id


