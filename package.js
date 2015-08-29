Package.describe({
  name: 'maximum:computed-fields',
  summary: 'Meteor package for automatic computation of field values in a collection',
  version: '0.1.0',
  git: 'https://github.com/maximummeteor/computed-fields'
});

Package.onUse(function(api) {
  api.versionsFrom('1.1.0.3');
  api.use([
    'coffeescript',
    'underscore',
    'matb33:collection-hooks@0.7.14'
  ], 'server');

  api.addFiles([
    'lib/computed-fields.coffee',
  ], 'server');
  api.export('ComputedFields','server');
});


Package.onTest(function (api) {
  api.use('tinytest');
  api.use('coffeescript');
  api.use('maximum:computed-fields');

  api.addFiles('tests/basic.coffee', 'server');
});
