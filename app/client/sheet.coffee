

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
			Meteor.subscribe 'elements', @params._id
			Meteor.subscribe 'images', @params._id
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
	Meteor.call "updateElement", element._id, content

saveNewElement = (sheet_id, content, afterElement = null, callback = null) ->
	if content.replace(/^\s+|\s+$/g, '').trim().length > 0
		unless afterElement?
			afterElement = getActiveElement sheet_id
		
		
		Meteor.call "addElement", sheet_id, content, afterElement?.position, (error, new_element_id)->
			Session.set "activeElement", new_element_id
			if _.isFunction callback
				callback null, new_element_id
			window.setTimeout ->
				$(".editor-tail").focus()
			,100


	
getActiveElement = (sheet_id)->
	Elements.findOne _id: Session.get "activeElement", sheet_id: sheet_id
	
	

Template.oneElement.rendered = ->
	processMathJax()


Template.oneElement.isActiveElement = ->
	@_id == Session.get "activeElement"


Template.oneElement.events
	"click .element": (event, template) ->

		if ElementTools.userCanEdit Meteor.userId(), template.data.sheet_id
			Session.set "activeElement", template.data._id
			$("body").addClass "editing"
			$(".element").removeClass "editing"
			template.$(".element").addClass "editing"
			template.$(".editor-element").focus()
			return false
	"blur .editor-element": (event, template) ->
		if ElementTools.userCanEdit Meteor.userId(), template.data.sheet_id
			updateElement template.data, $(event.target).val()
			template.$(".element").removeClass "editing"
			$("body").removeClass "editing"
	"keyup .editor-element": (event, template) ->
		if hasDoublePressedEnter(event) and ElementTools.userCanEdit(Meteor.userId(), template.data.sheet_id)
			updateElement template.data, $(event.target).val()
			template.$(".element").removeClass "editing"
			$("body").removeClass "editing"

	"dropped .element": (event, template) ->

		if ElementTools.userCanEdit Meteor.userId(), template.data.sheet_id
			target_element_id = template.data._id
			targetElement = Elements.findOne _id: target_element_id

			dropped_element_id = event.originalEvent?.dataTransfer?.getData 'element_id'

			if dropped_element_id? and dropped_element_id.length > 0
				Meteor.call "moveElement", dropped_element_id, targetElement.position
			else
				handleFileDrops event, targetElement.sheet_id, targetElement		
			return false
	"dragover .element": (event, template) ->
		
		event.preventDefault()
		#console.log event, template
	"dragstart .element": (event, template) ->
		event.originalEvent.dataTransfer.setData 'element_id', @_id


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

Template.sheet_author.username = ->
	Meteor.user()?.profile?.name

Template.sheet_author.year = ->
	new Date().getFullYear()
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
		newFile.user_id = Meteor.userId()
		newFile.sheet_id = sheet_id
		Images.insert newFile, (error, fileObj) ->
			if error?
				console.error error
			else
				content = "![#{fileObj.name()}](#{fileObj._id})"
				saveNewElement sheet_id, content, insertFileAfterElement
			



