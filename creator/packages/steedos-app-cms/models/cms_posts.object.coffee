Creator.Objects.cms_posts = 
	name: "cms_posts"
	icon: "cms"
	label: "文章"
	fields:
		title: 
			type: "text"
			required: true
			is_name: true
			searchable:true
			index:true
		postDate: 
			type: "datetime"
		htmlBody:
			type: "html"
			is_wide: true
		site:
			type: "master_detail"
			reference_to: "cms_sites"
		author: 
			type: "lookup"
			reference_to: "users"
	list_views:
		default:
			columns: ["title", "site", "postDate", "author"]
		all:
			filter_scope: "space"