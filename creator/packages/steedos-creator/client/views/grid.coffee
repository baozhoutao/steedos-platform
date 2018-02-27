dxDataGridInstance = null

_fields = (object_name)->
	object = Creator.getObject(object_name)
	name_field_key = object.NAME_FIELD_KEY
	fields = [name_field_key]
	if object.list_views?.default?.columns
		fields = object.list_views.default.columns
	fields = fields.map (n,i)->
		if object.fields[n]?.type and !object.fields[n].hidden
			return n.split(".")[0]
		else
			return undefined
	
	fields = _.compact(fields)
	return fields

_columns = (object_name, columns, list_view_id, is_related)->
	object = Creator.getObject(object_name)
	grid_settings = Creator.Collections.settings.findOne({object_name: object_name, record_id: "object_gridviews"})
	defaultWidth = _defaultWidth(columns)
	return columns.map (n,i)->
		field = object.fields[n]
		columnItem = 
			cssClass: "slds-cell-edit"
			caption: field.label || n
			dataField: n
			cellTemplate: (container, options) ->
				field_name = n
				if /\w+\.\$\.\w+/g.test(field_name)
					# object类型带子属性的field_name要去掉中间的美元符号，否则显示不出字段值
					field_name = n.replace(/\$\./,"")
				cellOption = {_id: options.data._id, val: options.data[n], doc: options.data, field: field, field_name: field_name, object_name:object_name}
				Blaze.renderWithData Template.creator_table_cell, cellOption, container[0]
		
		if grid_settings and grid_settings.settings
			column_width_settings = grid_settings.settings[list_view_id]?.column_width
			column_sort_settings = grid_settings.settings[list_view_id]?.sort
		
		if column_width_settings
			width = column_width_settings[n]
			if width
				columnItem.width = width
		else
			columnItem.width = defaultWidth

		if column_sort_settings and column_sort_settings.length > 0
			_.each column_sort_settings, (sort)->
				if sort[0] == n
					columnItem.sortOrder = sort[1]
		
		unless field.sortable
			columnItem.allowSorting = false
		return columnItem

_defaultWidth = (columns)->
	column_counts = columns.length
	content_width = $(".gridContainer").width() - 46 - 60
	return content_width/column_counts

Template.creator_grid.onRendered ->
	self = this
	self.autorun (c)->
		is_related = self.data.is_related
		object_name = Session.get("object_name")
		creator_obj = Creator.getObject(object_name)
		related_object_name = Session.get("related_object_name")
		name_field_key = Creator.getObject(object_name).NAME_FIELD_KEY
		record_id = Session.get("record_id")
		if is_related
			list_view_id = "recent"
		else
			list_view_id = Session.get("list_view_id")

		if Steedos.spaceId() and (is_related or Creator.subs["CreatorListViews"].ready()) and Creator.subs["TabularSetting"].ready()
			if is_related
				url = "/api/odata/v4/#{Steedos.spaceId()}/#{related_object_name}"
				filter = Creator.getODataRelatedFilter(object_name, related_object_name, record_id)
			else
				url = "/api/odata/v4/#{Steedos.spaceId()}/#{object_name}"
				filter = Creator.getODataFilter(list_view_id, object_name)
			
			curObjectName = if is_related then related_object_name else object_name
			object = Creator.getObject(curObjectName)
			selectColumns = _fields(curObjectName)
			extra_columns = ["owner"]
			if object.list_views?.default?.extra_columns
				extra_columns = _.union extra_columns, object.list_views.default.extra_columns
			
			# 这里如果不加nonreactive，会因为后面customSave函数插入数据造成表Creator.Collections.settings数据变化进入死循环
			showColumns = Tracker.nonreactive ()-> return _columns(curObjectName, selectColumns, list_view_id, is_related)
			showColumns.push
				dataField: "_id_actions"
				width: 46
				allowSorting: false
				headerCellTemplate: (container) ->
					return ""
				cellTemplate: (container, options) ->
					container.css("overflow", "visible")
					record_permissions = Creator.getRecordPermissions curObjectName, options.data, Meteor.userId()
					actionsOption = {_id: options.data._id, object_name: curObjectName, record_permissions: record_permissions, is_related: false}
					Blaze.renderWithData Template.creator_table_actions, actionsOption, container[0]
			showColumns.splice 0, 0, 
				dataField: "_id_checkbox"
				width: 60
				allowSorting: false
				headerCellTemplate: (container) ->
					Blaze.renderWithData Template.creator_table_checkbox, {_id: "#", object_name: curObjectName}, container[0]
				cellTemplate: (container, options) ->
					Blaze.renderWithData Template.creator_table_checkbox, {_id: options.data._id, object_name: curObjectName}, container[0]
			
			dxOptions = 
				paging: 
					pageSize: 20
				pager: 
					showPageSizeSelector: true,
					allowedPageSizes: [20, 40, 60],
					showInfo: false,
					showNavigationButtons: true
				showColumnLines: false
				allowColumnResizing: true
				columnResizingMode: "widget"
				showRowLines: true
				savingTimeout: 1000
				stateStoring:{
		   			type: "custom"
					enabled: true
					customSave: (gridState)->
						columns = gridState.columns
						column_width = {}
						sort = []
						_.each columns, (column_obj)->
							if column_obj.width
								column_width[column_obj.dataField] = column_obj.width
							if column_obj.sortOrder
								sort.push [column_obj.dataField, column_obj.sortOrder]
						Meteor.call 'grid_settings', curObjectName, list_view_id, column_width, sort,
							(error, result)->
								if error
									console.log error
								else
									console.log "grid_settings success"
				}
				dataSource: 
					store: 
						type: "odata"
						version: 4
						url: Steedos.absoluteUrl(url)
						withCredentials: false
						beforeSend: (request) ->
							request.headers['X-User-Id'] = Meteor.userId()
							request.headers['X-Space-Id'] = Steedos.spaceId()
							request.headers['X-Auth-Token'] = Accounts._storedLoginToken()
					select: selectColumns
					filter: filter
				columns: showColumns
				onContentReady: (e)->
					self.data.total.set dxDataGridInstance.totalCount()

			dxDataGridInstance = self.$(".gridContainer").dxDataGrid(dxOptions).dxDataGrid('instance')

