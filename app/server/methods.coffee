


removeElement = (element) ->

	decreasePositions element.sheet_id, element.position
	Elements.remove {_id: element._id}

preparePositionQuery = (sheet_id, fromPosition, toPosition)->
	query = 
		sheet_id: sheet_id, 
		position: 
			$gt: fromPosition
	if toPosition?
		query.position.$lt = toPosition
	query


increasePositions = (sheet_id, fromPosition, toPosition = null) ->
	query = preparePositionQuery sheet_id, fromPosition, toPosition
	
	Elements.update query,{$inc: position: 1},{multi: true }

decreasePositions =  (sheet_id, fromPosition, toPosition = null) ->
	query = preparePositionQuery sheet_id, fromPosition, toPosition

	Elements.update query,{$inc: position: -1},{multi: true }


Meteor.methods 
	addSheet: ->
		if @userId != null
			sheet_id = Sheets.insert {user_id: @userId}
		else
			throw new Meteor.Error(401, "Unauthorized");

	removeSheet: (sheet_id) ->
		# user has to match
		sheet = Sheets.findOne _id: sheet_id, user_id: @userId
		
		if sheet?
			Elements.remove sheet_id: sheet_id
			Images.remove sheet_id: sheet_id
			Sheets.remove _id: sheet_id

	moveElement: (element_id, toPosition) ->

		element = Elements.findOne _id: element_id
		if element? and ElementTools.userCanEdit @userId, element.sheet_id
			if toPosition > element.position
				# move down
				decreasePositions element.sheet_id, element.position, toPosition+1
				Elements.update {_id: element_id}, $set: position: toPosition
				updateSheetName element.sheet_id
			else if toPosition < element.position
				# move up
				increasePositions element.sheet_id, toPosition-1,  element.position
				Elements.update {_id: element_id}, $set: position: toPosition
				updateSheetName element.sheet_id
			else
				# do nothing
		else	
			throw new Meteor.Error(401, "Unauthorized");
	removeElement: (element_id) ->
		element = Elements.findOne _id: element_id
		if element? and ElementTools.userCanEdit @userId, element.sheet_id
			removeElement element
			updateSheetName element.sheet_id
		


	addElement: (sheet_id, content, afterElementPosition = null) ->

		if content.replace(/^\s+|\s+$/g, '').trim().length > 0 and ElementTools.userCanEdit @userId, sheet_id
			
			unless afterElementPosition?
				afterElementPosition = ElementTools.getLastPosition sheet_id
			
			increasePositions sheet_id, afterElementPosition
			new_element_id = Elements.insert
				sheet_id: sheet_id
				user_id: @userId
				content: content
				position: afterElementPosition+1
			updateSheetName sheet_id
			return new_element_id	
		else
			throw new Meteor.Error(401, "Unauthorized")
		

	updateElement: (element_id, content) ->
		element = Elements.findOne _id: element_id
		if element? and ElementTools.userCanEdit @userId, element.sheet_id
			if content?.replace(/^\s+|\s+$/g, '').trim().length == 0
				removeElement element
			else
				Elements.update {_id: element_id}, $set: content: content
			updateSheetName element.sheet_id
		else
			throw new Meteor.Error(401, "Unauthorized")


updateSheetName = (sheet_id) ->
	firstElelement = Elements.findOne {sheet_id: sheet_id}, sort: position: 1
	if firstElelement?.content?.trim().length > 0
		Sheets.update {_id: sheet_id}, $set: name: firstElelement.content.trim()
	
Meteor.publish "sheets", ->
	Sheets.find()


Meteor.publish "elements", (sheet_id)->
	Elements.find sheet_id: sheet_id

Meteor.publish "images", (sheet_id) ->
	Images.find sheet_id: sheet_id


