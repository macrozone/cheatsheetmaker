Router.configure layoutTemplate: 'layout'
Router.map ->
	@route 'sheet', path: "/"


@Sheets = new Meteor.Collection "sheets"
@Elements = new Meteor.Collection "elements"