Package.describe({
	name: 'steedos:app-crm',
	version: '0.0.1',
	summary: 'Creator crm',
	git: '',
	documentation: null
});

Package.onUse(function(api) {
	api.versionsFrom('METEOR@1.2.0.1');
	api.use('coffeescript@1.11.1_4');
	api.use('steedos:creator@0.0.3');
	api.use('blaze@2.1.9');
	api.use('templating@1.2.15');

	api.use('tap:i18n@1.8.2');
	
	tapi18nFiles = ['i18n/en.i18n.json', 'i18n/zh-CN.i18n.json']
	api.addFiles(tapi18nFiles);


	api.addFiles('models/Accounts.coffee');
	api.addFiles('models/Contacts.coffee');
	api.addFiles('models/Contracts.coffee');
	api.addFiles('crm.coffee','client');
	api.addFiles('reports/company.coffee');
	api.addFiles('reports/contact.coffee');
})