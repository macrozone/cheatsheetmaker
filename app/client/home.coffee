Router.map ->
	@route 'home',
		path: "/"
		waitOn: ->
			Meteor.subscribe 'sheets'
		data: ->
			allSheets: Sheets.find {}, sort: name: 1
			userSheets: Sheets.find {user_id: Meteor.userId()}, sort: name: 1

		action: ->
			if @ready()
				@render()
			else
				@render "loading"		
createSheet = ->
	Meteor.call "addSheet", (error, sheet_id) ->
		console.log error, sheet_id
		Router.go "sheet", _id: sheet_id

Template.home.events
	"click .btn-create-sheet": createSheet

