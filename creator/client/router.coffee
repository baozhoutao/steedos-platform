FlowRouter.route '/',
	action: (params, queryParams)->
		if !Meteor.userId()
			FlowRouter.go '/steedos/sign-in';
		else
			FlowRouter.go '/app/admin'


# Meteor.startup ->
# 	db.apps.INTERNAL_APPS = ["/app/crm", "/app/creator"]
# 	Session.set("apps", ["crm", "creator"]);
# 	Session.set("app_objects", ["customers", "contacts", "flow_roles"]);