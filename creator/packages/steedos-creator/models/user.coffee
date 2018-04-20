Creator.Objects.users = 
	name: "users"
	label: "用户"
	icon: "user"
	enable_api: true
	fields:
		name: 
			label: "名称"
			type: "text"
			required: true
			searchable:true
			index:true
	list_views:	
		all:
			label:'所有'
			columns: ["name", "username"]
			filter_scope: "all"
			filters: [["_id", "=", "{userId}"]]
	permission_set:
		user:
			allowCreate: false
			allowDelete: false
			allowEdit: false
			allowRead: true
			modifyAllRecords: false
			viewAllRecords: false 
		admin:
			allowCreate: false
			allowDelete: false
			allowEdit: false
			allowRead: true
			modifyAllRecords: false
			viewAllRecords: false 