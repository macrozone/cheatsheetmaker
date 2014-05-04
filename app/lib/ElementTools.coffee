
@ElementTools = 
	getLastPosition: (sheet_id)->
		element = Elements.findOne {sheet_id: sheet_id}, sort: position: -1
		if element?
			element.position
		else
			0

	userCanEdit: (user_id, sheet_id) ->
		sheet = Sheets.findOne _id: sheet_id
		user_id? and user_id == sheet?.user_id or sheet?.public_writable
