var fs, home, npmuprc, path, rcFile, writeRC;

path = require('path');

fs = require('nofs');

home = process.platform === 'win32' ? process.env.USERPROFILE : process.env.HOME;

rcFile = path.join(home, '.npmuprc.json');

npmuprc = (function() {
  try {
    return require(rcFile);
  } catch (_error) {
    return {};
  }
})();

writeRC = function() {
  return fs.outputJSON(rcFile, npmuprc, {
    space: 2
  })["catch"](function(e) {
    return console.log(e);
  });
};

module.exports = {
  npmuprc: npmuprc,
  writeRC: writeRC
};