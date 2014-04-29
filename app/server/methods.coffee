

Meteor.methods 
	"increasePositions": (sheet_id, lastPosition) ->
		Elements.update {sheet_id: sheet_id, position: $gt: lastPosition},{$inc: position: 1},{multi: true }
