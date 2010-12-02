// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function load_schema_example()
{
    var sample_schema = $('schema_example').innerHTML;
    var textarea = $('schema');
    textarea.innerHTML = sample_schema;
}

function load_query_example()
{
    var sample_query = $('query_example').innerHTML;
    var textarea = $('query');
    textarea.innerHTML = sample_query;
}