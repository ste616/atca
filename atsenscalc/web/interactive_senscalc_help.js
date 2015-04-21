require( [ 'dojo/query', 'dojo/hash', 'dojo/io-query', 'dojo/NodeList-dom' ],
	 function(query, hash, ioQuery) {
	     // Get the id to show from the address bar.
	     var o = ioQuery.queryToObject(hash());
	     for (var p in o) {
		 if (o.hasOwnProperty(p)) {
		     query("#" + p).removeClass('invisible');
		 }
	     }
	 });
