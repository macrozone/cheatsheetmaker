

Meteor.methods 
	"increasePositions": (sheet_id, fromPosition, toPosition = null) ->
		query = 
			sheet_id: sheet_id, 
			position: 
				$gt: fromPosition
		if toPosition?
			query.position.$lt = toPosition
		

		Elements.update query,{$inc: position: 1},{multi: true }

	"decreasePositions": (sheet_id, fromPosition, toPosition = null) ->
		query = 
			sheet_id: sheet_id, 
			position: 
				$gt: fromPosition
		if toPosition?
			query.position.$lt = toPosition
	

		Elements.update query,{$inc: position: -1},{multi: true }

Meteor.publish "sheets", ->
	Sheets.find {}