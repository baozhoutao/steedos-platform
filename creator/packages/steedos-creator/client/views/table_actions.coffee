Template.creator_table_actions.helpers
	object_name: ()->
		return Template.instance().data.object_name
	
	record_id: ()->
		return Template.instance().data._id

	actions: ()->
		object_name = this.object_name
		record_id = this._id
		record_permissions = this.record_permissions
		obj = Creator.getObject(object_name)
		actions = _.map obj.actions, (val, key) ->
			val._ACTION_KEY = key
			return val
		actions = _.values(actions) 
		actions = _.filter actions, (action)->
			if action.on == "record" or action.on == "record_more"
				if action.only_detail
					return false
				if typeof action.visible == "function"
					return action.visible(object_name, record_id, record_permissions)
				else
					return action.visible
			else
				return false
		return actions