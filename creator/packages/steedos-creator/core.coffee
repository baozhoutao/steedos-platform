@Creator = {}

Creator.Apps = {}
Creator.Objects = {}
Creator.Collections = {}
Creator.TabularTables = {}



Meteor.startup ->
	Creator.initApps()
	_.each Creator.Objects, (obj, object_name)->
		if db[object_name]
			Creator.Collections[object_name] = db[object_name]
		else if !Creator.Collections[object_name]
			schema = Creator.getObjectSchema(obj)
			_simpleSchema = new SimpleSchema(schema)
			Creator.Collections[object_name] = new Meteor.Collection(object_name)
			Creator.Collections[object_name].attachSchema(_simpleSchema)
				
			if Meteor.isServer
				Creator.Collections[object_name].allow
					insert: (userId, doc) ->
						return true
					update: (userId, doc) ->
						return true
					remove: (userId, doc) ->
						return true

				Creator.Collections[object_name].before.insert (userId, doc)->
					doc.owner = userId
					doc.created_by = userId;
					doc.created = new Date();
					doc.modified_by = userId;
					doc.modified = new Date();

				Creator.Collections[object_name].before.update (userId, doc, fieldNames, modifier, options)->
					modifier.$set = modifier.$set || {};
					modifier.$set.modified_by = userId
					modifier.$set.modified = new Date();


		if Meteor.isClient
				Creator.Collections[object_name].before.insert (userId, doc)->
					doc.space = Session.get("spaceId")

		if obj.list_views?.default?.columns
			Creator.TabularTables[object_name] = new Tabular.Table
				name: object_name,
				collection: Creator.Collections[object_name],
				pub: "steedos_object_tabular",
				columns: Creator.getTabularColumns(object_name, obj.list_views.default.columns)
				dom: "tp"
				extraFields: ["_id"]
				lengthChange: false
				ordering: false
				pageLength: 10
				info: false
				searching: true
				autoWidth: true

	# 初始化子表
	_.each Creator.Objects, (obj, object_name)->

		_.each obj.fields, (field, field_name)->
			if field.type == "master_detail" and field.reference_to
				tabular_name = field.reference_to + "_related_" + object_name
				columns = obj.list_views.default.columns
				columns = _.without(columns, field_name)

				Creator.TabularTables[tabular_name] = new Tabular.Table
					name: tabular_name,
					collection: Creator.Collections[object_name],
					pub: "steedos_object_tabular",
					columns: Creator.getTabularColumns(object_name, columns)
					dom: "tp"
					extraFields: ["_id"]
					lengthChange: false
					ordering: false
					pageLength: 10
					info: false
					searching: true
					autoWidth: true

Creator.initApps = ()->
	if Meteor.isServer
		_.each Creator.Apps, (app, app_id)->
			db_app = db.apps.findOne(app_id) 
			if !db_app
				app._id = app_id
				db.apps.insert(app)
			# else
			# 	db.apps.update({_id: app_id}, {$set: app})

Creator.getObjectSchema = (obj) ->

	baseFields = 
		owner:
			type: "text",
			omit: true
		space:
			type: "text",
			omit: true
		created:
			type: "datetime",
			omit: true
		created_by:
			type: "text",
			omit: true
		modified:
			type: "datetime",
			omit: true
		modified_by:
			type: "text",
			omit: true
		last_activity: 
			type: "datetime",
			omit: true
		last_viewed: 
			type: "datetime",
			omit: true
		last_referenced: 
			type: "datetime",
			omit: true

	_.extend(obj.fields, baseFields)

	schema = {}
	_.each obj.fields, (field, field_name)->

		fs = {}
		fs.autoform = {}
		if field.type == "text"
			fs.type = "String"
		else if field.type == "textarea"
			fs.type = "String"
			fs.autoform.type = "textarea"
			fs.autoform.rows = 3
		else if field.type == "date"
			fs.type = "Date"
		else if field.type == "datetime"
			fs.type = "Date"
		else if field.type == "master_detail"
			fs.type = "String"
			if Meteor.isClient
				fs.autoform.type="universe-select"
				fs.autoform.optionsMethod="creator.object_options"
				fs.autoform.optionsMethodParams=
					reference_to: field.reference_to
					space: Session.get("spaceId")
		else if field.type == "select"
			fs.type = "String"
			fs.autoform.type = "select2"
			fs.autoform.options = field.options
		else
			fs.type = "String"

		if field.label
			fs.label = field.label
			
		if !field.required
			fs.optional = true

		if field.omit
			fs.autoform.omit = true

		schema[field_name] = fs


	return schema

Creator.getTabularColumns = (object_name, columns) ->
	obj = Creator.Objects[object_name]
	cols = []
	_.each columns, (field_name)->
		field = obj.fields[field_name]
		if field?.type
			col = {}
			col.title = field?.label
			col.data = field_name
			col.render =  (val, type, doc) ->

				if field.reference_to
					return "<a href='" + Creator.getObjectUrl(field.reference_to, doc[field_name]) + "'>" + (Creator.Collections[field.reference_to].findOne(doc[field_name])?.name || "") + "</a>"

				if field_name == "name"
					return "<a href='" + Creator.getObjectUrl(obj.name, doc._id) + "'>" + val + "</a>"
				if (val instanceof Date) 
					return moment(val).format('YYYY-MM-DD H:mm')
				else if (val == null)
					return ""
				else
					return val;
			cols.push(col)
	return cols

Creator.getObjectUrl = (object_name, record_id, app_id) ->
	if !app_id
		app_id = Session.get("app_id")
	if record_id
		return Steedos.absoluteUrl("/creator/" + app_id + "/" + object_name + "/view/" + record_id)
	else 
		return Steedos.absoluteUrl("/creator/" + app_id + "/" + object_name + "/list")


Creator.getObject = (object_name)->
	if !object_name
		object_name = Session.get("object_name")
	if object_name
		return Creator.Objects[object_name]

Creator.getCollection = (object_name)->
	if !object_name
		object_name = Session.get("object_name")
	if object_name
		return Creator.Collections[object_name]

Creator.getObjectRecord = (object_name, record_id)->
	if !record_id
		record_id = Session.get("record_id")
	collection = Creator.getCollection(object_name)
	if collection
		return collection.findOne(record_id)


# 切换工作区时，重置下拉框的选项
if Meteor.isClient
	Tracker.autorun ()->
		if  Session.get("spaceId")
			_.each Creator.Objects, (obj, object_name)->
				if Creator.Collections[object_name]
					_.each obj.fields, (field, field_name)->
						if field.type == "master_detail"
							_schema = Creator.Collections[object_name]?._c2?._simpleSchema?._schema
							_schema?[field_name]?.autoform?.optionsMethodParams?.space = Session.get("spaceId")
