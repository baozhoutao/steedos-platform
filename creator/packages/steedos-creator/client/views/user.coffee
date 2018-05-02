
Template.user.onRendered ->
	this.autorun ->
		spaceId = Session.get "spaceId"
		userId = Session.get "record_id"
		Creator.subs["Creator"].subscribe "space_user_info", spaceId, userId

	this.autorun ->
		spaceId = Session.get "spaceId"
		userId = Session.get "record_id"
		space_record = Creator.getCollection("space_users").findOne({space: spaceId, user: userId})
		fields = Creator.getFields("space_users")
		ref_fields = {}
		_.each fields, (f)->
			ref_fields[f] = 1

		if space_record
			Creator.subs["Creator"].subscribe "steedos_object_tabular", "creator_space_users", [space_record._id], ref_fields

Template.user.helpers 
	doc: ()->
		spaceId = Session.get "spaceId"
		userId = Session.get "record_id"
		return Creator.getCollection("space_users").findOne({space: spaceId, user: userId})

	fields: ()->
		return [["name", "email"], ["position", "organization"], ["manager", "mobile"], ["work_phone", "position"], ["company", "organizations"]]

	keyValue: (key)->
		spaceId = Session.get "spaceId"
		userId = Session.get "record_id"
		doc = Creator.getCollection("space_users").findOne({space: spaceId, user: userId})
		if doc
			console.log doc
			return doc[key]

	keyField: (key) ->
		fields = Creator.getObject("space_users").fields
		return fields[key]

	label: (key) ->
		return AutoForm.getLabelForField(key)

	avatarUrl: ()->
		userId = Session.get "record_id"
		avatar = Creator.getCollection("users").findOne({_id: userId})?.avatar
		if avatar
			return Steedos.absoluteUrl("avatar/#{Meteor.userId()}?w=220&h=200&fs=160&avatar=#{avatar}")


Template.user.events 
	'change #avator-upload': (event, template)->
		file = event.target.files[0];
		unless file
			return
		$("body").addClass("loading");
		db.avatars.insert file, (error, fileDoc)->
			if error
				console.error error
				toastr.error t(error.reason)
				$(document.body).removeClass('loading')
			else
				# Inserted new doc with ID fileDoc._id, and kicked off the data upload using HTTP
				# 理论上这里不需要加setTimeout，但是当上传图片很快成功的话，定阅到Avatar变化时可能请求不到上传成功的图片
				setTimeout(()->
					Meteor.call "updateUserAvatar", fileDoc._id, (error, result)->
						if result?.error
							$(document.body).removeClass('loading')
							toastr.error t(result.message)
						else
							$(document.body).removeClass('loading')
				, 3000)
		 
