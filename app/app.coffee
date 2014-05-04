Router.configure layoutTemplate: 'layout'



@Sheets = new Meteor.Collection "sheets"
@Elements = new Meteor.Collection "elements"


imageStore = new FS.Store.FileSystem "image"
@Images = new FS.Collection "images", stores: [imageStore]
 
@Images.allow
  insert: -> true
  update: -> true
  remove: -> true
  download: -> true