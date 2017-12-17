Creator.baseObject = 
	fields: 
		owner:
			type: "lookup",
			reference_to: "users"
		space:
			type: "text",
			omit: true
		created:
			type: "datetime",
			omit: true
		created_by:
			type: "lookup",
			reference_to: "users"
		modified:
			type: "datetime",
			omit: true
		modified_by:
			type: "lookup",
			reference_to: "users"
		last_activity: 
			type: "datetime",
			omit: true
		last_referenced: 
			type: "datetime",
			omit: true
		is_deleted:
			type: "boolean"
			omit: true

	list_views:
		default:
			columns: ["name"]
		recent:
			filter_scope: "all"
		all:
			filter_scope: "all"

	permissions:
		allowCreate: true
		allowDelete: true
		allowEdit: true
		allowRead: true
		modifyAllRecords: false
		viewAllRecords: false 