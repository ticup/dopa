//
// model/documents.opa
//
// Implements the database for the persistently saved documents
//
// @author: Tim Coppieters
// @date: 01/2013

database dopa {
  // a map of unique document names to the document text
  stringmap(string) /documents
}

module Documents {

  function get_stringmap() {
    /dopa/documents
  }
  function get(doc_name) {
    /dopa/documents[doc_name]
  }
  function set(doc_name, text) {
    /dopa/documents[doc_name] <- text
  }
  function delete(doc_name) {
    Db.remove(@/dopa/documents[doc_name])
  }
}