Template.creator_grid.helpers Creator.helpers

Template.creator_grid.events
	
	'click .list-item-action': (event, template) ->
		actionKey = event.currentTarget.dataset.actionKey
		objectName = event.currentTarget.dataset.objectName
		recordId = event.currentTarget.dataset.recordId
		object = Creator.getObject(objectName)
		action = object.actions[actionKey]
		collection_name = object.label
		if action.todo == "standard_delete"
			action_record_title = template.$(".list-item-link-"+ recordId).attr("title")
			swal
				title: "删除#{object.label}"
				text: "<div class='delete-creator-warning'>是否确定要删除此#{object.label}？</div>"
				html: true
				showCancelButton:true
				confirmButtonText: t('Delete')
				cancelButtonText: t('Cancel')
				(option) ->
					if option
						Creator.Collections[objectName].remove {_id: recordId}, (error, result) ->
							if error
								toastr.error error.reason
							else
								info = object.label + "\"#{action_record_title}\"" + "已删除"
								toastr.success info
								dxDataGridInstance.refresh()
		else
			Session.set("action_fields", undefined)
			Session.set("action_collection", "Creator.Collections.#{objectName}")
			Session.set("action_collection_name", collection_name)
			Session.set("action_save_and_insert", true)
			Creator.executeAction objectName, action, recordId

	'click .table-cell-edit': (event, template) ->
		is_related = template.data.is_related
		field = this.field_name

		if this.field.depend_on && _.isArray(this.field.depend_on)
			field = _.clone(this.field.depend_on)
			field.push(this.field_name)
			field = field.join(",")

		objectName = if is_related then Session.get("related_object_name") else Session.get("object_name")
		collection_name = Creator.getObject(objectName).label
		rowData = this.doc

		if rowData
			Session.set("action_fields", field)
			Session.set("action_collection", "Creator.Collections.#{objectName}")
			Session.set("action_collection_name", collection_name)
			Session.set("action_save_and_insert", false)
			Session.set 'cmDoc', rowData
			Session.set 'cmIsMultipleUpdate', true
			Session.set 'cmTargetIds', Creator.TabularSelectedIds?[objectName]
			Meteor.defer ()->
				$(".btn.creator-cell-edit").click()

	'dblclick td': (event) ->
		$(".table-cell-edit", event.currentTarget).click()

	'click td': (event, template)->
		if $(event.currentTarget).find(".slds-checkbox input").length
			# 左侧勾选框不要focus样式功能
			return
		if $(event.currentTarget).parent().hasClass("dx-freespace-row")
			# 最底下的空白td不要focus样式功能
			return
		template.$("td").removeClass("slds-has-focus")
		$(event.currentTarget).addClass("slds-has-focus")

Template.creator_grid.onCreated ->
	AutoForm.hooks creatorAddForm:
		onSuccess: (formType,result)->
			dxDataGridInstance.refresh().done (result)->
				Creator.remainCheckboxState(dxDataGridInstance.$element())
	,true
	AutoForm.hooks creatorEditForm:
		onSuccess: (formType,result)->
			dxDataGridInstance.refresh().done (result)->
				Creator.remainCheckboxState(dxDataGridInstance.$element())
	,true
	AutoForm.hooks creatorCellEditForm:
		onSuccess: (formType,result)->
			dxDataGridInstance.refresh().done (result)->
				Creator.remainCheckboxState(dxDataGridInstance.$element())
	,true

Template.creator_grid.onDestroyed ->
	#离开界面时，清除hooks为空函数
	AutoForm.hooks creatorAddForm:
		onSuccess: undefined
	,true
	AutoForm.hooks creatorEditForm:
		onSuccess: undefined
	,true
	AutoForm.hooks creatorCellEditForm:
		onSuccess: undefined
	,true


Template.creator_grid.refresh = ->
	dxDataGridInstance.refresh().done (result)->
		Creator.remainCheckboxState(dxDataGridInstance.$element())
