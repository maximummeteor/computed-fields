Package.describe({
  name: 'maximum:computed-fields',
  summary: 'Meteor package for automatic computation of field values in a collection',
  version: '0.1.6',
  git: 'https://github.com/maximummeteor/computed-fields'
});

Npm.depends({
  'JSONPath': '0.10.0',
});

Package.onUse(function(api) {
  api.versionsFrom('1.1.0.3');
  api.use([
    'coffeescript',
    'underscore',
    'check',
    'lai:collection-extensions@0.1.4',
    'matb33:collection-hooks@0.7.14',
  ], 'server');
  api.use([
    'coffeescript',
    'underscore',
    'check',
  ], 'client');

  api.addFiles([
    'lib/computed-fields.coffee',
    'lib/collection2.coffee',
  ], 'server');
  api.addFiles([
    'lib/collection2.coffee',
  ], 'client');
});


Package.onTest(function (api) {
  api.use('tinytest');
  api.use('coffeescript');
  api.use('mongo');
  api.use('aldeed:collection2@2.0.0');
  api.use('maximum:computed-fields');

  api.addFiles([
    'tests/collection2.coffee',
  ], 'client');
  api.addFiles([
    'tests/basic.coffee',
    'tests/collection2.coffee',
  ], 'server');
});
