/*global describe, it*/


'use strict';


var zlib = require('zlib');

var pako    = require('../index');
var helpers = require('./helpers');
var testSamples = helpers.testSamples;
var assert  = require('assert');
var fs      = require('fs');
var path    = require('path');



var samples = helpers.loadSamples();


describe('Deflate defaults', function () {

  it('deflate, no options', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, {}, done, 'deflate_no_opt');
  });

  it('deflate raw, no options', function (done) {
    testSamples(zlib.createDeflateRaw, pako.deflateRaw, samples, {}, done, 'deflate_raw_no_opt');
  });

  // OS_CODE can differ. Probably should add param to compare function
  // to ignore some buffer positions
  it('gzip, no options', function (done) {
    testSamples(zlib.createGzip, pako.gzip, samples, {}, done, 'gzip_no_opt');
  });
});


describe('Deflate levels', function () {

  it('level 9', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { level: 9 }, done, 'deflate_lev9');
  });
  it('level 8', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { level: 8 }, done, 'deflate_lev8');
  });
  it('level 7', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { level: 7 }, done, 'deflate_lev7');
  });
  it('level 6', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { level: 6 }, done, 'deflate_lev6');
  });
  it('level 5', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { level: 5 }, done, 'deflate_lev5');
  });
  it('level 4', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { level: 4 }, done, 'deflate_lev4');
  });
  it('level 3', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { level: 3 }, done, 'deflate_lev3');
  });
  it('level 2', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { level: 2 }, done, 'deflate_lev2');
  });
  it('level 1', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { level: 1 }, done, 'deflate_lev1');
  });
  it('level 0', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { level: 0 }, done, 'deflate_lev0');
  });
  it('level -1 (implicit default)', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { level: 0 }, done, 'deflate_lev-1');
  });
});


describe('Deflate windowBits', function () {

  it('windowBits 15', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { windowBits: 15 }, done, 'deflate_wb15');
  });
  it('windowBits 14', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { windowBits: 14 }, done, 'deflate_wb14');
  });
  it('windowBits 13', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { windowBits: 13 }, done, 'deflate_wb13');
  });
  it('windowBits 12', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { windowBits: 12 }, done, 'deflate_wb12');
  });
  it('windowBits 11', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { windowBits: 11 }, done, 'deflate_wb11');
  });
  it('windowBits 10', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { windowBits: 10 }, done, 'deflate_wb10');
  });
  it('windowBits 9', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { windowBits: 9 }, done, 'deflate_wb9');
  });
  it('windowBits 8', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { windowBits: 8 }, done, 'deflate_wb8');
  });
  it('windowBits -15 (implicit raw)', function (done) {
    testSamples(zlib.createDeflateRaw, pako.deflate, samples, { windowBits: -15 }, done, 'deflate_wb-15');
  });

});


describe('Deflate memLevel', function () {

  it('memLevel 9', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { memLevel: 9 }, done, 'deflate_mem9');
  });
  it('memLevel 8', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { memLevel: 8 }, done, 'deflate_mem8');
  });
  it('memLevel 7', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { memLevel: 7 }, done, 'deflate_mem7');
  });
  it('memLevel 6', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { memLevel: 6 }, done, 'deflate_mem6');
  });
  it('memLevel 5', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { memLevel: 5 }, done, 'deflate_mem5');
  });
  it('memLevel 4', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { memLevel: 4 }, done, 'deflate_mem4');
  });
  it('memLevel 3', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { memLevel: 3 }, done, 'deflate_mem3');
  });
  it('memLevel 2', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { memLevel: 2 }, done, 'deflate_mem2');
  });
  it('memLevel 1', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { memLevel: 1 }, done, 'deflate_mem1');
  });

});


describe('Deflate strategy', function () {

  it('Z_DEFAULT_STRATEGY', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { strategy: 0 }, done, 'deflate_strat_def');
  });
  it('Z_FILTERED', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { strategy: 1 }, done, 'deflate_strat_filt');
  });
  it('Z_HUFFMAN_ONLY', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { strategy: 2 }, done, 'deflate_strat_huff');
  });
  it('Z_RLE', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { strategy: 3 }, done, 'deflate_strat_rle');
  });
  it('Z_FIXED', function (done) {
    testSamples(zlib.createDeflate, pako.deflate, samples, { strategy: 4 }, done, 'deflate_strat_fix');
  });

});


describe('Deflate RAW', function () {
  // Since difference is only in rwapper, test for store/fast/slow methods are enougth
  it('level 4', function (done) {
    testSamples(zlib.createDeflateRaw, pako.deflateRaw, samples, { level: 4 }, done, 'deflate_raw_lev4');
  });
  it('level 1', function (done) {
    testSamples(zlib.createDeflateRaw, pako.deflateRaw, samples, { level: 1 }, done, 'deflate_raw_lev1');
  });
  it('level 0', function (done) {
    testSamples(zlib.createDeflateRaw, pako.deflateRaw, samples, { level: 0 }, done, 'deflate_raw_lev0');
  });

});


describe('Deflate dictionary', function () {

  it('trivial dictionary', function (done) {
    var dict = new Buffer('abcdefghijklmnoprstuvwxyz');
    testSamples(zlib.createDeflate, pako.deflate, samples, { dictionary: dict }, done, 'deflate_dict_trivial');
  });

  it('spdy dictionary', function (done) {
    var spdyDict = require('fs').readFileSync(require('path').join(__dirname, 'fixtures', 'spdy_dict.txt'));

    testSamples(zlib.createDeflate, pako.deflate, samples, { dictionary: spdyDict }, done, 'deflate_dict_spdy');
  });

  it('handles multiple pushes', function () {
    var dict = new Buffer('abcd');
    var deflate = new pako.Deflate({ dictionary: dict });

    deflate.push(new Buffer('hello'), false);
    deflate.push(new Buffer('hello'), false);
    deflate.push(new Buffer(' world'), true);

    if (deflate.err) { throw new Error(deflate.err); }

    var uncompressed = pako.inflate(new Buffer(deflate.result), { dictionary: dict });

    if (!helpers.cmpBuf(new Buffer('hellohello world'), uncompressed)) {
      throw new Error('Result not equal for p -> z');
    }
  });
});


describe('Deflate issues', function () {

  it('#78', function () {
    var data = fs.readFileSync(path.join(__dirname, 'fixtures', 'issue_78.bin'));
    var deflatedPakoData = pako.deflate(data, { memLevel: 1 });
    var inflatedPakoData = pako.inflate(deflatedPakoData);

    assert.equal(data.length, inflatedPakoData.length);
  });
});
