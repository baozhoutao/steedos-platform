_syncToObject = (doc) ->
	object_fields = Creator.getCollection("object_fields").find({object: doc.object}, {
		fields: {
			created: 0,
			modified: 0,
			owner: 0,
			created_by: 0,
			modified_by: 0
		}
	}).fetch()

	fields = {}

	_.forEach object_fields, (f)->
		fields[f.name] = f

	Creator.getCollection("objects").update({_id: doc.object}, {
		$set:
			fields: fields
	})

isRepeatedName = (doc, name)->
	other = Creator.getCollection("object_fields").find({object: doc.object, _id: {$ne: doc._id}, name: name || doc.name}, {fields:{_id: 1}})
	if other.count() > 0
		return true
	return false

Creator.Objects.object_fields =
	name: "object_fields"
	label: "字段"
	icon: "orders"
	enable_api: true
	fields:
		object:
			type: "master_detail"
			reference_to: "objects"
		name:
			type: "text"
			searchable: true
			index: true
			required: true
			regEx: SimpleSchema.RegEx.code
		label:
			type: "text"
		description:
			label: "Description"
			type: "text"
		type:
			type: "select"
			required: true
			options:
				text: "文本",
				textarea: "长文本"
				html: "Html文本",
				select: "选择框",
				boolean: "Checkbox"
				date: "日期"
				datetime: "日期时间"
				number: "数值"
				currency: "金额"
				lookup: "相关表"
				master_detail: "主表/子表"
		multiple:
			type: "boolean"

		required:
			type: "boolean"

		is_wide:
			type: "boolean"

		readonly:
			type: "boolean"

		disabled:
			type: "boolean"

		omit:
			type: "boolean"

		group:
			type: "text"

		index:
			type: "boolean"

		sortable:
			type: "boolean"

		allowedValues:
			type: "text"
			multiple: true

		rows:
			type: "number"

		precision:
			type: "number"

		scale:
			type: "number"

		reference_to: #在服务端处理此字段值，如果小于2个，则存储为字符串，否则存储为数组
			type: "lookup"
			optionsFunction: ()->
				_options = []
				_.forEach Creator.Objects, (o, k)->
					_options.push {label: o.label, value: k, icon: o.icon}
				return _options
			multiple: true

		options:
			type: "textarea"

	list_views:
		default:
			columns: ["name", "object", "label", "type", "multiple", "required", "omit", "group", "description", "modified"]
		all:
			filter_scope: "space"

	permission_set:
		user:
			allowCreate: false
			allowDelete: false
			allowEdit: false
			allowRead: false
			modifyAllRecords: false
			viewAllRecords: false
		admin:
			allowCreate: true
			allowDelete: true
			allowEdit: true
			allowRead: true
			modifyAllRecords: true
			viewAllRecords: true

	triggers:
		"after.insert.server.object_fields":
			on: "server"
			when: "after.insert"
			todo: (userId, doc)->
				_syncToObject(doc)
		"after.update.server.object_fields":
			on: "server"
			when: "after.update"
			todo: (userId, doc)->
				_syncToObject(doc)
		"after.remove.server.object_fields":
			on: "server"
			when: "after.remove"
			todo: (userId, doc)->
				_syncToObject(doc)

		"before.update.server.object_fields":
			on: "server"
			when: "before.update"
			todo: (userId, doc, fieldNames, modifier, options)->
				if doc.name == 'name' && modifier?.$set?.name && doc.name != modifier.$set.name
					throw new Meteor.Error 500, "不能修改此纪录的name属性"
				if modifier?.$set?.name && isRepeatedName(doc, modifier.$set.name)
					throw new Meteor.Error 500, "对象名称不能重复"

				if modifier?.$set?.reference_to && modifier.$set.reference_to.length == 1
					_reference_to = modifier.$set.reference_to[0]

				object = Creator.getCollection("objects").findOne({_id: doc.object}, {fields: {name: 1, label: 1}})

				if object

					object_documents = Creator.getCollection(object.name).find()
					if modifier?.$set?.reference_to && doc.reference_to != _reference_to && object_documents.count() > 0
						throw new Meteor.Error 500, "对象#{object.label}中已经有记录，不能修改reference_to字段"

		"before.insert.server.object_fields":
			on: "server"
			when: "before.insert"
			todo: (userId, doc)->

				if doc.reference_to?.length == 1
					doc.reference_to = doc.reference_to[0]

				if isRepeatedName(doc)
					throw new Meteor.Error 500, "对象名称不能重复"

		"before.remove.server.object_fields":
			on: "server"
			when: "before.remove"
			todo: (userId, doc)->
				if doc.name == "name"
					throw new Meteor.Error 500, "不能删除此纪录"


