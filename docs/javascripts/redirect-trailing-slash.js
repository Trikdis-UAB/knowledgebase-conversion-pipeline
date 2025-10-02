(function () {
  var path = window.location.pathname;
  if (path.length > 1 && !path.endsWith('/') && path.indexOf('.') === -1) {
    var target = path + '/';
    var search = window.location.search || '';
    var hash = window.location.hash || '';
    window.location.replace(target + search + hash);
  }
})();
