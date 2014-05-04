Template.toolBar.events
	"click .btn-remove": (event, template) ->
		shouldDelete = confirm "Delete this Sheet and all it's assets?? It can't be undone"
		if shouldDelete
			Meteor.call "removeSheet", template.data.sheet_id, (error, success) ->
				Router.go "home"


Template.toolBar_images.images = ->
	Images.find sheet_id: @sheet._id

Template.toolBar_oneImage.events
	"dragstart img": (event, template) ->
		event.originalEvent.dataTransfer.setData 'image_id', @_id

	"click .btn-remove": (event, template) ->
		shouldDelete = confirm "Delete this image? It can't be undone"
		if shouldDelete
			Images.remove _id: template.data._id