
UI.registerHelper "userCanEdit", (sheet_id) ->
	
	ElementTools.userCanEdit Meteor.userId?(), sheet_id