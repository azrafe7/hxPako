### Notes to self

When upgrading the port to a new version of pako js:

 - add this at the end of `helper.js`

```javascript
var portHelpers = require('./port_helpers');

exports.toType = portHelpers.toType;
exports.cmpBuf = portHelpers.cmpBuf;
exports.testSamples = portHelpers.testSamples;
exports.testInflate = portHelpers.testInflate;
exports.loadSamples = portHelpers.loadSamples;
```

 - this also ensures that the tests are only run for untyped arrays
 - set `GEN_ZLIB_OUTPUT` to true in `port_helpers.js`
 - remember to pass the `name` parameter whenever `testSamples()` is called
 - run `mocha` to generate the files
 - add the generated files as resources in the `.hxml` so they can be tested from the haxe side

 