Template.infos.status = ->
	Meteor.status()

Template.infos.events = 
	"click .btn-reconnect": ->
		Meteor.reconnect()